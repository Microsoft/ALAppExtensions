// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

enum 9046 "Lease Action"
{
    Extensible = false;

    value(0; acquire) { }
    value(1; renew) { }
    value(2; change) { }
    value(3; release) { }
    value(4; break) { }
}