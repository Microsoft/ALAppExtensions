// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

table 4509 "Email - Outlook API Setup"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; ClientId; guid)
        {
            Caption = 'Client Id';
            DataClassification = CustomerContent;
        }
        field(3; ClientSecret; guid)
        {
            Caption = 'Client Secret';
            DataClassification = CustomerContent;
        }
        field(4; RedirectURL; Text[1024])
        {
            Caption = 'Redirect URL';
            DataClassification = CustomerContent;
        }
        field(5; TenantID; Text[36])
        {
            Caption = 'TenantID';
            DataClassification = CustomerContent;
            InitValue = 'Common';
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}
