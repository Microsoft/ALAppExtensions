// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 9049 "Blob API HttpContent Helper"
{
    Access = Internal;

    var
        ContentLengthLbl: Label '%1', Comment = '%1 = Length';

    procedure AddBlobPutBlockBlobContentHeaders(var Content: HttpContent; OperationPayload: Codeunit "Blob API Operation Payload"; var SourceStream: InStream)
    var
        BlobType: Enum "Blob Type";
    begin
        AddBlobPutContentHeaders(Content, OperationPayload, SourceStream, BlobType::BlockBlob)
    end;

    procedure AddBlobPutBlockBlobContentHeaders(var Content: HttpContent; OperationPayload: Codeunit "Blob API Operation Payload"; SourceText: Text)
    var
        BlobType: Enum "Blob Type";
    begin
        AddBlobPutContentHeaders(Content, OperationPayload, SourceText, BlobType::BlockBlob)
    end;

    procedure AddBlobPutPageBlobContentHeaders(OperationPayload: Codeunit "Blob API Operation Payload"; ContentLength: Integer; ContentType: Text)
    var
        BlobType: Enum "Blob Type";
        Content: HttpContent;
    begin
        if ContentLength = 0 then
            ContentLength := 512;
        AddBlobPutContentHeaders(Content, OperationPayload, BlobType::PageBlob, ContentLength, ContentType)
    end;

    procedure AddBlobPutAppendBlobContentHeaders(OperationPayload: Codeunit "Blob API Operation Payload"; ContentType: Text)
    var
        BlobType: Enum "Blob Type";
        Content: HttpContent;
    begin
        AddBlobPutContentHeaders(Content, OperationPayload, BlobType::AppendBlob, 0, ContentType)
    end;

    local procedure AddBlobPutContentHeaders(var Content: HttpContent; OperationPayload: Codeunit "Blob API Operation Payload"; var SourceStream: InStream; BlobType: Enum "Blob Type")
    var
        Length: Integer;
    begin
        // Do this before calling "GetContentLength", because for some reason the system errors out with "Cannot access a closed Stream."
        Content.WriteFrom(SourceStream);

        Length := GetContentLength(SourceStream);

        AddBlobPutContentHeaders(Content, OperationPayload, BlobType, Length, 'application/octet-stream');
    end;

    local procedure AddBlobPutContentHeaders(var Content: HttpContent; OperationPayload: Codeunit "Blob API Operation Payload"; SourceText: Text; BlobType: Enum "Blob Type")
    var
        Length: Integer;
    begin
        Content.WriteFrom(SourceText);

        Length := GetContentLength(SourceText);

        AddBlobPutContentHeaders(Content, OperationPayload, BlobType, Length, 'text/plain; charset=UTF-8');
    end;

    local procedure AddBlobPutContentHeaders(var Content: HttpContent; OperationPayload: Codeunit "Blob API Operation Payload"; BlobType: Enum "Blob Type"; ContentLength: Integer; ContentType: Text)
    var
        Headers: HttpHeaders;
        BlobServiceAPIOperation: Enum "Blob Service API Operation";
    begin
        if ContentType = '' then
            ContentType := 'application/octet-stream';
        Content.GetHeaders(Headers);
        if not (OperationPayload.GetOperation() in [BlobServiceAPIOperation::PutPage]) then
            OperationPayload.AddHeader(Headers, 'Content-Type', ContentType);
        case BlobType of
            BlobType::PageBlob:
                begin
                    OperationPayload.AddHeader(Headers, 'x-ms-blob-content-length', StrSubstNo(ContentLengthLbl, ContentLength));
                    OperationPayload.AddHeader(Headers, 'Content-Length', StrSubstNo(ContentLengthLbl, 0));
                end;
            else
                OperationPayload.AddHeader(Headers, 'Content-Length', StrSubstNo(ContentLengthLbl, ContentLength));
        end;
        if not (OperationPayload.GetOperation() in [BlobServiceAPIOperation::PutBlock, BlobServiceAPIOperation::PutPage, BlobServiceAPIOperation::AppendBlock]) then
            OperationPayload.AddHeader(Headers, 'x-ms-blob-type', Format(BlobType));
    end;

    procedure AddServicePropertiesContent(var Content: HttpContent; var OperationPayload: Codeunit "Blob API Operation Payload"; Document: XmlDocument)
    begin
        AddXmlDocumentAsContent(Content, OperationPayload, Document);
    end;

    procedure AddContainerAclDefinition(var Content: HttpContent; var OperationPayload: Codeunit "Blob API Operation Payload"; Document: XmlDocument)
    begin
        AddXmlDocumentAsContent(Content, OperationPayload, Document);
    end;

    procedure AddTagsContent(var Content: HttpContent; var OperationPayload: Codeunit "Blob API Operation Payload"; Document: XmlDocument)
    begin
        AddXmlDocumentAsContent(Content, OperationPayload, Document);
    end;

    procedure AddBlockListContent(var Content: HttpContent; var OperationPayload: Codeunit "Blob API Operation Payload"; Document: XmlDocument)
    begin
        AddXmlDocumentAsContent(Content, OperationPayload, Document);
    end;

    procedure AddUserDelegationRequestContent(var Content: HttpContent; var OperationPayload: Codeunit "Blob API Operation Payload"; Document: XmlDocument)
    begin
        AddXmlDocumentAsContent(Content, OperationPayload, Document);
    end;

    procedure AddQueryBlobContentRequestContent(var Content: HttpContent; var OperationPayload: Codeunit "Blob API Operation Payload"; Document: XmlDocument)
    begin
        AddXmlDocumentAsContent(Content, OperationPayload, Document);
    end;

    local procedure AddXmlDocumentAsContent(var Content: HttpContent; var OperationPayload: Codeunit "Blob API Operation Payload"; Document: XmlDocument)
    var
        Headers: HttpHeaders;
        Length: Integer;
        DocumentAsText: Text;
    begin
        DocumentAsText := Format(Document);
        Length := StrLen(DocumentAsText);

        Content.WriteFrom(DocumentAsText);

        Content.GetHeaders(Headers);
        OperationPayload.AddHeader(Headers, 'Content-Type', 'application/xml');
        OperationPayload.AddHeader(Headers, 'Content-Length', Format(Length));
    end;

    procedure ContentSet(Content: HttpContent): Boolean
    var
        VarContent: Text;
    begin
        Content.ReadAs(VarContent);
        if StrLen(VarContent) > 0 then
            exit(true);

        exit(VarContent <> '');
    end;

    /// <summary>
    /// Retrieves the length of the given stream (used for "Content-Length" header in PUT-operations)
    /// </summary>
    /// <param name="SourceStream">The InStream for Request Body.</param>
    /// <returns>The length of the current stream</returns>
    local procedure GetContentLength(var SourceStream: InStream): Integer
    var
        MemoryStream: DotNet MemoryStream;
        Length: Integer;
    begin
        // Load the memory stream and get the size
        MemoryStream := MemoryStream.MemoryStream();
        CopyStream(MemoryStream, SourceStream);
        Length := MemoryStream.Length();
        Clear(SourceStream);
        exit(Length);
    end;

    /// <summary>
    /// Retrieves the length of the given stream (used for "Content-Length" header in PUT-operations)
    /// </summary>
    /// <param name="SourceText">The Text for Request Body.</param>
    /// <returns>The length of the current stream</returns>
    local procedure GetContentLength(SourceText: Text): Integer
    var
        Length: Integer;
    begin
        Length := StrLen(SourceText);
        exit(Length);
    end;
}