// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// This enum contains the REST Http Request types.
/// </summary>
enum 1289 "Http Request Type"
{
    Extensible = true;

    /// <summary>
    /// Specifies that the Http request type is GET.
    /// </summary>
    value(0; GET)
    {
        Caption = 'GET', Locked = true;
    }

    /// <summary>
    /// Specifies that the Http request type is POST.
    /// </summary>
    value(1; POST)
    {
        Caption = 'POST', Locked = true;
    }

    /// <summary>
    /// Specifies that the Http request type is PATCH.
    /// </summary>
    value(2; PATCH)
    {
        Caption = 'PATCH', Locked = true;
    }

    /// <summary>
    /// Specifies that the Http request type is PUT.
    /// </summary>
    value(3; PUT)
    {
        Caption = 'PUT', Locked = true;
    }

    /// <summary>
    /// Specifies that the Http request type is DELETE.
    /// </summary>
    value(4; DELETE)
    {
        Caption = 'DELETE', Locked = true;
    }

    /// <summary>
    /// Specifies that the Http request type is HEAD.
    /// </summary>
    value(5; HEAD)
    {
        Caption = 'HEAD', Locked = true;;
    }

    /// <summary>
    /// Specifies that the Http request type is OPTIONS.
    /// </summary>
    value(6; OPTIONS)
    {
        Caption = 'OPTIONS', Locked = true;;
    }
}