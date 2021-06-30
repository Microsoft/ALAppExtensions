// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

enum 1285 "RSA Signature Padding"
{
    Extensible = false;

    value(0; Pkcs1)
    {
        Caption = 'Pkcs1';
    }
    value(1; Pss)
    {
        Caption = 'Pss';
    }
}