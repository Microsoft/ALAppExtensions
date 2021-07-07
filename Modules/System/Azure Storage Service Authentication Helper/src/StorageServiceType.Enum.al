// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Defines the possible service types for account SAS
/// More Information: https://docs.microsoft.com/en-us/rest/api/storageservices/create-account-sas#specifying-account-sas-parameters
/// </summary>
enum 9062 "Storage Service Type"
{
    Access = Public;
    Extensible = false;

    value(0; Blob)
    {
        Caption = 'Blob';
    }
    value(1; Queue)
    {
        Caption = 'Queue';
    }
    value(2; Table)
    {
        Caption = 'Table';
    }
    value(3; File)
    {
        Caption = 'File';
    }
}