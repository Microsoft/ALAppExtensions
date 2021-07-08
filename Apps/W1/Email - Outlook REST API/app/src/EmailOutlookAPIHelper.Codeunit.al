// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 4509 "Email - Outlook API Helper"
{
    Permissions = tabledata "Email - Outlook Account" = rimd;

    var
        CannotConnectToMailServerErr: Label 'Client ID or Client secret is not set up on the Email Application AAD Registration page.';
        SetupOutlookAPIQst: Label 'To connect to your email account you must create an App registration in Azure Active Directory and then enter information about the registration on the Email Application AAD Registration Page in Business Central. Do you want to do that now?';
        OnPremOnlyErr: Label 'Authentication using the Client ID and secret should only be used for Business Central on-premises.';
        AccountNotFoundErr: Label 'We could not find the account. Typically, this is because the account has been deleted.';
        EmailBodyTooLargeErr: Label 'The email is too large to send. The size limit is 4 MB, not including attachments.', Locked = true;

    procedure GetAccounts(Connector: Enum "Email Connector"; var Accounts: Record "Email Account")
    var
        Account: Record "Email - Outlook Account";
    begin
        Account.SetRange("Outlook API Email Connector", Connector);

        if Account.FindSet() then
            repeat
                Accounts."Account Id" := Account.Id;
                Accounts."Email Address" := Account."Email Address";
                Accounts.Name := Account.Name;
                Accounts.Connector := Connector;

                Accounts.Insert();
            until Account.Next() = 0;
    end;

    procedure DeleteAccount(AccountId: Guid): Boolean
    var
        OutlookAccount: Record "Email - Outlook Account";
    begin
        if OutlookAccount.Get(AccountId) then
            if OutlookAccount.WritePermission() then
                exit(OutlookAccount.Delete());
        exit(false);
    end;

    procedure EmailMessageToJson(EmailMessage: Codeunit "Email Message"; Account: Record "Email - Outlook Account"): JsonObject
    var
        EmailMessageJson: JsonObject;
        EmailAddressJson: JsonObject;
        FromJson: JsonObject;
    begin
        EmailAddressJson.Add('address', Account."Email Address");
        EmailAddressJson.Add('name', Account."Name");

        FromJson.Add('emailAddress', EmailAddressJson);
        EmailMessageJson.Add('from', FromJson);

        exit(EmailMessageToJson(EmailMessage, EmailMessageJson))
    end;

    procedure EmailMessageToJson(EmailMessage: Codeunit "Email Message"): JsonObject
    var
        EmailMessageJson: JsonObject;
    begin
        exit(EmailMessageToJson(EmailMessage, EmailMessageJson));
    end;

    procedure AddEmailAttachments(EmailMessage: Codeunit "Email Message"; var MessageJson: JsonObject)
    var
        AttachmentItemJson: JsonObject;
        AttachmentJson: JsonObject;
        AttachmentsArray: JsonArray;
    begin
        if not EmailMessage.Attachments_First() then
            exit;

        repeat
            Clear(AttachmentJson);
            Clear(AttachmentItemJson);
            AttachmentJson.Add('name', EmailMessage.Attachments_GetName());
            AttachmentJson.Add('contentType', EmailMessage.Attachments_GetContentType());
            AttachmentJson.Add('isInline', EmailMessage.Attachments_IsInline());

            if EmailMessage.Attachments_GetLength() <= MaximumAttachmentSizeInBytes() then begin
                AttachmentJson.Add('@odata.type', '#microsoft.graph.fileAttachment');
                AttachmentJson.Add('contentBytes', EmailMessage.Attachments_GetContentBase64());
                AttachmentsArray.Add(AttachmentJson);
            end else begin
                AttachmentJson.Add('attachmentType', 'file');
                AttachmentJson.Add('size', EmailMessage.Attachments_GetLength());
                AttachmentJson.Add('contentBytes', EmailMessage.Attachments_GetContentBase64());
                AttachmentItemJson.Add('AttachmentItem', AttachmentJson);
                AttachmentsArray.Add(AttachmentItemJson);
            end;
        until EmailMessage.Attachments_Next() = 0;

        MessageJson.Add('attachments', AttachmentsArray);
    end;

    local procedure EmailMessageToJson(EmailMessage: Codeunit "Email Message"; EmailMessageJson: JsonObject): JsonObject
    var
        MessageJson: JsonObject;
        MessageText: Text;
        EmailBody: JsonObject;
    begin
        if EmailMessage.IsBodyHTMLFormatted() then
            EmailBody.Add('contentType', 'HTML')
        else
            EmailBody.Add('contentType', 'text');

        EmailBody.Add('content', EmailMessage.GetBody());

        EmailMessageJson.Add('subject', EmailMessage.GetSubject());
        EmailMessageJson.Add('body', EmailBody);
        EmailMessageJson.Add('toRecipients', GetEmailRecipients(EmailMessage, Enum::"Email Recipient Type"::"To"));
        EmailMessageJson.Add('ccRecipients', GetEmailRecipients(EmailMessage, Enum::"Email Recipient Type"::Cc));
        EmailMessageJson.Add('bccRecipients', GetEmailRecipients(EmailMessage, Enum::"Email Recipient Type"::Bcc));

        // If message json > max request size, then error as the email body is too large.
        EmailMessageJson.WriteTo(MessageText);
        if StrLen(MessageText) > MaximumRequestSizeInBytes() then
            Error(EmailBodyTooLargeErr);

        AddEmailAttachments(EmailMessage, EmailMessageJson);

        // If message json <= max request size, wrap it in message object to send in a single request.
        EmailMessageJson.WriteTo(MessageText);
        if StrLen(MessageText) > MaximumRequestSizeInBytes() then
            MessageJson := EmailMessageJson
        else begin
            MessageJson.Add('message', EmailMessageJson);
            MessageJson.Add('saveToSentItems', true);
        end;

        exit(MessageJson);
    end;

    local procedure GetEmailRecipients(EmailMessage: Codeunit "Email Message"; EmailRecipientType: enum "Email Recipient Type"): JsonArray
    var
        Address: JsonObject;
        Recipients: List of [Text];
        RecipientsJson: JsonArray;
        EmailAddress: JsonObject;
        Value: Text;
    begin
#pragma warning disable AA0205
        EmailMessage.GetRecipients(EmailRecipientType, Recipients);
#pragma warning restore AA0205
        foreach value in Recipients do begin
            clear(Address);
            clear(EmailAddress);
            Address.Add('address', value);
            EmailAddress.Add('emailAddress', Address);
            RecipientsJson.Add(EmailAddress);
        end;
        exit(RecipientsJson);
    end;

    [NonDebuggable]
    procedure GetClientIDAndSecret(var ClientId: Text; var ClientSecret: Text)
    var
        Setup: Record "Email - Outlook API Setup";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            Error(OnPremOnlyErr);

        if not IsAzureAppRegistrationSetup() then
            Error(CannotConnectToMailServerErr);

        Setup.Get();
        if not IsolatedStorage.Get(Setup.ClientId, DataScope::Module, ClientId) then
            Error(CannotConnectToMailServerErr);
        if not IsolatedStorage.Get(Setup.ClientSecret, DataScope::Module, ClientSecret) then
            Error(CannotConnectToMailServerErr);
    end;

    procedure SetupAzureAppRegistration()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then // The setup is needed only for OnPrem
            exit;

        if IsAzureAppRegistrationSetup() then // The setup already exists
            exit;

        if not Confirm(SetupOutlookAPIQst) then // The user doesn't want to setup the app registration
            exit;

        Page.RunModal(Page::"Email - Outlook API Setup");
    end;

    procedure GetRedirectURL(): Text
    var
        Setup: Record "Email - Outlook API Setup";
    begin
        if Setup.Get() then
            exit(Setup.RedirectURL);
    end;

    procedure GetTenantID(): Text
    var
        Setup: Record "Email - Outlook API Setup";
    begin
        if Setup.Get() then
            exit(Setup.TenantID);
    end;

    procedure IsAzureAppRegistrationSetup(): Boolean
    var
        Setup: Record "Email - Outlook API Setup";
    begin
        exit(Setup.Get() and
            (not IsNullGuid(Setup.ClientId)) and
            (not IsNullGuid(Setup.ClientSecret)));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Email - Outlook API Setup", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnDeleteOutlookAPIAccount(var Rec: Record "Email - Outlook API Setup")
    begin
        if IsolatedStorage.Contains(Rec.ClientId, DataScope::Module) then
            IsolatedStorage.Delete(Rec.ClientId, DataScope::Module);

        if IsolatedStorage.Contains(Rec.ClientSecret, DataScope::Module) then
            IsolatedStorage.Delete(Rec.ClientSecret, DataScope::Module);
    end;

    procedure InitializeClients(var OutlookAPIClient: interface "Email - Outlook API Client"; var OAuthClient: interface "Email - OAuth Client")
    var
        DefaultAPIClient: Codeunit "Email - Outlook API Client";
        DefaultOAuthClient: Codeunit "Email - OAuth Client";
    begin
        OutlookAPIClient := DefaultAPIClient;
        OAuthClient := DefaultOAuthClient;
        OnAfterInitializeClients(OutlookAPIClient, OAuthClient);
    end;

    procedure Send(EmailMessage: Codeunit "Email Message"; AccountId: Guid)
    var
        EmailOutlookAccount: Record "Email - Outlook Account";
        APIClient: interface "Email - Outlook API Client";
        OAuthClient: interface "Email - OAuth Client";

        [NonDebuggable]
        AccessToken: Text;
    begin
        InitializeClients(APIClient, OAuthClient);
        if not EmailOutlookAccount.Get(AccountId) then
            Error(AccountNotFoundErr);

        OAuthClient.GetAccessToken(AccessToken);
        APIClient.SendEmail(AccessToken, EmailMessageToJson(EmailMessage, EmailOutlookAccount));
    end;

    procedure Send(EmailMessage: Codeunit "Email Message")
    var
        APIClient: interface "Email - Outlook API Client";
        OAuthClient: interface "Email - OAuth Client";

        [NonDebuggable]
        AccessToken: Text;
    begin
        InitializeClients(APIClient, OAuthClient);

        OAuthClient.GetAccessToken(AccessToken);
        APIClient.SendEmail(AccessToken, EmailMessageToJson(EmailMessage));
    end;

    [InternalEvent(false)]
    local procedure OnAfterInitializeClients(var OutlookAPIClient: interface "Email - Outlook API Client"; var OAuthClient: interface "Email - OAuth Client")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sandbox Cleanup", 'OnClearCompanyConfiguration', '', false, false)]
    local procedure DeleteEmailAccountsForSandbox(CompanyName: Text)
    var
        OutlookAccounts: Record "Email - Outlook Account";
    begin
        OutlookAccounts.DeleteAll();
    end;

    local procedure MaximumRequestSizeInBytes(): Integer
    begin
        exit(4194304); // 4 mb
    end;

    local procedure MaximumAttachmentSizeInBytes(): Integer
    begin
        exit(3145728); // 3 mb
    end;
}