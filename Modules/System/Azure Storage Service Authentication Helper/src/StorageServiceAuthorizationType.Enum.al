// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Defines the possible Authorization types
/// see: https://docs.microsoft.com/en-us/rest/api/storageservices/authorize-requests-to-azure-storage
/// </summary>
enum 9061 "Storage Service Authorization Type"
{
    Access = Public;
    Extensible = false;

    value(0; SasToken)
    {
        Caption = 'Shared Access Signature';
    }
    value(1; AccessKey)
    {
        Caption = 'Access Key';
    }

    // TODO: OAuth?
}