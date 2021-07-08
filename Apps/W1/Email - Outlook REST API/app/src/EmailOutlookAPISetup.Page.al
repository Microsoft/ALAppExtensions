// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 4509 "Email - Outlook API Setup"
{
    PageType = NavigatePage;
    UsageCategory = Administration;
    SourceTable = "Email - Outlook API Setup";
    Caption = 'Email Application AAD Registration';
    DataCaptionExpression = ' ';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(TopBanner)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible;
                field(NotDoneIcon; MediaResources."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = ' ';
                    Caption = ' ';
                }
            }
            group(Info)
            {
                InstructionalText = 'You must already have registered your application in Azure Active Directory and granted certain permissions. Use the client ID and secret from that registration to authenticate the email account.';
                ShowCaption = false;
                Visible = 1 > 0;

                field(Doc; AppRegistrationsLbl)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = ' ';

                    trigger OnDrillDown()
                    begin
                        Hyperlink(DocumentationAzureUlrTxt);
                    end;
                }

                field(Doc2; AppPermissionsLbl)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = ' ';

                    trigger OnDrillDown()
                    begin
                        Hyperlink(DocumentationBCUlrTxt);
                    end;
                }

                group(Secrets)
                {
                    Caption = 'Azure Application registration';
                    field(ClientId; ClientIdText)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Client Id.';
                        Caption = 'Client Id';

                        trigger OnValidate()
                        begin
                            if ClientIdText = HiddenValueTxt then
                                exit;
                            if isNullGuid(Rec.ClientId) then
                                Rec.ClientId := CreateGuid();
                            IsolatedStorage.Set(Rec.ClientId, ClientIdText, DataScope::Module);
                            ClientIdText := HiddenValueTxt;

                            SetTestSetupEnabled();
                        end;
                    }

                    field(ClientSecret; ClientSecretText)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Client Secret.';
                        Caption = 'Client Secret';

                        trigger OnValidate()
                        begin
                            if ClientSecretText = HiddenValueTxt then
                                exit;
                            if isNullGuid(Rec.ClientSecret) then
                                Rec.ClientSecret := CreateGuid();
                            IsolatedStorage.Set(Rec.ClientSecret, ClientSecretText, DataScope::Module);
                            ClientSecretText := HiddenValueTxt;

                            SetTestSetupEnabled();
                        end;
                    }

                    field(RedirectURL; Rec.RedirectURL)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Redirect URL.';
                        Caption = 'Redirect URL';

                        trigger OnValidate()
                        begin
                            ValidateUri(Rec.RedirectURL);
                        end;
                    }

                    field(TenantID; Rec.TenantID)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Tenant ID.';
                        Caption = 'Tenant ID';
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Ok)
            {
                ApplicationArea = All;
                Image = NextRecord;
                ToolTip = ' ';
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
            action(SingInAgain)
            {
                ApplicationArea = All;
                Image = GoTo;
                InFooterBar = true;
                ToolTip = 'Change the email account that is associated with the email app registration for the current user.';
                Caption = 'Sign in with a different account';
                Visible = IsUserLoggedIn;

                trigger OnAction()
                var
                    EmailOAuthClient: Codeunit "Email - OAuth Client";
                begin
                    EmailOAuthClient.SignInUsingAuthorizationCode();
                end;
            }

            action(TestSetupAction)
            {
                ApplicationArea = All;
                Image = TestFile;
                InFooterBar = true;
                ToolTip = 'Verify that you can use the settings on this page to authenticate to the application registration.';
                Caption = 'Verify Registration';
                Enabled = TestSetupEnabled;

                trigger OnAction()
                begin
                    TestSetup();
                end;
            }

            action(Clear)
            {
                ApplicationArea = All;
                Image = FaultDefault;
                ToolTip = 'Delete the Azure Active Directory app registration information in Business Central.';
                InFooterBar = true;
                Caption = 'Clear';

                trigger OnAction()
                var
                    DummyGuid: Guid;
                begin
                    if not Confirm(ThisWillClearTheFieldsTxt) then
                        exit;
                    if IsolatedStorage.Contains(Rec.ClientSecret, DataScope::Module) then
                        IsolatedStorage.Delete(Rec.ClientSecret, DataScope::Module);
                    if IsolatedStorage.Contains(Rec.ClientId, DataScope::Module) then
                        IsolatedStorage.Delete(Rec.ClientId, DataScope::Module);

                    Rec.ClientId := DummyGuid;
                    Rec.ClientSecret := DummyGuid;
                    Rec.RedirectURL := '';
                    Rec.TenantID := '';
                    ClientSecretText := '';
                    ClientIdText := '';

                    SetTestSetupEnabled();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        EmailOutlookAPIHelper: Codeunit "Email - Outlook API Helper";
        EmailOAuthClient: Codeunit "Email - OAuth Client";
        OAuth2: Codeunit "OAuth2";
        RedirectURLTxt: Text;
    begin
        if not Rec.Get() then
            Rec.Insert();

        if not IsNullGuid(Rec.ClientId) then
            ClientIdText := HiddenValueTxt;

        if not IsNullGuid(Rec.ClientSecret) then
            ClientSecretText := HiddenValueTxt;

        if Rec.RedirectURL = '' then begin
            OAuth2.GetDefaultRedirectUrl(RedirectURLTxt);
            Rec.RedirectURL := CopyStr(RedirectURLTxt, 1, MaxStrLen(Rec.RedirectURL));
            Rec.Modify();
        end;

        if Rec.TenantID = '' then begin
            Rec.TenantID := CopyStr(DefaultTenantId, 1, MaxStrLen(Rec.TenantID));
            Rec.Modify();
        end;

        if MediaResources.Get('ASSISTEDSETUP-NOTEXT-400PX.PNG') and (CurrentClientType = ClientType::Web) then
            TopBannerVisible := MediaResources."Media Reference".HasValue;

        if EmailOutlookAPIHelper.IsAzureAppRegistrationSetup() then
            IsUserLoggedIn := EmailOAuthClient.AuthorizationCodeTokenCacheExists();

        SetTestSetupEnabled();
    end;

    local procedure ValidateUri(UriString: Text)
    var
        Uri: Codeunit Uri;
    begin
        if UriString = '' then
            exit;

        if not Uri.IsValidUri(UriString) then
            Error(UriIsNotValidErr, UriString);
    end;

    local procedure SetTestSetupEnabled()
    begin
        TestSetupEnabled := (not IsNullGuid(Rec.ClientId)) and (not IsNullGuid(Rec.ClientSecret));
    end;

    local procedure TestSetup()
    var
        EmailOAuthClient: Codeunit "Email - OAuth Client";
        [NonDebuggable]
        AccessToken: Text;
    begin
        if not EmailOAuthClient.TryGetAccessToken(AccessToken, true) then
            Message(UnsuccessfulTestMsg)
        else
            Message(SuccessfulTestMsg);
    end;

    var
        MediaResources: Record "Media Resources";
        ClientIdText: Text;
        ClientSecretText: Text;
        DocumentationAzureUlrTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2134620', Locked = true;
        DocumentationBCUlrTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2134520', Locked = true;
        AppRegistrationsLbl: Label 'Learn more about app registration';
        AppPermissionsLbl: Label 'Learn more about the permissions';
        ThisWillClearTheFieldsTxt: Label 'If you clear the app registration on this page, users will not be able to send email messages from their Exchange accounts. Do you want to continue?';
        UriIsNotValidErr: Label '%1 is not a valid URI.', Comment = '%1 = a string';
        UnsuccessfulTestMsg: Label 'We could not get access token with the current setup.\\Please verify the values on the page and try again.';
        SuccessfulTestMsg: Label 'Success! Your authentication was verified.';
        HiddenValueTxt: Label '******', Locked = true;
        DefaultTenantId: Label 'Common', Locked = true;
        TopBannerVisible: Boolean;
        [InDataSet]
        IsUserLoggedIn: Boolean;
        TestSetupEnabled: Boolean;
}