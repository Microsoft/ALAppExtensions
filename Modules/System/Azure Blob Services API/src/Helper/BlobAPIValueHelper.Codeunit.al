// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Exposes helper functionality to set values on or retrieve values from "Blob API Operation Object" 
/// </summary>
codeunit 9047 "Blob API Value Helper"
{
    Access = Public;

    var
        BlobAPIFormatHelper: Codeunit "Blob API Format Helper";
        NeedToSpecifyHeaderErr: Label 'You need to specify the "%1"-Header to use this function.', Comment = '%1 = Header Name';
        InvalidCombinationErr: Label 'Invalid combination: "%1" can only be set if "%2" is "%3"', Comment = '%1 = Header Name, %2 = Lease Action Header Name, %3 = Lease Action';
        InvalidCombinationTwoValuesErr: Label 'Invalid combination: "%1" can only be set if "%2" is "%3" or "%4"', Comment = '%1 = Header Name, %2 = Lease Action Header Name, %3 = Lease Action, %4 = Lease Action 2';


    procedure GetLeaseActionFromOptionalHeaders(var OperationPayload: Codeunit "Blob API Operation Payload"): Enum "Lease Action"
    var
        LeaseActionAsText: Text;
        LeaseAction: Enum "Lease Action";
    begin
        if not OperationPayload.GetOptionalHeaderValue('x-ms-lease-action', LeaseActionAsText) then
            Error(NeedToSpecifyHeaderErr, 'x-ms-lease-action');
        Evaluate(LeaseAction, LeaseActionAsText);
        exit(LeaseAction);
    end;

    /// <summary>
    /// Sets the value for 'x-ms-lease-id' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Guid value specifying the LeaseID</param>
    procedure SetLeaseIdHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Guid)
    var
        GuidAsText: Text;
    begin
        GuidAsText := BlobAPIFormatHelper.RemoveCurlyBracketsFromString(Format("Value").ToLower());
        OperationPayload.AddOptionalHeader('x-ms-lease-id', GuidAsText);
    end;

    /// <summary>
    /// Sets the value for 'x-ms-source-lease-id' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Guid value specifying the source LeaseID</param>
    procedure SetSourceLeaseIdHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Guid)
    var
        GuidAsText: Text;
    begin
        GuidAsText := BlobAPIFormatHelper.RemoveCurlyBracketsFromString(Format("Value").ToLower());
        SetSourceLeaseIdHeader(OperationPayload, GuidAsText);
    end;

    /// <summary>
    /// Sets the value for 'x-ms-source-lease-id' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Text value specifying the source LeaseID</param>
    procedure SetSourceLeaseIdHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    begin
        OperationPayload.AddOptionalHeader('x-ms-source-lease-id', "Value");
    end;

    /// <summary>
    /// Sets the value for 'x-ms-lease-action' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Text value specifying the lease action</param>
    procedure SetLeaseActionHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Enum "Lease Action")
    begin
        OperationPayload.AddOptionalHeader('x-ms-lease-action', Format("Value"));
    end;

    /// <summary>
    /// Sets the value for 'x-ms-lease-break-period' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Integer value specifying the duration in seconds before a break operation is actually executed</param>
    procedure SetLeaseBreakPeriodHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Integer)
    var
        LeaseAction: Enum "Lease Action";
    begin
        LeaseAction := GetLeaseActionFromOptionalHeaders(OperationPayload);
        if LeaseAction <> LeaseAction::break then
            Error(InvalidCombinationErr, 'x-ms-lease-break-period', 'x-ms-lease-action', 'break');
        OperationPayload.AddOptionalHeader('x-ms-lease-break-period', Format("Value"));
    end;

    /// <summary>
    /// Sets the value for 'x-ms-lease-duration' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Integer value specifying the duration in seconds of a lease. Can be -1 (infinite) or between 15 and 60 seconds.</param>
    procedure SetLeaseDurationHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Integer)
    var
        LeaseAction: Enum "Lease Action";
    begin
        LeaseAction := GetLeaseActionFromOptionalHeaders(OperationPayload);
        if LeaseAction <> LeaseAction::acquire then
            Error(InvalidCombinationErr, 'x-ms-lease-duration', 'x-ms-lease-action', 'acquire');
        OperationPayload.AddOptionalHeader('x-ms-lease-duration', Format("Value"));
    end;

    /// <summary>
    /// Sets the value for 'x-ms-proposed-lease-id' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Guid value specifying proposed LeaseId</param>
    procedure SetProposedLeaseIdHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Guid)
    var
        GuidAsText: Text;
    begin
        GuidAsText := BlobAPIFormatHelper.RemoveCurlyBracketsFromString(Format("Value").ToLower());
        SetProposedLeaseIdHeader(OperationPayload, GuidAsText);
    end;

    /// <summary>
    /// Sets the value for 'x-ms-proposed-lease-id' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Text value specifying proposed LeaseId</param>
    procedure SetProposedLeaseIdHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    var
        LeaseAction: Enum "Lease Action";
    begin
        LeaseAction := GetLeaseActionFromOptionalHeaders(OperationPayload);
        if LeaseAction in [LeaseAction::acquire, LeaseAction::change] then
            Error(InvalidCombinationTwoValuesErr, 'x-ms-lease-break-period', 'x-ms-lease-action', 'acquire', 'change');
        OperationPayload.AddOptionalHeader('x-ms-proposed-lease-id', "Value");
    end;

    /// <summary>
    /// Sets the value for 'Origin' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetOriginHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    begin
        OperationPayload.AddOptionalHeader('Origin', "Value");
    end;

    /// <summary>
    /// Sets the value for 'Access-Control-Request-Method' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetAccessControlRequestMethodHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Enum "Http Request Type")
    begin
        OperationPayload.AddOptionalHeader('Access-Control-Request-Method', Format("Value"));
    end;

    /// <summary>
    /// Sets the value for 'Access-Control-Request-Headers' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetAccessControlRequestHeadersHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    begin
        OperationPayload.AddOptionalHeader('Access-Control-Request-Headers', "Value");
    end;

    /// <summary>
    /// Sets the value for 'x-ms-client-request-id' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetClientRequestIdHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    begin
        OperationPayload.AddOptionalHeader('x-ms-client-request-id', "Value");
    end;

    /// <summary>
    /// Sets the value for 'x-ms-blob-public-access' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Enum "Blob Public Access" value specifying the HttpHeader value</param>
    procedure SetBlobPublicAccessHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Enum "Blob Public Access")
    begin
        OperationPayload.AddOptionalHeader('x-ms-blob-public-access', Format("Value"));
    end;

    /// <summary>
    /// Sets the value for 'x-ms-meta-[MetaName]' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="MetaName">The name of the Metadata-value.</param>
    /// <param name="Value">Text value specifying the Metadata value</param>
    procedure SetMetadataNameValueHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; MetaName: Text; "Value": Text)
    var
        MetaKeyValuePairLbl: Label 'x-ms-meta-%1', Comment = '%1 = Key';
    begin
        OperationPayload.AddOptionalHeader(StrSubstNo(MetaKeyValuePairLbl, MetaName), "Value");
    end;

    /// <summary>
    /// Sets the value for 'x-ms-tags' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetTagsValueHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    begin
        OperationPayload.AddOptionalHeader('x-ms-tags', "Value"); // Supported in version 2019-12-12 and newer.
    end;

    /// <summary>
    /// Sets the value for 'x-ms-source-if-modified-since' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">DateTime value specifying the HttpHeader value</param>
    procedure SetSourceIfModifiedSinceHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": DateTime)
    begin
        OperationPayload.AddOptionalHeader('x-ms-source-if-modified-since', Format("Value")); // TODO: Check DateTime-format for URI
    end;

    /// <summary>
    /// Sets the value for 'x-ms-source-if-unmodified-since' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">DateTime value specifying the HttpHeader value</param>
    procedure SetSourceIfUnmodifiedSinceHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": DateTime)
    begin
        OperationPayload.AddOptionalHeader('x-ms-source-if-unmodified-since', Format("Value")); // TODO: Check DateTime-format for URI
    end;

    /// <summary>
    /// Sets the value for 'x-ms-source-if-match' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetSourceIfMatchHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    begin
        OperationPayload.AddOptionalHeader('x-ms-source-if-match', "Value");
    end;

    /// <summary>
    /// Sets the value for 'x-ms-source-if-none-match' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetSourceIfNoneMatchHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    begin
        OperationPayload.AddOptionalHeader('x-ms-source-if-none-match', "Value");
    end;

    /// <summary>
    /// Sets the value for 'x-ms-copy-source' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetCopySourceNameHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    begin
        OperationPayload.AddOptionalHeader('x-ms-copy-source', "Value");
    end;

    /// <summary>
    /// Sets the value for 'x-ms-access-tier' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Enum "Blob Access Tier" value specifying the HttpHeader value</param>
    procedure SetAccessTierHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Enum "Blob Access Tier")
    begin
        OperationPayload.AddOptionalHeader('x-ms-access-tier', Format("Value"));
    end;

    /// <summary>
    /// Sets the value for 'x-ms-rehydrate-priority' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Enum "Rehydrate Priority" value specifying the HttpHeader value</param>
    procedure SetRehydratePriorityHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Enum "Rehydrate Priority")
    begin
        OperationPayload.AddOptionalHeader('x-ms-rehydrate-priority', Format("Value"));
    end;

    /// <summary>
    /// Sets the value for 'x-ms-copy-action' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Enum "Copy Action" value specifying the HttpHeader value</param>
    procedure SetCopyActionHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Enum "Copy Action")
    begin
        OperationPayload.AddOptionalHeader('x-ms-copy-action', Format("Value")); // Valid value is 'abort'
    end;

    /// <summary>
    /// Sets the value for 'x-ms-expiry-option' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Enum "Blob Expiry Option" value specifying the HttpHeader value</param>
    procedure SetBlobExpiryOptionHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Enum "Blob Expiry Option")
    begin
        OperationPayload.AddOptionalHeader('x-ms-expiry-option', Format("Value")); // Valid values are RelativeToCreation/RelativeToNow/Absolute/NeverExpire
    end;

    /// <summary>
    /// Sets the value for 'x-ms-expiry-time' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Integer value specifying the HttpHeader value</param>
    procedure SetBlobExpiryTimeHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Integer)
    begin
        OperationPayload.AddOptionalHeader('x-ms-expiry-time', Format("Value")); // Either an RFC 1123 datetime or miliseconds-value
    end;

    /// <summary>
    /// Sets the value for 'x-ms-expiry-time' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">DateTime value specifying the HttpHeader value</param>
    procedure SetBlobExpiryTimeHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": DateTime)
    begin
        OperationPayload.AddOptionalHeader('x-ms-expiry-time', BlobAPIFormatHelper.GetRfc1123DateTime(("Value"))); // Either an RFC 1123 datetime or miliseconds-value
    end;

    /// <summary>
    /// Sets the value for 'x-ms-access-tier' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Enum "Blob Access Tier" value specifying the HttpHeader value</param>
    procedure SetBlobAccessTierHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Enum "Blob Access Tier")
    begin
        OperationPayload.AddOptionalHeader('x-ms-access-tier', Format("Value"));
    end;

    /// <summary>
    /// Sets the value for 'x-ms-page-write' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Enum "PageBlob Write Option" value specifying the HttpHeader value</param>
    procedure SetPageWriteOptionHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Enum "PageBlob Write Option")
    begin
        OperationPayload.AddOptionalHeader('x-ms-page-write', Format("Value"));
    end;

    /// <summary>
    /// Sets the value for 'x-ms-range' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="BytesStartValue">Integer value specifying the Bytes start range value</param>
    /// <param name="BytesEndValue">Integer value specifying the Bytes end range value</param>
    procedure SetRangeHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; BytesStartValue: Integer; BytesEndValue: Integer)
    var
        RangeBytesLbl: Label 'bytes=%1-%2', Comment = '%1 = Start Range; %2 = End Range';
    begin
        OperationPayload.AddOptionalHeader('x-ms-range', StrSubstNo(RangeBytesLbl, BytesStartValue, BytesEndValue));
    end;

    /// <summary>
    /// Sets the value for 'x-ms-source-range' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="BytesStartValue">Integer value specifying the Bytes start range value</param>
    /// <param name="BytesEndValue">Integer value specifying the Bytes end range value</param>
    procedure SetSourceRangeHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; BytesStartValue: Integer; BytesEndValue: Integer)
    var
        RangeBytesLbl: Label 'bytes=%1-%2', Comment = '%1 = Start Range; %2 = End Range';
    begin
        OperationPayload.AddOptionalHeader('x-ms-source-range', StrSubstNo(RangeBytesLbl, BytesStartValue, BytesEndValue));
    end;

    /// <summary>
    /// Sets the value for 'x-ms-requires-sync' HttpHeader for a request.
    /// </summary>
    /// <param name="OperationPayload">An object containing the parameters for the request.</param>
    /// <param name="Value">Boolean value specifying the HttpHeader value</param>
    procedure SetRequiresSyncHeader(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Boolean)
    var
        ValueText: Text;
    begin
        // Set as text, because otherwise it might give different formatted values based on language locale
        if "Value" = true then
            ValueText := 'true'
        else
            ValueText := 'false';
        OperationPayload.AddOptionalHeader('x-ms-requires-sync', ValueText);
    end;

    // #region Optional Uri Parameters
    /// <summary>
    /// Sets the optional timeout value for the Request
    /// </summary>
    /// <param name="Value">Timeout in seconds. Most operations have a max. limit of 30 seconds. For more Information see: https://docs.microsoft.com/en-us/rest/api/storageservices/setting-timeouts-for-blob-service-operations</param>
    procedure SetTimeoutParameterParameter(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Integer)
    begin
        OperationPayload.AddOptionalUriParameter('timeout', Format("Value"));
    end;

    /// <summary>
    /// The versionid parameter is an opaque DateTime value that, when present, specifies the Version of the blob to retrieve.
    /// </summary>
    /// <param name="Value">The DateTime identifying the Version</param>
    procedure SetVersionIdParameter(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": DateTime)
    var
        HelperLibrary: Codeunit "Blob API Helper Library";
        ApiVersion: Enum "Storage Service API Version";
        IncompatibleVersionsErr: Label 'Parameter "%1" is only available after API Version %2, but you selected %3.', Comment = '%1 = Parameter Name; %2 = Target API Version; %3 = Curr. API Version';
    begin
        // Only allowed for API-Version 2019-12-12 and newer
        HelperLibrary.ValidateApiVersion(OperationPayload.GetApiVersion(), ApiVersion::"2019-12-12", true, StrSubstNo(IncompatibleVersionsErr, 'VersionId', OperationPayload.GetApiVersion(), ApiVersion::"2019-12-12"));
        OperationPayload.AddOptionalUriParameter('versionid', Format("Value")); // TODO: Check DateTime-format for URI
    end;

    /// <summary>
    /// The snapshot parameter is an opaque DateTime value that, when present, specifies the blob snapshot to retrieve. 
    /// </summary>
    /// <param name="Value">The DateTime identifying the Snapshot</param>
    procedure SetSnapshotParameter(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": DateTime)
    begin
        OperationPayload.AddOptionalUriParameter('snapshot', Format("Value")); // TODO: Check DateTime-format for URI
    end;

    /// <summary>
    /// The snapshot parameter is an opaque DateTime value that, when present, specifies the blob snapshot to retrieve. 
    /// </summary>
    /// <param name="Value">The DateTime identifying the Snapshot</param>
    procedure SetSnapshotParameter(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    begin
        OperationPayload.AddOptionalUriParameter('snapshot', "Value");
    end;

    /// <summary>
    /// Filters the results to return only blobs whose names begin with the specified prefix.
    /// </summary>
    /// <param name="Value">Prefix to search for</param>
    procedure SetPrefixParameter(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    begin
        OperationPayload.AddOptionalUriParameter('prefix', "Value");
    end;

    /// <summary>
    /// When the request includes this parameter, the operation returns a BlobPrefix element in the response body 
    /// that acts as a placeholder for all blobs whose names begin with the same substring up to the appearance of the delimiter character. 
    /// The delimiter may be a single character or a string.
    /// </summary>
    /// <param name="Value">Delimiting character/string</param>
    procedure SetDelimiterParameter(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    begin
        OperationPayload.AddOptionalUriParameter('delimiter', "Value");
    end;

    /// <summary>
    /// Specifies the maximum number of blobs to return
    /// </summary>
    /// <param name="Value">Max. number of results to return. Must be positive, must not be greater than 5000</param>
    procedure SetMaxResultsParameterParameter(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Integer)
    begin
        OperationPayload.AddOptionalUriParameter('maxresults', Format("Value"));
    end;

    /// <summary>
    /// Identifiers the ID of a Block in BlockBlob
    /// </summary>
    /// <param name="Value">A valid Base64 string value that identifies the block. Prior to encoding, the string must be less than or equal to 64 bytes in size</param>
    procedure SetBlockIdParameter(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Text)
    begin
        OperationPayload.AddOptionalUriParameter('blockid', "Value");
    end;

    /// <summary>
    /// Specifies whether to return the list of committed blocks, the list of uncommitted blocks, or both lists together.
    /// </summary>
    /// <param name="Value">Valid values are committed, uncommitted, or all</param>
    procedure SetBlockListTypeParameter(var OperationPayload: Codeunit "Blob API Operation Payload"; "Value": Enum "Block List Type")
    begin
        OperationPayload.AddOptionalUriParameter('blocklisttype', Format("Value"));
    end;
    // #endregion Optional Uri Parameters

    /// <summary>
    /// Creates a new Guid value and returns it after applying necessary format/URL-encoding so it can be used as BlockId for BlockBlobs
    /// </summary>
    /// <returns>Formatted unique value for BlockId</returns>
    procedure GetBase64BlockId(): Text
    begin
        exit(GetBase64BlockId(BlobAPIFormatHelper.RemoveCurlyBracketsFromString(Format(CreateGuid()))));
    end;

    /// <summary>
    /// Applys necessary format/URL-encoding to a given BlockId (Text) so it can be used as BlockId for BlockBlobs
    /// </summary>
    /// <param name="BlockId">BlockId as Text</param>
    /// <returns>Formatted unique value for BlockId</returns>
    procedure GetBase64BlockId(BlockId: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        Uri: Codeunit Uri;
    begin
        exit(Uri.EscapeDataString(Base64Convert.ToBase64(BlockId)));
    end;
}