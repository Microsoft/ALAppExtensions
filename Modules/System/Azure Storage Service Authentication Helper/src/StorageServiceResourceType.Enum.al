// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Defines the possible resource types for account SAS
/// More Information: https://docs.microsoft.com/en-us/rest/api/storageservices/create-account-sas#specifying-account-sas-parameters
/// </summary>
enum 9063 "Storage Service Resource Type"
{
    Access = Public;
    Extensible = false;

    value(0; Service)
    {
        Caption = 'Service';
    }
    value(1; Container)
    {
        Caption = 'Container';
    }
    value(2; Object)
    {
        Caption = 'Object';
    }
}