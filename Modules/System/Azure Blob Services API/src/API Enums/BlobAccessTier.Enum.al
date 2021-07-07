// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

enum 9042 "Blob Access Tier"
{
    Extensible = false;
    value(0; Hot)
    {
        Caption = 'Hot';
    }
    value(1; Cool)
    {
        Caption = 'Cool';
    }
    value(3; Archive)
    {
        Caption = 'Archive';
    }
}