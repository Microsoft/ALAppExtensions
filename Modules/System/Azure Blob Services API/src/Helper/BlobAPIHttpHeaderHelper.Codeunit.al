// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 9048 "Blob API HttpHeader Helper"
{
    Access = Internal;

    procedure HandleHeaders(HttpRequestType: Enum "Http Request Type"; var Client: HttpClient; var OperationPayload: Codeunit "Blob API Operation Payload")
    var
        FormatHelper: Codeunit "Blob API Format Helper";
        UsedDateTimeText: Text;
        Headers: HttpHeaders;
        HeadersDictionary: Dictionary of [Text, Text];
        HeaderKey: Text;
        AuthType: Enum "Storage Service Authorization Type";
    begin
        Headers := Client.DefaultRequestHeaders;
        // Add to all requests >>
        UsedDateTimeText := FormatHelper.GetRfc1123DateTime();
        OperationPayload.AddHeader('x-ms-date', UsedDateTimeText);
        OperationPayload.AddHeader('x-ms-version', Format(OperationPayload.GetApiVersion()));
        // Add to all requests <<
        HeadersDictionary := OperationPayload.GetSortedHeadersDictionary();
        OperationPayload.SetHeaderValues(HeadersDictionary);
        foreach HeaderKey in HeadersDictionary.Keys do
            if not IsContentHeader(HeaderKey) then
                OperationPayload.AddHeader(Headers, HeaderKey, HeadersDictionary.Get(HeaderKey));
        case OperationPayload.GetAuthorizationType() of
            AuthType::AccessKey:
                OperationPayload.AddHeader(Headers, 'Authorization', OperationPayload.GetSharedKeySignature(HttpRequestType));
        //AuthType::"AAD (Client Credentials)":
        //    OperationPayload.AddHeader(Headers, 'Authorization', OperationPayload.GetAADBearerToken(HttpRequestType));
        end;
    end;

    procedure HandleContentHeaders(var Content: HttpContent; var OperationPayload: Codeunit "Blob API Operation Payload"): Boolean
    var
        Headers: HttpHeaders;
        HeadersDictionary: Dictionary of [Text, Text];
        HeaderKey: Text;
        ContainsContentHeader: Boolean;
    begin
        Content.GetHeaders(Headers);
        HeadersDictionary := OperationPayload.GetSortedHeadersDictionary();
        foreach HeaderKey in HeadersDictionary.Keys do
            if IsContentHeader(HeaderKey) then begin
                OperationPayload.AddHeader(Headers, HeaderKey, HeadersDictionary.Get(HeaderKey));
                ContainsContentHeader := true;
            end;
        exit(ContainsContentHeader);
    end;

    local procedure IsContentHeader(HeaderKey: Text): Boolean
    begin
        if HeaderKey in ['Content-Type', 'Content-Length', 'x-ms-blob-content-length', 'x-ms-blob-type', 'Content-Language', 'x-ms-blob-content-language'] then // TODO: Check if these are all relevant headers
            exit(true);
        exit(false);
    end;
}