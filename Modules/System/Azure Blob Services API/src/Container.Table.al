// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

table 9040 "Container"
{
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
        }
        field(10; Name; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Name';
        }
        field(11; "Last-Modified"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Last-Modified';
        }
        field(12; LeaseStatus; Text[15])
        {
            DataClassification = CustomerContent;
            Caption = 'LeaseStatus';
        }
        field(13; LeaseState; Text[15])
        {
            DataClassification = CustomerContent;
            Caption = 'LeaseState';
        }
        field(14; DefaultEncryptionScope; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'DefaultEncryptionScope';
        }
        field(15; DenyEncryptionScopeOverride; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'DenyEncryptionScopeOverride';
        }
        field(16; HasImmutabilityPolicy; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'HasImmutabilityPolicy';
        }
        field(17; HasLegalHold; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'HasLegalHold';
        }
        field(100; "XML Value"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'XML Value';
        }
        field(110; URI; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'URI';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
    var
        OperationPayload: Codeunit "Blob API Operation Payload";
        StorageAccountName: Text;
        ContainerName: Text;

    procedure SetBaseInfos(NewOperationPayload: Codeunit "Blob API Operation Payload")
    begin
        StorageAccountName := OperationPayload.GetStorageAccountName();
        ContainerName := OperationPayload.GetContainerName();
        OperationPayload := NewOperationPayload;
    end;

    procedure AddNewEntryFromNode(var Node: XmlNode; XPathName: Text)
    var
        HelperLibrary: Codeunit "Blob API Helper Library";
        NameFromXml: Text;
        OuterXml: Text;
        ChildNodes: XmlNodeList;
        PropertiesNode: XmlNode;
    begin
        NameFromXml := HelperLibrary.GetValueFromNode(Node, XPathName);
        Node.WriteTo(OuterXml);
        Node.SelectSingleNode('.//Properties', PropertiesNode);
        ChildNodes := PropertiesNode.AsXmlElement().GetChildNodes();
        if ChildNodes.Count = 0 then
            Rec.AddNewEntry(NameFromXml, OuterXml)
        else
            Rec.AddNewEntry(NameFromXml, OuterXml, ChildNodes);
    end;

    procedure AddNewEntry(NameFromXml: Text; OuterXml: Text)
    var
        ChildNodes: XmlNodeList;
    begin
        AddNewEntry(NameFromXml, OuterXml, ChildNodes);
    end;

    procedure AddNewEntry(NameFromXml: Text; OuterXml: Text; ChildNodes: XmlNodeList)
    var
        NextEntryNo: Integer;
        Outstr: OutStream;
    begin
        NextEntryNo := GetNextEntryNo();

        Rec.Init();
        Rec."Entry No." := NextEntryNo;
        Rec.Name := CopyStr(NameFromXml, 1, 250);
        SetPropertyFields(ChildNodes);
        Rec."XML Value".CreateOutStream(Outstr);
        Outstr.Write(OuterXml);
        //Rec.URI := HelperLibrary.ConstructUrl(StorageAccountName, OperationPayload, Operation::ListContainerContents, ContainerName, NameFromXml);
        Rec.Insert(true);
    end;

    local procedure GetNextEntryNo(): Integer
    begin
        if Rec.FindLast() then
            exit(Rec."Entry No." + 1)
        else
            exit(1);
    end;

    local procedure SetPropertyFields(ChildNodes: XmlNodeList)
    var
        FormatHelper: Codeunit "Blob API Format Helper";
        HelperLibrary: Codeunit "Blob API Helper Library";
        RecRef: RecordRef;
        FldRef: FieldRef;
        ChildNode: XmlNode;
        PropertyName: Text;
        PropertyValue: Text;
        FldNo: Integer;
    begin
        foreach ChildNode in ChildNodes do begin
            PropertyName := ChildNode.AsXmlElement().Name;
            PropertyValue := ChildNode.AsXmlElement().InnerText;
            if PropertyValue <> '' then begin
                RecRef.GetTable(Rec);
                if HelperLibrary.GetFieldByName(Database::"Container", PropertyName, FldNo) then begin
                    FldRef := RecRef.Field(FldNo);
                    case FldRef.Type of
                        FldRef.Type::DateTime:
                            FldRef.Value := FormatHelper.ConvertToDateTime(PropertyValue);
                        FldRef.Type::Integer:
                            FldRef.Value := FormatHelper.ConvertToInteger(PropertyValue);
                        FldRef.Type::Boolean:
                            FldRef.Value := FormatHelper.ConvertToBoolean(PropertyValue);
                        else
                            FldRef.Value := PropertyValue;
                    end;
                end;
            end;
            RecRef.SetTable(Rec);
        end;
    end;
}