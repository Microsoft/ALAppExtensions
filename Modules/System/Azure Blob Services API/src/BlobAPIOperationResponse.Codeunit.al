codeunit 9050 "Blob API Operation Response"
{
    /// <summary>
    /// Sets the HttpResponseMessage for this request
    /// </summary>
    /// <param name="NewResponse">The HttpResponseMessage</param>
    procedure SetHttpResponse(NewResponse: HttpResponseMessage)
    begin
        Response := NewResponse;
        ResponseIsSet := true;
    end;

    procedure GetHttpResponse(): HttpResponseMessage
    var
        ValueNotSetErr: Label 'HttpResponseMessage is not set. Call this function only after you executed the API operation.';
    begin
        if not ResponseIsSet then
            Error(ValueNotSetErr);
        exit(Response);
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns the HttpResponseMessage as Text
    /// </summary>
    /// <returns>The HttpResponseMessage as Text</returns>
    procedure GetHttpResponseAsText(): Text;
    var
        ResponseText: Text;
    begin
        Response.Content.ReadAs(ResponseText);
        exit(ResponseText)
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns the HttpResponseMessage as InStream
    /// </summary>    
    /// <returns>The HttpResponseMessage as InStream</returns>
    procedure GetHttpResponseAsStream() Result: InStream
    begin
        Response.Content.ReadAs(Result);
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns the HttpStatusCode as Integer
    /// </summary>    
    /// <returns>The HttpStatusCode as Integer</returns>
    procedure GetHttpResponseStatusCode(): Integer
    begin
        exit(Response.HttpStatusCode());
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns a Boolean indicating if the request was successful or not
    /// </summary>    
    /// <returns>Boolean indicating if the request was successful or not</returns>
    procedure GetHttpResponseIsSuccessStatusCode(): Boolean
    begin
        exit(Response.IsSuccessStatusCode);
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns the HttpHeaders of the underlying HttpResponseMessage
    /// </summary>    
    /// <returns>The HttpHeaders of the underlying HttpResponseMessage</returns>
    procedure GetHttpResponseHeaders(): HttpHeaders
    begin
        exit(Response.Headers);
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns the value of a specific HttpHeader of the underlying HttpResponseMessage
    /// </summary>    
    /// <returns>Text containing the value of HttpHeader of the underlying HttpResponseMessage. Returns empty string if HttpHeader does not exist</returns>
    procedure GetHeaderValueFromResponseHeaders(HeaderName: Text): Text
    var
        Headers: HttpHeaders;
        Values: array[100] of Text;
    begin
        Headers := GetHttpResponseHeaders();
        if not Headers.GetValues(HeaderName, Values) then
            exit('');
        exit(Values[1]);
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns the value of 'x-ms-sku-name' HttpHeader of the underlying HttpResponseMessage
    /// </summary>    
    /// <returns>Text containing the value of HttpHeader 'x-ms-sku-name' of the underlying HttpResponseMessage. Returns empty string if HttpHeader does not exist</returns>
    procedure GetSkuNameFromResponseHeaders(): Text
    var
        ReturnValue: Text;
    begin
        ReturnValue := GetHeaderValueFromResponseHeaders('x-ms-sku-name');
        exit(ReturnValue);
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns the value of 'x-ms-account-kind' HttpHeader of the underlying HttpResponseMessage
    /// </summary>    
    /// <returns>Text containing the value of HttpHeader 'x-ms-sku-name' of the underlying HttpResponseMessage. Returns empty string if HttpHeader does not exist</returns>
    procedure GetAccountKindFromResponseHeaders(): Text
    var
        ReturnValue: Text;
    begin
        ReturnValue := GetHeaderValueFromResponseHeaders('x-ms-account-kind');
        exit(ReturnValue);
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns the value of 'x-ms-copy-id' HttpHeader of the underlying HttpResponseMessage
    /// </summary>    
    /// <returns>Text containing the value of HttpHeader 'x-ms-copy-id' of the underlying HttpResponseMessage. Returns empty string if HttpHeader does not exist</returns>
    procedure GetCopyIdFromResponseHeaders(): Text
    var
        ReturnValue: Text;
    begin
        ReturnValue := GetHeaderValueFromResponseHeaders('x-ms-copy-id');
        exit(ReturnValue);
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns the value of 'x-ms-snapshot' HttpHeader of the underlying HttpResponseMessage
    /// </summary>    
    /// <returns>Text containing the value of HttpHeader 'x-ms-snapshot' of the underlying HttpResponseMessage. Returns empty string if HttpHeader does not exist</returns>
    procedure GetSnapshotFromResponseHeaders(): Text
    var
        ReturnValue: Text;
    begin
        ReturnValue := GetHeaderValueFromResponseHeaders('x-ms-snapshot');
        exit(ReturnValue);
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns the value of 'x-ms-lease-state' HttpHeader of the underlying HttpResponseMessage
    /// </summary>    
    /// <returns>Text containing the value of HttpHeader 'x-ms-lease-state' of the underlying HttpResponseMessage. Returns empty string if HttpHeader does not exist</returns>
    procedure GetLeaseStateFromResponseHeaders(var OperationPayload: Codeunit "Blob API Operation Payload"): Text
    var
        ReturnValue: Text;
    begin
        ReturnValue := GetHeaderValueFromResponseHeaders('x-ms-lease-state');
        exit(ReturnValue);
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns the value of 'x-ms-lease-id' HttpHeader of the underlying HttpResponseMessage
    /// </summary>    
    /// <returns>Guid containing the value of HttpHeader 'x-ms-lease-id' of the underlying HttpResponseMessage. Returns empty string if HttpHeader does not exist</returns>
    procedure GetLeaseIdFromResponseHeaders(): Guid
    var
        ReturnValue: Text;
        ReturnGuid: Guid;
    begin
        ReturnValue := GetHeaderValueFromResponseHeaders('x-ms-lease-id');
        Evaluate(ReturnGuid, ReturnValue);
        exit(ReturnGuid);
    end;

    /// <summary>
    /// Can be called after an API operation was executed. Returns the value of 'x-ms-meta-[MetaName]' HttpHeader of the underlying HttpResponseMessage
    /// </summary>    
    /// <param name="MetaName">The name of the Metadata-value.</param>
    /// <returns>Text containing the value of HttpHeader 'x-ms-meta-[MetaName]' of the underlying HttpResponseMessage. Returns empty string if HttpHeader does not exist</returns>
    procedure GetMetaValueFromResponseHeaders(MetaName: Text): Text
    var
        ReturnValue: Text;
        MetaKeyValuePairLbl: Label 'x-ms-meta-%1', Comment = '%1 = Key';
    begin
        ReturnValue := GetHeaderValueFromResponseHeaders(StrSubstNo(MetaKeyValuePairLbl, MetaName));
        exit(ReturnValue);
    end;

    procedure GetUserDelegationKeyFromResponse(): Text
    var
        ResponseDocument: XmlDocument;
        ValueNode: XmlNode;
    begin
        XmlDocument.ReadFrom(GetHttpResponseAsText(), ResponseDocument);
        ResponseDocument.SelectSingleNode('.//Value', ValueNode);
        exit(ValueNode.AsXmlElement().InnerText);
    end;

    var
        ResponseIsSet: Boolean;
        Response: HttpResponseMessage;
}