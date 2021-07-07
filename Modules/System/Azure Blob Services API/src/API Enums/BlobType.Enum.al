// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

enum 9041 "Blob Type"
{
    Extensible = false;

    value(0; BlockBlob)
    {
        Caption = 'BlockBlob';
    }
    value(1; PageBlob)
    {
        Caption = 'PageBlob';
    }
    value(2; AppendBlob)
    {
        Caption = 'AppendBlob';
    }
}