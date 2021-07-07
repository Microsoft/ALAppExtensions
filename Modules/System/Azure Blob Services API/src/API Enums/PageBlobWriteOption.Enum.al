// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

enum 9047 "PageBlob Write Option"
{
    Extensible = false;

    value(0; Update)
    {
        Caption = 'update';
    }
    value(1; Clear)
    {
        Caption = 'clear';
    }
}