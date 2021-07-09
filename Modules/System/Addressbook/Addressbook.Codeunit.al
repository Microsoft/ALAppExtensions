codeunit 8945 Addressbook
{
    #region Events

    /// <summary>
    /// Event that allows subscribers to populate the list of "Suggested Contacts" in the Addressbook
    /// </summary>
    /// <param name="SourceTableNo">Table number of a related record</param>
    /// <param name="SourceSystemID">SystemID of a related record</param>
    /// <param name="EmailAddress">EmailAddress record used to return addresses</param>
    [IntegrationEvent(false, false)]
    internal procedure OnGetSuggestedAddresses(SourceTableNo: Integer; SourceSystemID: Guid; var EmailAddress: Record "Email Address")
    begin
    end;

    /// <summary>
    /// Event that retrieves contact information from a specified entity
    /// </summary>
    /// <param name="TableNo">Table number of entity</param>
    /// <param name="EmailAddress">EmailAddress record used to return addresses</param>
    /// <param name="IsHandled">Boolean indicating whether the event has been handled</param>
    [IntegrationEvent(false, false)]
    internal procedure OnLookupEmailAddressFromEntity(TableNo: Integer; var EmailAddress: Record "Email Address"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event that retrieves a list of entities (Contact, Customer, Vendor etc.) that the addressbook should be able to get information from
    /// </summary>
    /// <param name="EmailAddress">EmailAddress record used to return addresses</param> 
    [IntegrationEvent(false, false)]
    internal procedure OnGetEmailAddressEntity(var EmailAddress: Record "Email Address") //TODO: Replace "Email Address" record with a "Addressbook Entity" record here. For now simply populate "Source Name" and "SourceTable"
    begin
    end;
    #endregion

    /// <summary>
    /// Launches the addressbook and allows the user to select a recipient
    /// </summary>
    /// <param name="MessageID">Email Message ID</param>
    /// <param name="EmailAddress">EmailAddress record used to return addresses</param>
    procedure SelectRecipient(MessageID: Guid; var EmailAddress: Record "Email Address")
    begin
        AddressbookImpl.SelectRecipient(MessageID, EmailAddress);
    end;

    /// <summary>
    /// Produces a string of email addresses from an Email Address record
    /// </summary>
    /// <param name="EmailAddress">A non-empty Email Address record</param>
    /// <returns>A concatenated string of the email addresses</returns>
    procedure GetEmailsFrom(var EmailAddress: Record "Email Address"): Text
    begin
        exit(AddressbookImpl.GetEmailsFrom(EmailAddress));
    end;

    var
        AddressbookImpl: Codeunit "Addressbook Impl";
}