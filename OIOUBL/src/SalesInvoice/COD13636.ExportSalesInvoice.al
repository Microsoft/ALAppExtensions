// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 13636 "OIOUBL-Export Sales Invoice"
{
    TableNo = "Record Export Buffer";
    Permissions = tabledata "Sales Invoice Header" = rm;
    trigger OnRun();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RecordRef: RecordRef;
    begin
        RecordRef.GET(RecordID);
        RecordRef.SETTABLE(SalesInvoiceHeader);

        ServerFilePath := CreateXML(SalesInvoiceHeader);
        MODIFY();

        SalesInvoiceHeader."OIOUBL-Electronic Invoice Created" := TRUE;
        SalesInvoiceHeader.MODIFY();
    end;

    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        Currency: Record "Currency";
        ItemCharge: Record "Item Charge";
        SalesSetup: Record "Sales & Receivables Setup";
        OIOUBLDocumentEncode: Codeunit "OIOUBL-Document Encode";
        OIOUBLXMLGenerator: Codeunit "OIOUBL-Common Logic";
        CompanyInfoRead: Boolean;
        GLSetupRead: Boolean;
        DocNameSpace: Text[250];
        DocNameSpace2: Text[250];

    procedure ExportXML(SalesInvoiceHeader: Record "Sales Invoice Header");
    var
        SalesInvHeader2: Record "Sales Invoice Header";
        RBMgt: Codeunit "File Management";
        OIOUBLManagement: Codeunit "OIOUBL-Management";
        PermissionManager: Codeunit "Permission Manager";
        FromFile: Text[1024];
        DocumentType: Option "Quote","Order","Invoice","Credit Memo","Blanket Order","Return Order","Finance Charge","Reminder";
    begin
        FromFile := CreateXML(SalesInvoiceHeader);

        SalesSetup.GET();

        if RBMgt.CanRunDotNetOnClient() and not PermissionManager.SoftwareAsAService() then
            SalesSetup.VerifyAndSetOIOUBLSetupPath(DocumentType::Invoice);

        OIOUBLManagement.ExportXMLFile(SalesInvoiceHeader."No.", FromFile, SalesSetup."OIOUBL-Invoice Path");

        SalesInvHeader2.GET(SalesInvoiceHeader."No.");
        SalesInvHeader2."OIOUBL-Electronic Invoice Created" := TRUE;
        SalesInvHeader2.MODIFY();
    end;

    local procedure InsertInvoiceTaxTotal(var InvoiceElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; TotalTaxAmount: Decimal);
    var
        TaxTotalElement: XmlElement;
        TaxableAmount: Decimal;
        TaxAmount: Decimal;
        VATPercentage: Decimal;
    begin
        TaxTotalElement := XmlElement.Create('TaxTotal', DocNameSpace2);

        TaxTotalElement.Add(
          XmlElement.Create('TaxAmount', DocNameSpace,
            XmlAttribute.Create('currencyID', SalesInvoiceHeader."Currency Code"),
            OIOUBLDocumentEncode.DecimalToText(TotalTaxAmount)));

        // Invoice->TaxTotal (for ("Normal VAT" AND "VAT %" <> 0) OR "Full VAT")
        //   SalesInvoiceLine.Reset();
        SalesInvoiceLine.SETFILTER(
          "VAT Calculation Type", '%1|%2',
          SalesInvoiceLine."VAT Calculation Type"::"Normal VAT",
          SalesInvoiceLine."VAT Calculation Type"::"Full VAT");
        if SalesInvoiceLine.FINDFIRST() then begin
            TaxableAmount := 0;
            TaxAmount := 0;
            SalesInvoiceLine.SETFILTER("VAT %", '<>0');
            if SalesInvoiceLine.FINDSET() then begin
                VATPercentage := SalesInvoiceLine."VAT %";
                repeat
                    UpdateTaxAmtAndTaxableAmt(SalesInvoiceLine.Amount, SalesInvoiceLine."Amount Including VAT", TaxableAmount, TaxAmount);
                until SalesInvoiceLine.NEXT() = 0;
                OIOUBLXMLGenerator.InsertTaxSubtotal(TaxTotalElement, SalesInvoiceLine."VAT Calculation Type", TaxableAmount, TaxAmount, VATPercentage, SalesInvoiceHeader."Currency Code");
            end;

            TaxableAmount := 0;
            TaxAmount := 0;
            SalesInvoiceLine.SETRANGE("VAT %", 0);
            if SalesInvoiceLine.FINDSET() then begin
                VATPercentage := SalesInvoiceLine."VAT %";
                repeat
                    UpdateTaxAmtAndTaxableAmt(SalesInvoiceLine.Amount, SalesInvoiceLine."Amount Including VAT", TaxableAmount, TaxAmount);
                until SalesInvoiceLine.NEXT() = 0;
                // Invoice->TaxTotal->TaxSubtotal
                OIOUBLXMLGenerator.InsertTaxSubtotal(TaxTotalElement, SalesInvoiceLine."VAT Calculation Type", TaxableAmount, TaxAmount, VATPercentage, SalesInvoiceHeader."Currency Code");
            end;
        end;

        // Invoice->TaxTotal (for "Reverse Charge VAT")
        SalesInvoiceLine.SETRANGE("VAT %");
        SalesInvoiceLine.SETRANGE("VAT Calculation Type", SalesInvoiceLine."VAT Calculation Type"::"Reverse Charge VAT");
        if SalesInvoiceLine.FINDSET() then begin
            TaxableAmount := 0;
            TaxAmount := 0;
            VATPercentage := SalesInvoiceLine."VAT %";
            repeat
                UpdateTaxAmtAndTaxableAmt(SalesInvoiceLine.Amount, SalesInvoiceLine."Amount Including VAT", TaxableAmount, TaxAmount);
            until SalesInvoiceLine.NEXT() = 0;
            OIOUBLXMLGenerator.InsertTaxSubtotal(TaxTotalElement, SalesInvoiceLine."VAT Calculation Type", TaxableAmount, TaxAmount, VATPercentage, SalesInvoiceHeader."Currency Code");
        end;

        InvoiceElement.Add(TaxTotalElement);
    end;

    local procedure InsertOrderLineReference(var InvoiceLineElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceLine: Record "Sales Invoice Line");
    var
        OrderLineReferenceElement: XmlElement;
    begin
        OrderLineReferenceElement := XmlElement.Create('OrderLineReference', DocNameSpace2);
        OrderLineReferenceElement.Add(XmlElement.Create('LineID', DocNameSpace,
          FORMAT(SalesInvoiceLine."Line No.")));
        if SalesInvoiceHeader."Order No." <> '' then
            OIOUBLXMLGenerator.InsertOrderReference(OrderLineReferenceElement,
              SalesInvoiceHeader."External Document No.",
              '',
              CalcDate('0D'))
        else
            OIOUBLXMLGenerator.InsertOrderReference(OrderLineReferenceElement,
              SalesInvoiceHeader."External Document No.",
              '',
              CalcDate('0D'));
        InvoiceLineElement.Add(OrderLineReferenceElement);
    end;

    local procedure InsertInvoiceLine(var InvoiceElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceLine: Record "Sales Invoice Line"; CurrencyCode: Code[10])
    var
        InvoiceLineElement: XmlElement;
        DiscountAmount: Decimal;
        AllowanceChargeReason: Text;
    begin
        InvoiceLineElement := XmlElement.Create('InvoiceLine', DocNameSpace2);

        InvoiceLineElement.Add(XmlElement.Create('ID', DocNameSpace, FORMAT(SalesInvoiceLine."Line No.")));
        InvoiceLineElement.Add(
          XmlElement.Create('InvoicedQuantity', DocNameSpace,
            XmlAttribute.Create('unitCode', OIOUBLDocumentEncode.GetUoMCode(SalesInvoiceLine."Unit of Measure Code")),
            OIOUBLDocumentEncode.DecimalToText(SalesInvoiceLine.Quantity)));
        InvoiceLineElement.Add(
          XmlElement.Create('LineExtensionAmount', DocNameSpace,
            XmlAttribute.Create('currencyID', SalesInvoiceHeader."Currency Code"),
            OIOUBLDocumentEncode.DecimalToText(SalesInvoiceLine.Amount + GetDiscountAmount(SalesInvoiceLine))));
        InvoiceLineElement.Add(XmlElement.Create('AccountingCost', DocNameSpace, SalesInvoiceLine."OIOUBL-Account Code"));
        InsertOrderLineReference(InvoiceLineElement, SalesInvoiceHeader, SalesInvoiceLine);
        // Invoice->InvoiceLine->AllowanceCharge
        DiscountAmount := GetDiscountAmount(SalesInvoiceLine);
        if DiscountAmount > 0 then
            OIOUBLXMLGenerator.InsertAllowanceCharge(InvoiceLineElement, 1, 'Rabat', 'ReverseCharge',
              DiscountAmount, SalesInvoiceHeader."Currency Code", SalesInvoiceLine."Line Discount %");

        // TO-DO move to mapping function
        if SalesInvoiceLine.Type = SalesInvoiceLine.Type::"Charge (Item)" then begin
            ItemCharge.GET(SalesInvoiceLine."No.");
            case ItemCharge."OIOUBL-Charge Category" of
                ItemCharge."OIOUBL-Charge Category"::"General Rebate":
                    AllowanceChargeReason := 'Rabat';
                ItemCharge."OIOUBL-Charge Category"::"General Fine":
                    AllowanceChargeReason := 'Gebyr';
                ItemCharge."OIOUBL-Charge Category"::"Freight Charge":
                    AllowanceChargeReason := 'Fragt';
                ItemCharge."OIOUBL-Charge Category"::Duty:
                    AllowanceChargeReason := 'Afgift';
                ItemCharge."OIOUBL-Charge Category"::Tax:
                    AllowanceChargeReason := 'Told';
            end;

            OIOUBLXMLGenerator.InsertAllowanceCharge(InvoiceLineElement, 2, AllowanceChargeReason,
              OIOUBLXMLGenerator.GetTaxCategoryID(SalesInvoiceLine."VAT Calculation Type", SalesInvoiceLine."VAT %"),
              SalesInvoiceLine."Amount Including VAT", SalesInvoiceHeader."Currency Code", SalesInvoiceLine."VAT %");
        end;
        OIOUBLXMLGenerator.InsertLineTaxTotal(
          InvoiceLineElement,
          SalesInvoiceLine."Amount Including VAT",
          SalesInvoiceLine.Amount,
          SalesInvoiceLine."VAT Calculation Type",
          SalesInvoiceLine."VAT %",
          CurrencyCode);
        OIOUBLXMLGenerator.InsertItem(InvoiceLineElement, SalesInvoiceLine.Description, SalesInvoiceLine."No.");
        OIOUBLXMLGenerator.InsertPrice(InvoiceLineElement,
          SalesInvoiceLine."Unit Price",
          SalesInvoiceLine."Unit of Measure Code",
          CurrencyCode);

        InvoiceElement.Add(InvoiceLineElement);
    end;

    local procedure CreateXML(SalesInvoiceHeader: Record "Sales Invoice Header") FromFile: Text[250];
    var
        BillToAddress: Record "Standard Address";
        DeliveryAddress: Record "Standard Address";
        OIOUBLProfile: Record "OIOUBL-Profile";
        OutputBlob: Record TempBlob temporary;
        SalesInvLine2: Record "Sales Invoice Line";
        SalesInvLine: Record "Sales Invoice Line";
        SellToContact: Record Contact;
        RBMgt: Codeunit "File Management";
        OutputFile: File;
        XMLCurrNode: XmlElement;
        XMLdocOut: XmlDocument;
        FileOutstream: Outstream;
        IsExported: Boolean;
        IsHandled: Boolean;
        CurrencyCode: Code[10];
        TaxableAmount: Decimal;
        TaxAmount: Decimal;
        TotalAmount: Decimal;
        TotalInvDiscountAmount: Decimal;
        TotalTaxAmount: Decimal;
    begin
        CODEUNIT.RUN(CODEUNIT::"OIOUBL-Check Sales Invoice", SalesInvoiceHeader);
        ReadGLSetup();
        ReadCompanyInfo();

        if SalesInvoiceHeader."Currency Code" = '' then
            CurrencyCode := GLSetup."LCY Code"
        else
            CurrencyCode := SalesInvoiceHeader."Currency Code";

        if CurrencyCode = GLSetup."LCY Code" then
            Currency.InitRoundingPrecision()
        else begin
            Currency.GET(CurrencyCode);
            Currency.TESTFIELD("Amount Rounding Precision");
        end;

        SalesInvLine.SETRANGE("Document No.", SalesInvoiceHeader."No.");
        SalesInvLine.SETFILTER(Type, '>%1', 0);
        SalesInvLine.SETFILTER("No.", '<>%1', ' ');
        SalesInvLine.SETFILTER(Quantity, '<>0');
        if NOT SalesInvLine.FINDSET() then
            EXIT;

        FromFile := CopyStr(RBMgt.ServerTempFileName(''), 1, MaxStrLen(FromFile));

        // Invoice
        XmlDocument.ReadFrom(OIOUBLXMLGenerator.GetInvoiceHeader(), XMLdocOut);
        XMLdocOut.GetRoot(XMLCurrNode);

        OIOUBLXMLGenerator.init(DocNameSpace, DocNameSpace2);

        XMLCurrNode.Add(XmlElement.Create('UBLVersionID', DocNameSpace, '2.0'));
        XMLCurrNode.Add(XmlElement.Create('CustomizationID', DocNameSpace, 'OIOUBL-2.02'));

        XMLCurrNode.Add(
          XmlElement.Create('ProfileID', DocNameSpace,
            XmlAttribute.Create('schemeID', 'urn:oioubl:id:profileid-1.2'),
            XmlAttribute.Create('schemeAgencyID', '320'),
            OIOUBLProfile.GetOIOUBLProfileID(SalesInvoiceHeader."OIOUBL-Profile Code", SalesInvoiceHeader."Sell-to Customer No.")));

        XMLCurrNode.Add(XmlElement.Create('ID', DocNameSpace, SalesInvoiceHeader."No."));
        XMLCurrNode.Add(XmlElement.Create('CopyIndicator', DocNameSpace,
          OIOUBLDocumentEncode.BooleanToText(SalesInvoiceHeader."OIOUBL-Electronic Invoice Created")));
        XMLCurrNode.Add(XmlElement.Create('IssueDate', DocNameSpace,
          OIOUBLDocumentEncode.DateToText(SalesInvoiceHeader."Posting Date")));

        XMLCurrNode.Add(XmlElement.Create('InvoiceTypeCode', DocNameSpace,
          XmlAttribute.Create('listID', 'urn:oioubl:codelist:invoicetypecode-1.1'),
          XmlAttribute.Create('listAgencyID', '320'),
          '380'));

        XMLCurrNode.Add(XmlElement.Create('DocumentCurrencyCode', DocNameSpace, CurrencyCode));
        XMLCurrNode.Add(XmlElement.Create('AccountingCostCode', DocNameSpace, SalesInvoiceHeader."OIOUBL-Account Code"));

        // Invoice->OrderReference
        if SalesInvoiceHeader."Order No." <> '' then
            OIOUBLXMLGenerator.InsertOrderReference(XMLCurrNode,
              SalesInvoiceHeader."External Document No.",
              SalesInvoiceHeader."Order No.",
              SalesInvoiceHeader."Order Date")
        else
            OIOUBLXMLGenerator.InsertOrderReference(XMLCurrNode,
              SalesInvoiceHeader."External Document No.",
              SalesInvoiceHeader."Pre-Assigned No.",
              SalesInvoiceHeader."Order Date");

        // Invoice->AccountingSupplierParty
        OIOUBLXMLGenerator.InsertAccountingSupplierParty(XMLCurrNode, SalesInvoiceHeader."Salesperson Code");

        // Invoice->AccountingCustomerParty
        BillToAddress.Address := SalesInvoiceHeader."Bill-to Address";
        BillToAddress."Address 2" := SalesInvoiceHeader."Bill-to Address 2";
        BillToAddress.City := SalesInvoiceHeader."Bill-to City";
        BillToAddress."Post Code" := SalesInvoiceHeader."Bill-to Post Code";
        BillToAddress."Country/Region Code" := SalesInvoiceHeader."Bill-to Country/Region Code";
        SellToContact.Name := SalesInvoiceHeader."Sell-to Contact";
        SellToContact."Phone No." := SalesInvoiceHeader."OIOUBL-Sell-to Contact Phone No.";
        SellToContact."Fax No." := SalesInvoiceHeader."OIOUBL-Sell-to Contact Fax No.";
        SellToContact."E-Mail" := SalesInvoiceHeader."OIOUBL-Sell-to Contact E-Mail";
        OIOUBLXMLGenerator.InsertAccountingCustomerParty(XMLCurrNode,
          SalesInvoiceHeader."OIOUBL-GLN",
          SalesInvoiceHeader."VAT Registration No.",
          SalesInvoiceHeader."Bill-to Name",
          BillToAddress,
          SellToContact);

        // Invoice->Delivery
        DeliveryAddress.Address := SalesInvoiceHeader."Ship-to Address";
        DeliveryAddress."Address 2" := SalesInvoiceHeader."Ship-to Address 2";
        DeliveryAddress.City := SalesInvoiceHeader."Ship-to City";
        DeliveryAddress."Post Code" := SalesInvoiceHeader."Ship-to Post Code";
        DeliveryAddress."Country/Region Code" := SalesInvoiceHeader."Ship-to Country/Region Code";
        OIOUBLXMLGenerator.InsertDelivery(XMLCurrNode, DeliveryAddress, SalesInvoiceHeader."Shipment Date");

        // Invoice->PaymentMeans
        OIOUBLXMLGenerator.InsertPaymentMeans(XMLCurrNode, SalesInvoiceHeader."Due Date");

        // Invoice->PaymentTerms
        SalesInvLine2.RESET();
        SalesInvLine2.COPY(SalesInvLine);
        SalesInvLine2.SETRANGE(Type);
        SalesInvLine2.SETRANGE("No.");
        SalesInvLine2.SETRANGE(Quantity);
        SalesInvLine2.CALCSUMS(Amount, "Amount Including VAT", "Inv. Discount Amount");
        OIOUBLXMLGenerator.InsertPaymentTerms(XMLCurrNode,
          SalesInvoiceHeader."Payment Terms Code",
          SalesInvoiceHeader."Payment Discount %",
          SalesInvoiceHeader."Currency Code",
          SalesInvoiceHeader."Pmt. Discount Date",
          SalesInvoiceHeader."Due Date",
          SalesInvLine2."Amount Including VAT");

        TotalInvDiscountAmount := 0;
        if SalesInvLine2.FINDSET() then
            repeat
                ExcludeVAT(SalesInvLine2, SalesInvoiceHeader."Prices Including VAT");
                TotalInvDiscountAmount := TotalInvDiscountAmount + GetDiscountAmount(SalesInvLine2);
            until SalesInvLine2.NEXT() = 0;

        // Invoice->AllowanceCharge
        if TotalInvDiscountAmount > 0 then
            OIOUBLXMLGenerator.InsertAllowanceCharge(XMLCurrNode, 1, 'Rabat', 'ReverseCharge',
              TotalInvDiscountAmount, SalesInvoiceHeader."Currency Code", 0);

        // Invoice->TaxTotal
        SalesInvLine2.RESET();
        SalesInvLine2.COPY(SalesInvLine);
        SalesInvLine2.SETFILTER(
          "VAT Calculation Type", '%1|%2|%3',
          SalesInvLine2."VAT Calculation Type"::"Normal VAT",
          SalesInvLine2."VAT Calculation Type"::"Full VAT",
          SalesInvLine2."VAT Calculation Type"::"Reverse Charge VAT");
        if SalesInvLine2.FINDFIRST() then begin
            TotalTaxAmount := 0;
            SalesInvLine2.CALCSUMS(Amount, "Amount Including VAT");
            TotalTaxAmount := SalesInvLine2."Amount Including VAT" - SalesInvLine2.Amount;

            InsertInvoiceTaxTotal(XMLCurrNode, SalesInvoiceHeader, SalesInvLine2, TotalTaxAmount);
        end;

        // Invoice->LegalMonetaryTotal
        TaxableAmount := 0;
        TaxAmount := 0;

        SalesInvLine2.RESET();
        SalesInvLine2.COPY(SalesInvLine);
        if SalesInvLine2.FINDSET() then
            repeat
                TaxableAmount := TaxableAmount + SalesInvLine2.Amount + GetDiscountAmount(SalesInvLine2);
                TotalAmount := TotalAmount + SalesInvLine2."Amount Including VAT";
                TaxAmount := TaxAmount + SalesInvLine2."Amount Including VAT" - SalesInvLine2.Amount;
            until SalesInvLine2.NEXT() = 0;

        OIOUBLXMLGenerator.InsertLegalMonetaryTotal(XMLCurrNode, TaxableAmount, TaxAmount, TotalAmount, TotalInvDiscountAmount, CurrencyCode);

        // Invoice->InvoiceLine
        repeat
            OnBeforeInsertInvoiceLine(SalesInvLine, XMLCurrNode, IsHandled);
            if not IsHandled then begin
                SalesInvLine.TESTFIELD(Description);

                ExcludeVAT(SalesInvLine, SalesInvoiceHeader."Prices Including VAT");
                InsertInvoiceLine(XMLCurrNode, SalesInvoiceHeader, SalesInvLine, CurrencyCode);
            end;
            OnAfterInsertInvoiceLine(SalesInvLine, XMLCurrNode);
        until SalesInvLine.NEXT() = 0;

        OutputBlob.Blob.CreateOutStream(FileOutstream);
        XMLdocOut.WriteTo(FileOutstream);
        if OutputBlob.Insert() then
            OnBeforeExportFile(OutputBlob, IsExported);

        if not IsExported then begin
            OutputFile.create(FromFile);
            OutputFile.CreateOutStream(FileOutstream);
            XMLdocOut.WriteTo(FileOutstream);
            OutputFile.Close();
        end;
    end;

    procedure ReadCompanyInfo();
    begin
        if NOT CompanyInfoRead then begin
            CompanyInfo.GET();
            CompanyInfoRead := TRUE;
        end;
    end;

    procedure ReadGLSetup();
    begin
        if NOT GLSetupRead then begin
            GLSetup.GET();
            GLSetupRead := TRUE;
        end;
    end;

    procedure UpdateTaxAmtAndTaxableAmt(Amount: Decimal; AmountIncludingVAT: Decimal; var TaxableAmountParam: Decimal; var TaxAmountParam: Decimal);
    begin
        TaxableAmountParam := TaxableAmountParam + Amount;
        TaxAmountParam := TaxAmountParam + AmountIncludingVAT - Amount;
    end;

    procedure ExcludeVAT(var SalesInvLine: Record "Sales Invoice Line"; PricesInclVAT: Boolean);
    var
        ExclVATFactor: Decimal;
    begin
        if NOT PricesInclVAT then
            EXIT;
        WITH SalesInvLine do begin
            ExclVATFactor := 1 + "VAT %" / 100;
            "Line Discount Amount" := ROUND("Line Discount Amount" / ExclVATFactor, Currency."Amount Rounding Precision");
            "Inv. Discount Amount" := ROUND("Inv. Discount Amount" / ExclVATFactor, Currency."Amount Rounding Precision");
            "Unit Price" := ROUND("Unit Price" / ExclVATFactor, Currency."Amount Rounding Precision");
        end;
    end;

    local procedure GetDiscountAmount(SalesInvLine: Record "Sales Invoice Line"): Decimal;
    begin
        WITH SalesInvLine do begin
            if "Line Discount %" = 100 then
                exit(Quantity * "Unit Price");
            exit("Inv. Discount Amount" + "Line Discount Amount");
        end;
    end;
    
    [IntegrationEvent(false,false)]
    local procedure OnBeforeInsertInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; var XMLCurrNode: XmlElement; var IsHandled: Boolean);
    begin
    end;



    [IntegrationEvent(false,false)]
    local procedure OnAfterInsertInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; var XMLCurrNode: XmlElement);
    begin
    end;

    [IntegrationEvent(false,false)]
    local procedure OnBeforeExportFile(var OutputBlob: Record TempBlob; var IsExported: Boolean);
    begin
    end;
}