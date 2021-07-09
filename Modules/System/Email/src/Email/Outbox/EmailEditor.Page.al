// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// A page to create, edit and send e-mails.
/// </summary>
page 13 "Email Editor"
{
    PageType = Document;
    SourceTable = "Email Outbox";
    Caption = 'Compose an Email';
    Permissions = tabledata "Email Outbox" = rm,
                  tabledata "Email Message Attachment" = rid;
    UsageCategory = Tasks;
    ApplicationArea = All;
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    Extensible = true;

    layout
    {
        area(Content)
        {
            group("Email Details")
            {
                grid("Email Details Grid")
                {
                    group("Email Inner Details")
                    {
                        ShowCaption = false;

                        field(Account; FromDisplayName)
                        {
                            ShowMandatory = true;
                            ApplicationArea = All;
                            Caption = 'From';
                            ToolTip = 'Specifies the account to send the email from.';
                            Editable = false;
                            Enabled = not EmailScheduled;

                            trigger OnAssistEdit()
                            begin
                                EmailEditor.ChangeEmailAccount(Rec, TempEmailAccount);

                                UpdateFromField(TempEmailAccount);
                                CurrPage.Update();
                            end;
                        }

                        field(ToField; ToRecipient)
                        {
                            ShowMandatory = true;
                            Caption = 'To';
                            ApplicationArea = All;
                            ToolTip = 'Specifies the email addresses to send the email to.';
                            Editable = not EmailScheduled;
                            Importance = Promoted;

                            trigger OnValidate()
                            begin
                                EmailMessage.SetRecipients(Enum::"Email Recipient Type"::"To", ToRecipient);
                            end;

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                EmailAddressRecord: Record "Email Address";
                                Addressbook: Codeunit Addressbook;
                            begin
                                Addressbook.SelectRecipient(Rec."Message Id", EmailAddressRecord);
                                if EmailAddressRecord.FindSet() then
                                    Text += Addressbook.GetEmailsFrom(EmailAddressRecord);
                                exit(true)
                            end;
                        }

                        field(CcField; CcRecipient)
                        {
                            Caption = 'Cc';
                            ApplicationArea = All;
                            ToolTip = 'Specifies the email addresses of people who should receive a copy of the email.';
                            Editable = not EmailScheduled;
                            Importance = Additional;

                            trigger OnValidate()
                            begin
                                EmailMessage.SetRecipients(Enum::"Email Recipient Type"::Cc, CcRecipient);
                            end;

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                EmailAddressRecord: Record "Email Address";
                                Addressbook: Codeunit Addressbook;
                            begin
                                Addressbook.SelectRecipient(Rec."Message Id", EmailAddressRecord);
                                if EmailAddressRecord.FindSet() then
                                    Text += Addressbook.GetEmailsFrom(EmailAddressRecord);
                                exit(true)
                            end;
                        }

                        field(BccField; BccRecipient)
                        {
                            Caption = 'Bcc';
                            ApplicationArea = All;
                            ToolTip = 'Specifies the email addresses of people who should receive a blind carbon copy (Bcc) of the email. These addresses are not shown to other recipients.';
                            Editable = not EmailScheduled;
                            Importance = Additional;

                            trigger OnValidate()
                            begin
                                EmailMessage.SetRecipients(Enum::"Email Recipient Type"::Bcc, BccRecipient);
                            end;

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                EmailAddressRecord: Record "Email Address";
                                Addressbook: Codeunit Addressbook;
                            begin
                                Addressbook.SelectRecipient(Rec."Message Id", EmailAddressRecord);
                                if EmailAddressRecord.FindSet() then
                                    Text += Addressbook.GetEmailsFrom(EmailAddressRecord);
                                exit(true)
                            end;
                        }

                        field(SubjectField; EmailSubject)
                        {
                            Caption = 'Subject';
                            ApplicationArea = All;
                            ToolTip = 'Specifies the subject of the email.';
                            Editable = not EmailScheduled;
                            Importance = Promoted;

                            trigger OnValidate()
                            begin
                                EmailMessage.SetSubject(EmailSubject);
                                EmailMessage.Modify();

                                Rec.Description := CopyStr(EmailSubject, 1, MaxStrLen(Rec.Description));
                                Rec.Modify();

                                CurrPage.Caption(EmailSubject);
                                CurrPage.Update();
                            end;
                        }
                    }
                }
            }

            group(HTMLFormattedBody)
            {
                ShowCaption = false;
                Caption = ' ';
                Visible = IsHTMLFormatted;

                field("Email Editor"; EmailBody)
                {
                    Caption = 'Message';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the content of the email.';
                    MultiLine = true;
                    Editable = not EmailScheduled;

                    trigger OnValidate()
                    begin
                        EmailMessage.SetBody(EmailBody);
                        EmailMessage.Modify();
                    end;
                }
            }

            group(RawTextBody)
            {
                ShowCaption = false;
                Caption = ' ';
                Visible = not IsHTMLFormatted;

                field(BodyField; EmailBody)
                {
                    Caption = 'Message';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the content of the email.';
                    MultiLine = true;
                    Editable = not EmailScheduled;

                    trigger OnValidate()
                    begin
                        EmailMessage.SetBody(EmailBody);
                        EmailMessage.Modify();
                    end;
                }
            }

            part(Attachments; "Email Attachments")
            {
                ApplicationArea = All;
                SubPageLink = "Email Message Id" = field("Message Id");
                UpdatePropagation = SubPart;
                Caption = 'Attachments';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Send)
            {
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Caption = 'Send Email';
                ToolTip = 'Send the email.';
                ApplicationArea = All;
                Enabled = not EmailScheduled;
                Image = SendMail;

                trigger OnAction()
                var
                    IsEmailDataValid: Boolean;
                begin
                    IsEmailDataValid := EmailEditor.ValidateEmailData(TempEmailAccount."Email Address", EmailMessage);

                    if IsEmailDataValid then begin
                        IsNewOutbox := false;
                        EmailEditor.SendOutbox(Rec);
                        EmailAction := Enum::"Email Action"::Sent;

                        CurrPage.Close();
                    end;
                end;
            }
            action(Discard)
            {
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Caption = 'Discard Draft';
                ToolTip = 'Discard the draft email and close the page.';
                ApplicationArea = All;
                Enabled = not EmailScheduled;
                Image = Delete;

                trigger OnAction()
                begin
                    if EmailEditor.DiscardEmail(Rec, true) then begin
                        IsNewOutbox := false;
                        EmailAction := Enum::"Email Action"::Discarded;
                        CurrPage.Close();
                    end;
                end;
            }
            action(Upload)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Image = Attach;
                Enabled = not EmailScheduled;
                Caption = 'Attach File';
                ToolTip = 'Attach files, such as documents or images, to the email.';

                trigger OnAction()
                begin
                    EmailEditor.UploadAttachment(EmailMessage);

                    CurrPage.Attachments.Page.UpdateDeleteEnablement();
                    CurrPage.Attachments.Page.Update();
                end;
            }

            action(ShowSourceRecord)
            {
                ApplicationArea = All;
                Image = GetSourceDoc;
                Caption = 'Show Source';
                ToolTip = 'Open the page from where the email was sent.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    EmailImpl: Codeunit "Email Impl";
                begin
                    EmailImpl.ShowSourceRecord(Rec."Message Id");
                end;
            }

            action(SourceAttachments)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Image = Attach;
                Caption = 'Get Source Attachments';
                ToolTip = 'Attach a file that was originally attached to the source document.';
                Scope = Page;

                trigger OnAction()
                begin
                    EmailEditor.AttachFromRelatedRecords(Rec."Message Id");
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        EmailEditor.CheckPermissions(Rec);

        EmailEditor.GetEmailAccount(Rec, TempEmailAccount);
        EmailEditor.GetEmailMessage(Rec, EmailMessage);

        UpdateFromField(TempEmailAccount);
        ToRecipient := EmailMessage.GetRecipientsAsText(Enum::"Email Recipient Type"::"To");
        CcRecipient := EmailMessage.GetRecipientsAsText(Enum::"Email Recipient Type"::Cc);
        BccRecipient := EmailMessage.GetRecipientsAsText(Enum::"Email Recipient Type"::Bcc);
        EmailBody := EmailMessage.GetBody();
        EmailSubject := EmailMessage.GetSubject();

        if EmailSubject <> '' then
            CurrPage.Caption(EmailSubject)
        else
            CurrPage.Caption(PageCaptionTxt); // fallback to default caption

        EmailScheduled := Rec.Status in [Enum::"Email Status"::Queued, Enum::"Email Status"::Processing];
        IsHTMLFormatted := EmailMessage.IsBodyHTMLFormatted();
        CurrPage.Attachments.Page.UpdateValues(EmailMessage.GetId());
    end;

    trigger OnOpenPage()
    begin
        EmailEditor.CheckPermissions(Rec);

        Rec.SetRange("User Security Id", UserSecurityId());
        CurrPage.SetTableView(Rec);

        if not IsNewOutbox then begin // if the outbox is set as new, do not create new outbox
            IsNewOutbox := Rec.Id = 0;
            if IsNewOutbox then
                EmailEditor.CreateOutbox(Rec);
        end;

        if IsNewOutbox then begin  // Disable arrows if it's a new record
            Rec.SetRange(Id, Rec.Id);
            CurrPage.SetTableView(Rec);
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if IsNewOutbox then
            exit(ShowCloseOptionsMenu());
    end;

    local procedure UpdateFromField(EmailAccount: Record "Email Account" temporary)
    begin
        if EmailAccount."Email Address" = '' then
            FromDisplayName := ''
        else
            FromDisplayName := StrSubstNo(FromDisplayNameLbl, EmailAccount.Name, EmailAccount."Email Address");
    end;

    local procedure ShowCloseOptionsMenu(): Boolean
    var
        CloseOptions: Text;
        SelectedCloseOption: Integer;
    begin
        CloseOptions := OptionsOnClosePageNewEmailLbl;
        SelectedCloseOption := Dialog.StrMenu(CloseOptions, 1, CloseThePageQst);

        case SelectedCloseOption of
            1:
                EmailAction := Enum::"Email Action"::"Saved As Draft";
            2:
                begin
                    EmailEditor.DiscardEmail(Rec, false);
                    EmailAction := Enum::"Email Action"::Discarded;
                end;
            else
                exit(false) // Cancel
        end;

        exit(true);
    end;

    internal procedure GetAction(): Enum "Email Action"
    begin
        exit(EmailAction);
    end;

    internal procedure SetAsNew()
    begin
        IsNewOutbox := true;
    end;

    var
        TempEmailAccount: Record "Email Account" temporary;
        EmailMessage: Codeunit "Email Message Impl.";
        EmailEditor: Codeunit "Email Editor";
        EmailAction: Enum "Email Action";
        FromDisplayName: Text;
        ToRecipient, CcRecipient, BccRecipient : Text;
        EmailScheduled: Boolean;
        IsNewOutbox: Boolean;
        EmailBody, EmailSubject : Text;
        [InDataSet]
        IsHTMLFormatted: Boolean;
        FromDisplayNameLbl: Label '%1 (%2)', Comment = '%1 - Account Name, %2 - Email address', Locked = true;
        CloseThePageQst: Label 'The email has not been sent.';
        OptionsOnClosePageNewEmailLbl: Label 'Keep as draft in Email Outbox,Discard email';
        PageCaptionTxt: Label 'Compose an Email';
}
