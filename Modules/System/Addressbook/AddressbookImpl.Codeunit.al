codeunit 8944 "Addressbook Impl"
{

    procedure SelectRecipient(MessageID: Guid; var EmailAddressRecord: Record "Email Address")
    var
        EmailRelatedRecord: Record "Email Related Record";
        Addressbook: Codeunit Addressbook;
        EmailAddressPage: Page "Email Address";
    begin
        // Get Suggested Email Addresses
        EmailRelatedRecord.SetRange("Email Message Id", MessageID);
        if EmailRelatedRecord.FindSet() then
            repeat
                Addressbook.OnGetSuggestedAddresses(EmailRelatedRecord."Table Id", EmailRelatedRecord."System Id", EmailAddressRecord);
            until EmailRelatedRecord.Next() = 0;


        // Open Addressbook in Lookupmode 
        EmailAddressPage.LookupMode(true);
        EmailAddressPage.InsertAddresses(EmailAddressRecord);
        EmailAddressRecord.DeleteAll();
        if EmailAddressPage.RunModal() <> Action::LookupOK then
            exit;

        // Return selected addresses
        EmailAddressPage.GetSelectedAddresses(EmailAddressRecord);
    end;

    procedure GetEmailsFrom(var EmailAddress: Record "Email Address") Recipients: Text
    begin
        if (StrLen(Recipients) > 0) and (not Recipients.EndsWith(';')) then
            Recipients += ';';
        if EmailAddress.FindSet() then
            repeat
                Recipients += EmailAddress."E-Mail Address" + ';';
            until EmailAddress.Next() = 0;
    end;

    procedure EmailAddressLookup(var EmailAddressRecord: Record "Email Address"): Boolean
    var
        RetrievedEmailAddress: Record "Email Address";
        Addressbook: Codeunit Addressbook;
        EmailAddressEntityPage: Page "Email Address Entity";
        IsHandled: Boolean;
    begin
        // Retrieve and select entity
        Addressbook.OnGetEmailAddressEntity(RetrievedEmailAddress);
        EmailAddressEntityPage.LookupMode(true);
        EmailAddressEntityPage.InsertAddresses(RetrievedEmailAddress);
        if EmailAddressEntityPage.RunModal() <> Action::LookupOK then
            exit;
        RetrievedEmailAddress.DeleteAll();

        // Look up email address from chosen entity  
        EmailAddressEntityPage.GetSelectedAddresses(RetrievedEmailAddress);
        Addressbook.OnLookupEmailAddressFromEntity(RetrievedEmailAddress.SourceTable, RetrievedEmailAddress, IsHandled);

        if IsHandled then
            if StrLen(RetrievedEmailAddress."E-Mail Address") = 0 then
                Message(NoEmailAddressMsg)
            else
                if EmailAddressRecord.Get(RetrievedEmailAddress."E-Mail Address", RetrievedEmailAddress."Source Name") then
                    Message(EmailAddressDuplicateMsg)
                else begin
                    EmailAddressRecord.TransferFields(RetrievedEmailAddress);
                    EmailAddressRecord.Insert();
                end;
        exit(IsHandled);
    end;

    var
        NoEmailAddressMsg: Label 'Record had no email address';
        EmailAddressDuplicateMsg: Label 'Email Address already added';
}