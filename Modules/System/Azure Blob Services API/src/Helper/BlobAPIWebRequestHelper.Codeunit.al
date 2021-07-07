// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 9045 "Blob API Web Request Helper"
{
    Access = Internal;

    var
        ReadResponseFailedErr: Label 'Could not read response.';
        HttpResponseInfoErr: Label '%1.\\Response Code: %2 %3', Comment = '%1 = Default Error Message ; %2 = Status Code; %3 = Reason Phrase';

    // #region GET-Request
    procedure GetOperationAsText(var OperationPayload: Codeunit "Blob API Operation Payload"; var ResponseText: Text; OperationNotSuccessfulErr: Text): Codeunit "Blob API Operation Response"
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        Response: HttpResponseMessage;
    begin
        OperationResponse := GetOperation(OperationPayload, OperationNotSuccessfulErr);

        Response := OperationResponse.GetHttpResponse();

        if not Response.Content.ReadAs(ResponseText) then
            Error(ReadResponseFailedErr);
        exit(OperationResponse);
    end;

    procedure GetOperationAsStream(var OperationPayload: Codeunit "Blob API Operation Payload"; var Stream: InStream; OperationNotSuccessfulErr: Text): Codeunit "Blob API Operation Response"
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        Response: HttpResponseMessage;
    begin
        OperationResponse := GetOperation(OperationPayload, OperationNotSuccessfulErr);

        Response := OperationResponse.GetHttpResponse();

        if not Response.Content.ReadAs(Stream) then
            Error(ReadResponseFailedErr);
        exit(OperationResponse);
    end;

    local procedure GetOperation(var OperationPayload: Codeunit "Blob API Operation Payload"; OperationNotSuccessfulErr: Text): Codeunit "Blob API Operation Response"
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        Client: HttpClient;
        RequestMsg: HttpRequestMessage;
    begin
        HandleHeaders(Enum::"Http Request Type"::GET, Client, OperationPayload);

        RequestMsg := PrepareRequestMsg(OperationPayload, Enum::"Http Request Type"::GET);

        OperationResponse := SendRequest(Client, RequestMsg, OperationNotSuccessfulErr);
        exit(OperationResponse);
    end;
    // #endregion GET-Request

    // #region HEAD-Request
    procedure HeadOperation(var OperationPayload: Codeunit "Blob API Operation Payload"; OperationNotSuccessfulErr: Text): Codeunit "Blob API Operation Response"
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        Client: HttpClient;
        RequestMsg: HttpRequestMessage;
    begin
        HandleHeaders(Enum::"Http Request Type"::HEAD, Client, OperationPayload);

        RequestMsg := PrepareRequestMsg(OperationPayload, Enum::"Http Request Type"::HEAD);

        OperationResponse := SendRequest(Client, RequestMsg, OperationNotSuccessfulErr);
        exit(OperationResponse);
    end;
    // #endregion HEAD-Request

    // #region PUT-Request
    procedure PutOperation(var OperationPayload: Codeunit "Blob API Operation Payload"; OperationNotSuccessfulErr: Text): Codeunit "Blob API Operation Response"
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        Content: HttpContent;
    begin
        OperationResponse := PutOperation(OperationPayload, Content, OperationNotSuccessfulErr);
        exit(OperationResponse);
    end;

    procedure PutOperation(var OperationPayload: Codeunit "Blob API Operation Payload"; Content: HttpContent; OperationNotSuccessfulErr: Text): Codeunit "Blob API Operation Response"
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        Client: HttpClient;
        RequestMsg: HttpRequestMessage;
    begin
        HandleHeaders(Enum::"Http Request Type"::PUT, Client, OperationPayload);

        RequestMsg := PrepareRequestMsg(OperationPayload, Enum::"Http Request Type"::PUT, Content);

        OperationResponse := SendRequest(Client, RequestMsg, OperationNotSuccessfulErr);
        exit(OperationResponse);
    end;
    // #endregion PUT-Request

    // #region DELETE-Request
    procedure DeleteOperation(var OperationPayload: Codeunit "Blob API Operation Payload"; OperationNotSuccessfulErr: Text): Codeunit "Blob API Operation Response"
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        Client: HttpClient;
        RequestMsg: HttpRequestMessage;
    begin
        HandleHeaders(Enum::"Http Request Type"::DELETE, Client, OperationPayload);

        RequestMsg := PrepareRequestMsg(OperationPayload, Enum::"Http Request Type"::DELETE);

        OperationResponse := SendRequest(Client, RequestMsg, OperationNotSuccessfulErr);
        exit(OperationResponse);
    end;
    // #endregion DELETE-Request

    // #region POST-Request
    procedure PostOperation(var OperationPayload: Codeunit "Blob API Operation Payload"; OperationNotSuccessfulErr: Text): Codeunit "Blob API Operation Response"
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        Content: HttpContent;
    begin
        OperationResponse := PostOperation(OperationPayload, Content, OperationNotSuccessfulErr);
        exit(OperationResponse);
    end;

    procedure PostOperation(var OperationPayload: Codeunit "Blob API Operation Payload"; Content: HttpContent; OperationNotSuccessfulErr: Text): Codeunit "Blob API Operation Response"
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        Client: HttpClient;
        RequestMsg: HttpRequestMessage;
    begin
        HandleHeaders(Enum::"Http Request Type"::POST, Client, OperationPayload);

        RequestMsg := PrepareRequestMsg(OperationPayload, Enum::"Http Request Type"::POST, Content);

        OperationResponse := SendRequest(Client, RequestMsg, OperationNotSuccessfulErr);
        exit(OperationResponse);
    end;
    // #endregion POST-Request

    // #region OPTIONS-Request

    procedure OptionsOperation(var OperationPayload: Codeunit "Blob API Operation Payload"; OperationNotSuccessfulErr: Text): Codeunit "Blob API Operation Response"
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        Client: HttpClient;
        RequestMsg: HttpRequestMessage;
    begin
        HandleHeaders(Enum::"Http Request Type"::OPTIONS, Client, OperationPayload);

        RequestMsg := PrepareRequestMsg(OperationPayload, Enum::"Http Request Type"::OPTIONS);

        OperationResponse := SendRequest(Client, RequestMsg, OperationNotSuccessfulErr);
        exit(OperationResponse);
    end;
    // #endregion OPTIONS-Request

    // #region Helper functions
    local procedure HandleHeaders(HttpRequestType: Enum "Http Request Type"; var Client: HttpClient; var OperationPayload: Codeunit "Blob API Operation Payload")
    var
        BlobAPIHttpHeaderHelper: Codeunit "Blob API HttpHeader Helper";
    begin
        BlobAPIHttpHeaderHelper.HandleHeaders(HttpRequestType, Client, OperationPayload);
    end;

    local procedure PrepareRequestMsg(var OperationPayload: Codeunit "Blob API Operation Payload"; HttpRequestType: Enum "Http Request Type") RequestMsg: HttpRequestMessage
    begin
        // Prepare HttpRequestMessage
        RequestMsg.Method(Format(HttpRequestType));
        RequestMsg.SetRequestUri(OperationPayload.ConstructUri());
    end;

    local procedure PrepareRequestMsg(var OperationPayload: Codeunit "Blob API Operation Payload"; HttpRequestType: Enum "Http Request Type"; Content: HttpContent) RequestMsg: HttpRequestMessage
    var
        BlobAPIHttpContentHelper: Codeunit "Blob API HttpContent Helper";
        BlobAPIHttpHeaderHelper: Codeunit "Blob API HttpHeader Helper";
    begin
        // Prepare HttpRequestMessage
        RequestMsg.Method(Format(HttpRequestType));
        if BlobAPIHttpContentHelper.ContentSet(Content) or BlobAPIHttpHeaderHelper.HandleContentHeaders(Content, OperationPayload) then
            RequestMsg.Content := Content;
        RequestMsg.SetRequestUri(OperationPayload.ConstructUri());
    end;

    local procedure SendRequest(var Client: HttpClient; RequestMsg: HttpRequestMessage; OperationNotSuccessfulErr: Text): Codeunit "Blob API Operation Response"
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        DebugText: Text;
        Response: HttpResponseMessage;
    begin
        // Send Request    
        Client.Send(RequestMsg, Response);
        Response.Content.ReadAs(DebugText);
        if not Response.IsSuccessStatusCode then
            Error(HttpResponseInfoErr, OperationNotSuccessfulErr, Response.HttpStatusCode, Response.ReasonPhrase);
        OperationResponse.SetHttpResponse(Response);
        exit(OperationResponse);
    end;
    // #endregion Helper functions
}