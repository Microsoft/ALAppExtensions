page 8945 "Email Address Entity"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Email Address";
    Caption = 'Entities';
    Extensible = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    ShowFilter = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Type"; "Source Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Source Entity Name.';
                }
            }
        }
    }

    internal procedure GetSelectedAddresses(var EmailAddress: Record "Email Address")
    begin
        CurrPage.SetSelectionFilter(Rec);

        if not Rec.FindSet() then
            exit;

        repeat
            EmailAddress.Copy(Rec);
            EmailAddress.Insert();
        until Rec.Next() = 0;
    end;

    internal procedure InsertAddresses(var EmailAddress: Record "Email Address")
    begin
        if EmailAddress.FindSet() then
            repeat
                Rec.Copy(EmailAddress);
                Rec.Insert();
            until EmailAddress.Next() = 0;
    end;
}