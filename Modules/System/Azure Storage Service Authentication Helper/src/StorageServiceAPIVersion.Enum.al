// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Defines the available API versions
/// see: https://docs.microsoft.com/en-us/rest/api/storageservices/previous-azure-storage-service-versions
/// </summary>
enum 9060 "Storage Service API Version"
{
    Access = Public;
    Extensible = false;

    value(0; "2017-04-17")
    {
        Caption = '2017-04-17';
    }
    value(1; "2017-07-29")
    {
        Caption = '2017-07-29';
    }
    value(2; "2017-11-09")
    {
        Caption = '2017-11-09';
    }
    value(3; "2018-03-28")
    {
        Caption = '2018-03-28';
    }
    value(4; "2018-11-09")
    {
        Caption = '2018-11-09';
    }
    value(5; "2019-02-02")
    {
        Caption = '2019-02-02';
    }
    value(6; "2019-07-07")
    {
        Caption = '2019-07-07';
    }
    value(7; "2019-12-12")
    {
        Caption = '2019-12-12';
    }
    value(8; "2020-02-10")
    {
        Caption = '2020-02-10';
    }
}