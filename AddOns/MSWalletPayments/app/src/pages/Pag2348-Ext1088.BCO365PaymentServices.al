pageextension 1088 "MS - Wallet Payment Services" extends "BC O365 Payment Services"
{
    layout
    {
        addafter(Control85)
        {
            group("MsPayIsSetUpSpace")
            {
                InstructionalText = ' ';
                ShowCaption = false;
            }
            group("SetUpPayPalInMsPay")
            {
                InstructionalText = 'You can set up your PayPal account in Microsoft Pay Payments easily and fast. Once you do it, come back here and choose Microsoft Pay Payments as your payment service.';
                Visible = IsPaypalDefault and UserHasPermissions;
                ShowCaption = false;
            }
            group("SetUpMsPay")
            {
                InstructionalText = 'You can set up your Microsoft Pay Payments merchant profile easily and fast. Accept the terms of service and add your favourite payment providers, and we will take care of the rest.';
                Visible = not IsPaypalDefault and not IsMsPaySetupAndEnabled and UserHasPermissions;
                ShowCaption = false;
            }
            group(NonAdminUserMessage)
            {
                InstructionalText = 'Ask your Office 365 administrator to set up Microsoft Pay Payments so that your customers can pay you easily and fast.';
                Visible = not UserHasPermissions;
                ShowCaption = false;
            }
            group("MsPayIsSetUp")
            {
                InstructionalText = 'Your Microsoft Pay Payments merchant profile is configured and active. You are on track to be paid fast and easily!';
                Visible = not IsPaypalDefault and IsMsPaySetupAndEnabled and UserHasPermissions;
                ShowCaption = false;
            }

            group("SetUpMsPayLinkGroup")
            {
                ShowCaption = false;
                visible = not IsMerchantIdSet and UserHasPermissions;
                field("SetUpMsPayLinkControl"; MsPaySetupLbl)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Initiates the steps required to set up Microsoft Pay Payments for this company.';

                    trigger OnDrillDown();
                    var
                        MSWalletMerchantMgt: Codeunit 1084;
                        MSWalletMgt: Codeunit "MS - Wallet Mgt.";
                    begin
                        if not MSWalletMerchantAccount.FindFirst() then begin
                            MSWalletMgt.NewPaymentAccount(MSWalletMerchantAccount);
                            Commit();
                        end;

                        MSWalletMerchantMgt.StartMerchantOnboardingExperience(MSWalletMerchantAccount."Primary Key", MSWalletMerchantTemplate);
                        MSWalletMerchantTemplate.RefreshLogoIfNeeded();
                    end;
                }
            }
            group("MsPaySettingsLinkGroup")
            {
                ShowCaption = false;
                Visible = IsMerchantIdSet and UserHasPermissions;
                field("MsPaySettingsLinkControl"; MsPaySettingsLbl)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Page.RunModal(Page::"MS - Wallet Merch. Setup Inv");
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        UserHasPermissions := CheckUserHasPermissions();
        if not UserHasPermissions then
            SendTraceTag('00006ZJ', TelemetryCategoryTok, Verbosity::Normal, UserWithoutPermissionsMsg, DataClassification::SystemMetadata);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        GetRecordsAndSetVisibility();
    end;

    local procedure GetRecordsAndSetVisibility()
    var
        PaypalAccountProxy: Codeunit 1060;
        MSWalletMgt: Codeunit "MS - Wallet Mgt.";
        DummyBoolean: Boolean;
    begin
        if not MSWalletMerchantAccount.FindFirst() then begin
            IsMsPaySetupAndEnabled := false;
            IsMerchantIdSet := false;
        end else begin
            IsMsPaySetupAndEnabled := MSWalletMerchantAccount.Enabled and (MSWalletMerchantAccount."Merchant ID" <> '');
            IsMerchantIdSet := MSWalletMerchantAccount."Merchant ID" <> '';
        end;

        PaypalAccountProxy.GetPaypalSetupOptions(DummyBoolean, IsPaypalDefault);

        if UserHasPermissions then
            MSWalletMgt.GetTemplate(MSWalletMerchantTemplate);
    end;

    local procedure CheckUserHasPermissions(): Boolean
    var
        DummyMSWalletMerchantAccount: Record 1080;
        AzureADUserManagement: Codeunit 9010;
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit(DummyMSWalletMerchantAccount.WritePermission());

        if AzureADUserManagement.IsUserTenantAdmin() then
            exit(true);

        exit(false);
    end;

    var
        MSWalletMerchantAccount: Record 1080;
        MSWalletMerchantTemplate: Record 1081;
        IsMsPaySetupAndEnabled: Boolean;
        IsPaypalDefault: Boolean;
        IsMerchantIdSet: Boolean;
        UserHasPermissions: Boolean;
        MsPaySetupLbl: Label 'Set up Microsoft Pay Payments';
        MsPaySettingsLbl: Label 'Microsoft Pay Payments Settings';
        TelemetryCategoryTok: Label 'AL MSPAY', Locked = true;
        UserWithoutPermissionsMsg: Label 'An Invoicing user without permissions saw the corresponding label in the Microsoft Pay Payments settings page.', Locked = true;
}