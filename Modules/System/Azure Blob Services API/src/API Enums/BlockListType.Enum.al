// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

enum 9044 "Block List Type"
{
    Extensible = false;

    value(0; committed)
    {
        Caption = 'committed';
    }
    value(1; uncommitted)
    {
        Caption = 'uncommitted';
    }
    value(2; all)
    {
        Caption = 'all';
    }
}