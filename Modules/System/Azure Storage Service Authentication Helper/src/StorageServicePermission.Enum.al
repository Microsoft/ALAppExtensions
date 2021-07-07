// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Defines the possible permissions for account SAS
/// More Information: https://docs.microsoft.com/en-us/rest/api/storageservices/create-account-sas#account-sas-permissions-by-operation
/// </summary>
enum 9064 "Storage Service Permission"
{
    Access = Public;
    Extensible = false;

    value(0; Read) { }
    value(1; Write) { }
    value(2; Delete) { }
    value(3; PermantDelete) { }
    value(4; List) { }
    value(5; Add) { }
    value(6; Create) { }
    value(7; Update) { }
    value(8; Process) { }
    value(9; VersionDeletion) { }
    value(10; BlobIndexReadWrite) { }
    value(11; BlobIndexFilter) { }
}