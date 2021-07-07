// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 9042 "Blob API Operation Payload"
{
    Access = Public;

    var
        AuthType: Enum "Storage Service Authorization Type";
        ApiVersion: Enum "Storage Service API Version";
        Secret: Text;
        StorageAccountName: Text;
        ContainerName: Text;
        BlobName: Text;
        Operation: Enum "Blob Service API Operation";
        HeaderValues: Dictionary of [Text, Text];
        OptionalHeaderValues: Dictionary of [Text, Text];
        OptionalUriParameters: Dictionary of [Text, Text];
        Response: HttpResponseMessage;
        ResponseIsSet: Boolean;

    // #region Initialize Requests
    /// <summary>
    /// Initializes the object to be used in an API operation
    /// </summary>
    /// <param name="NewStorageAccountName">The Storage Account to use</param>
    procedure InitializeRequest(NewStorageAccountName: Text)
    begin
        InitializeRequest(NewStorageAccountName, '');
    end;

    /// <summary>
    /// Initializes the object to be used in an API operation
    /// </summary>
    /// <param name="NewStorageAccountName">The Storage Account to use</param>
    /// <param name="NewContainerName">The name of the container in the Storage Account</param>
    procedure InitializeRequest(NewStorageAccountName: Text; NewContainerName: Text)
    begin
        InitializeRequest(NewStorageAccountName, NewContainerName, '');
    end;

    /// <summary>
    /// Initializes the object to be used in an API operation
    /// </summary>
    /// <param name="NewStorageAccountName">The Storage Account to use</param>
    /// <param name="NewContainerName">The name of the container in the Storage Account</param>
    /// <param name="NewBlobName">The Name of the Blob</param>
    procedure InitializeRequest(NewStorageAccountName: Text; NewContainerName: Text; NewBlobName: Text)
    begin
        InitializeRequest(NewStorageAccountName, NewContainerName, NewBlobName, ApiVersion::"2017-04-17");
    end;

    /// <summary>
    /// Initializes the object to be used in an API operation
    /// </summary>
    /// <param name="NewStorageAccountName">The Storage Account to use</param>
    /// <param name="NewContainerName">The name of the container in the Storage Account</param>
    /// <param name="NewBlobName">The Name of the Blob</param>
    /// <param name="NewApiVersion">The used API version</param>
    procedure InitializeRequest(NewStorageAccountName: Text; NewContainerName: Text; NewBlobName: Text; NewApiVersion: Enum "Storage Service API Version")
    begin
        StorageAccountName := NewStorageAccountName;
        ContainerName := NewContainerName;
        BlobName := NewBlobName;
        ApiVersion := NewApiVersion;
    end;
    // #endregion Initialize Requests

    // #region Initialize Authorization
    /// <summary>
    /// Initializes the Authorization method for object to be used in an API operation
    /// </summary>
    /// <param name="NewAuthType">Enum "Storage Service Authorization Type" specifying the authorization type</param>
    /// <param name="NewSecret">The Secret (as Text) to use during authorization (SAS Token or SharedKey)</param>
    procedure InitializeAuthorization(NewAuthType: Enum "Storage Service Authorization Type"; NewSecret: Text)
    begin
        AuthType := NewAuthType;
        Secret := NewSecret;
    end;
    // #endregion Initialize Authorization

    // #region Set/Get Globals
    /// <summary>
    /// Sets the Storage Account name for this request
    /// </summary>
    /// <param name="NewStorageAccountName">The Storage Account name</param>
    procedure SetStorageAccountName(NewStorageAccountName: Text)
    begin
        StorageAccountName := NewStorageAccountName;
    end;

    /// <summary>
    /// Returns the Storage Account name for this request
    /// </summary>
    /// <returns>The Storage Account name</returns>
    procedure GetStorageAccountName(): Text
    begin
        exit(StorageAccountName);
    end;

    /// <summary>
    /// Sets the Container name for this request
    /// </summary>
    /// <param name="NewContainerName">The Container name</param>
    procedure SetContainerName(NewContainerName: Text)
    begin
        ContainerName := NewContainerName;
    end;

    /// <summary>
    /// Returns the Container name for this request
    /// </summary>
    /// <returns>The Container name</returns>
    procedure GetContainerName(): Text
    begin
        exit(ContainerName);
    end;

    /// <summary>
    /// Sets the Blob name for this request
    /// </summary>
    /// <param name="NewBlobName">The Blob name</param>
    procedure SetBlobName(NewBlobName: Text)
    begin
        BlobName := NewBlobName;
    end;

    /// <summary>
    /// Returns the Blob name for this request
    /// </summary>
    /// <returns>The Blob name</returns>
    procedure GetBlobName(): Text
    begin
        exit(BlobName);
    end;

    /// <summary>
    /// Sets the Authorization Type for this request
    /// </summary>
    /// <param name="NewAuthType">The Authorization Type</param>
    procedure SetAuthorizationType(NewAuthType: Enum "Storage Service Authorization Type")
    begin
        AuthType := NewAuthType;
    end;

    /// <summary>
    /// Returns the Authorization Type for this request
    /// </summary>
    /// <returns>The Authorization Type</returns>
    procedure GetAuthorizationType(): Enum "Storage Service Authorization Type"
    begin
        exit(AuthType);
    end;

    /// <summary>
    /// Sets the Secret for this request
    /// </summary>
    /// <param name="NewSecret">The Secret</param>
    procedure SetSecret(NewSecret: Text)
    begin
        Secret := NewSecret;
    end;

    /// <summary>
    /// Returns the Secret for this request
    /// </summary>
    /// <returns>The Secret</returns>
    procedure GetSecret(): Text
    begin
        exit(Secret);
    end;

    /// <summary>
    /// Sets the API Version for this request
    /// </summary>
    /// <param name="NewApiVersion">The API Version</param>
    procedure SetApiVersion(NewApiVersion: Enum "Storage Service API Version")
    begin
        ApiVersion := NewApiVersion;
    end;

    /// <summary>
    /// Returns the API Version for this request
    /// </summary>
    /// <returns>The API Version</returns>
    procedure GetApiVersion(): Enum "Storage Service API Version"
    begin
        exit(ApiVersion);
    end;

    /// <summary>
    /// Sets the Operation for this request
    /// </summary>
    /// <param name="NewOperation">The Operation</param>
    procedure SetOperation(NewOperation: Enum "Blob Service API Operation")
    var
        HelperLibrary: Codeunit "Blob API Helper Library";
    begin
        Operation := NewOperation;
        // Only API Versions after 2017-04-17 are considered
        case Operation of
            Operation::GetAccountInformation:
                HelperLibrary.ValidateApiVersion(ApiVersion, ApiVersion::"2018-03-28", NewOperation, true);
            Operation::SetBlobExpiry:
                HelperLibrary.ValidateApiVersion(ApiVersion, ApiVersion::"2020-02-10", NewOperation, true);
            Operation::UndeleteBlob:
                HelperLibrary.ValidateApiVersion(ApiVersion, ApiVersion::"2017-07-29", NewOperation, true);
            Operation::PutBlockFromURL:
                HelperLibrary.ValidateApiVersion(ApiVersion, ApiVersion::"2018-03-28", NewOperation, true);
            Operation::GetUserDelegationKey:
                Error('Only works with Azure AD authentication, which is not implemented yet'); // TODO: Make real error
        end
    end;

    /// <summary>
    /// Returns the Operation for this request
    /// </summary>
    /// <returns>The Operation</returns>
    procedure GetOperation(): Enum "Blob Service API Operation"
    begin
        exit(Operation);
    end;


    internal procedure SetHeaderValues(NewHeaderValues: Dictionary of [Text, Text])
    begin
        HeaderValues := NewHeaderValues;
    end;
    // #endregion Set/Get Globals

    // #region Uri generation
    /// <summary>
    /// Creates the Uri for this object, based on given values
    /// </summary>
    /// <returns>An Uri (as Text) for this API Operation</returns>
    procedure ConstructUri(): Text
    var
        URIHelepr: Codeunit "Blob API URI Helper";
    begin
        URIHelepr.SetOptionalUriParameter(OptionalUriParameters);
        exit(URIHelepr.ConstructUri(StorageAccountName, ContainerName, BlobName, Operation, AuthType, Secret));
    end;
    // #endregion Uri generation

    // #region Shared Key Signature Generation
    /// <summary>
    /// Creates the SharedKey signature for this object, based on given values
    /// </summary>
    /// <param name="HttpRequestType">Enum "Http Request Type" specifying the type for this API Operation</param>
    /// <returns>The SharedKey signature (as Text) for this API Operation, which is added to the "Authorization"-header</returns>
    internal procedure GetSharedKeySignature(HttpRequestType: Enum "Http Request Type"): Text
    var
        ReqAuthAccessKey: Codeunit "Storage Serv. Auth. Access Key";
    begin
        ReqAuthAccessKey.SetHeaderValues(HeaderValues);
        ReqAuthAccessKey.SetApiVersion(ApiVersion);
        exit(ReqAuthAccessKey.GetSharedKeySignature(HttpRequestType, StorageAccountName, ConstructUri(), Secret));
    end;
    // #endregion Shared Key Signature Generation

    /// <summary>
    /// Adds an entry to the internally used Header-Dictionary
    /// </summary>
    /// <param name="Key">Identifier for the Header</param>
    /// <param name="Value">Value for the Header</param>
    procedure AddHeader("Key": Text; "Value": Text)
    begin
        if HeaderValues.ContainsKey("Key") then
            HeaderValues.Remove("Key");
        HeaderValues.Add("Key", "Value");
    end;

    /// <summary>
    /// Adds an entry to the internally used Header-Dictionary and to a HttpHeaders-variable at the same time
    /// </summary>
    /// <param name="Headers">HttpHeaders that should have the specified Header-value</param>
    /// <param name="Key">Identifier for the Header</param>
    /// <param name="Value">Value for the Header</param>
    procedure AddHeader(var Headers: HttpHeaders; "Key": Text; "Value": Text)
    begin
        AddHeader("Key", "Value");
        if Headers.Contains("Key") then
            Headers.Remove("Key");
        Headers.Add("Key", "Value");
    end;

    /// <summary>
    /// Removes an entry from the internally used Header-Dictionary and from a HttpHeaders-variable at the same time
    /// </summary>
    /// <param name="Headers">HttpHeaders that should have the specified Header-value</param>
    /// <param name="Key">Identifier for the Header</param>
    procedure RemoveHeader(var Headers: HttpHeaders; "Key": Text)
    var
    begin
        if HeaderValues.ContainsKey("Key") then
            HeaderValues.Remove("Key");
        if Headers.Contains("Key") then
            Headers.Remove("Key");
    end;

    /// <summary>
    /// Adds an entry to the internally used OptionalHeader-Dictionary
    /// </summary>
    /// <param name="Key">Identifier for the Header</param>
    /// <param name="Value">Value for the Header</param>
    procedure AddOptionalHeader("Key": Text; "Value": Text)
    begin
        if OptionalHeaderValues.ContainsKey("Key") then
            OptionalHeaderValues.Remove("Key");
        OptionalHeaderValues.Add("Key", "Value");
    end;

    /// <summary>
    /// Retrieves a value from the internally used OptionalHeader-Dictionary
    /// </summary>
    /// <param name="HeaderKey">Identifier for the Header</param>
    /// <param name="HeaderValue">Value for the Header (contains the result)</param>
    /// <returns>Boolean indicating if the value exists</returns>
    procedure GetOptionalHeaderValue(HeaderKey: Text; var HeaderValue: Text): Boolean
    begin
        exit(OptionalHeaderValues.Get(HeaderKey, HeaderValue));
    end;

    /// <summary>
    /// Creates a sorted Dictionary containg all Headers and OptionalHeaderValues from this object.
    /// </summary>
    /// <returns>Sorted Dictionary of [Text, Text] containg all Headers and OptionalHeaderValues from this object.</returns>
    internal procedure GetSortedHeadersDictionary() NewHeaders: Dictionary of [Text, Text]
    var
        SortedDictionary: DotNet SortedDictionary2;
        SortedDictionaryEntry: DotNet GenericKeyValuePair2;
        HeaderKey: Text;
        HeaderValue: Text;
    begin
        SortedDictionary := SortedDictionary.SortedDictionary();

        Clear(NewHeaders);

        foreach HeaderKey in HeaderValues.Keys do
            SortedDictionary.Add(HeaderKey, HeaderValues.Get(HeaderKey));

        foreach HeaderKey in OptionalHeaderValues.Keys do begin
            if SortedDictionary.ContainsKey(HeaderKey) then
                SortedDictionary.Remove(HeaderKey);
            SortedDictionary.Add(HeaderKey, OptionalHeaderValues.Get(HeaderKey));
        end;

        foreach SortedDictionaryEntry in SortedDictionary do
            NewHeaders.Add(SortedDictionaryEntry."Key", SortedDictionaryEntry.Value);
    end;

    // #region Optional Uri Parameters
    /// <summary>
    /// Adds an entry to the internally used OptionalUriParameters-Dictionary
    /// </summary>
    /// <param name="Key">Identifier for the Parameter</param>
    /// <param name="Value">Value for the Parameter</param>
    procedure AddOptionalUriParameter("Key": Text; "Value": Text)
    begin
        if OptionalUriParameters.ContainsKey("Key") then
            OptionalUriParameters.Remove("Key");
        OptionalUriParameters.Add("Key", "Value");
    end;
    // #endregion Optional Uri Parameters
}