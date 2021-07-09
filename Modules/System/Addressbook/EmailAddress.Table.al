table 8944 "Email Address"
{
    Access = Public;
    DataClassification = ToBeClassified;
    TableType = Temporary;

    fields
    {
        field(1; "E-Mail Address"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(2; Name; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(3; Company; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(4; RecipientType; Enum "Email Recipient Type")
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Source Name"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(6; SourceTable; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(7; SourceSystemID; Guid)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "E-Mail Address", "Source Name")
        {
            Clustered = true;
        }
    }

}