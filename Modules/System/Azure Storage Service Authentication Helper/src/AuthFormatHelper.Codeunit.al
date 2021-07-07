// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 9060 "Auth. Format Helper"
{
    Access = Internal;

    procedure GetNewLineCharacter(): Text
    var
        LF: Char;
    begin
        LF := 10;
        exit(Format(LF));
    end;

    procedure GetIso8601DateTime(MyDateTime: DateTime): Text
    var
        DateTimeAsXmlString: Text;
    begin
        DateTimeAsXmlString := Format(MyDateTime, 0, 9); // Format as XML, e.g.: 2020-11-11T08:50:07.553Z
        if DateTimeAsXmlString.Contains('.') then
            DateTimeAsXmlString := DateTimeAsXmlString.Substring(1, DateTimeAsXmlString.LastIndexOf('.'));
        exit(DateTimeAsXmlString);
    end;

    procedure GetAccessKeyHashCode(StringToSign: Text; AccessKey: Text): Text;
    var
        CryptographyMgmt: Codeunit "Cryptography Management";
        HashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512;
    begin
        exit(CryptographyMgmt.GenerateBase64KeyedHashAsBase64String(StringToSign, AccessKey, HashAlgorithmType::HMACSHA256));
    end;

    procedure GetCanonicalizedHeaders(Headers: Dictionary of [Text, Text]): Text
    var
        AuthenticationHelper: Codeunit "Auth. Format Helper";
        HeaderKey: Text;
        HeaderValue: Text;
        CanonicalizedHeaders: Text;
        KeyValuePairLbl: Label '%1:%2', Comment = '%1 = Key; %2 = Value';
    begin
        // "Headers" needs to be a sorted dictionary
        foreach HeaderKey in Headers.Keys do
            if (HeaderKey.ToLower().StartsWith('x-ms-')) then begin // only add headers that start with "x-ms-"
                if CanonicalizedHeaders <> '' then
                    CanonicalizedHeaders += AuthenticationHelper.GetNewLineCharacter();
                HeaderValue := Headers.Get(HeaderKey);
                CanonicalizedHeaders += StrSubstNo(KeyValuePairLbl, HeaderKey.ToLower(), HeaderValue)
            end;
        exit(CanonicalizedHeaders);
    end;

    procedure GetCanonicalizedResource(StorageAccount: Text; UriString: Text): Text
    var
        Uri: Codeunit Uri;
        UriBuider: Codeunit "Uri Builder";
        AuthenticationHelper: Codeunit "Auth. Format Helper";
        SortedDictionaryQuery: DotNet SortedDictionary2;
        SortedDictionaryEntry: DotNet GenericKeyValuePair2;
        QueryString: Text;
        Segments: List of [Text];
        Segment: Text;
        StringBuilderResource: TextBuilder;
        StringBuilderQuery: TextBuilder;
        StringBuilderCanonicalizedResource: TextBuilder;
        KeyValuePairLbl: Label '%1:%2', Comment = '%1 = Key; %2 = Value';
    begin
        Uri.Init(UriString);
        Uri.GetSegments(Segments);

        UriBuider.Init(UriString);
        QueryString := UriBuider.GetQuery();

        StringBuilderResource.Append('/');
        StringBuilderResource.Append(StorageAccount);
        foreach Segment in Segments do
            StringBuilderResource.Append(Segment);

        if QueryString <> '' then begin
            // According to documentation it should be lexicographically, but I didn't find a better way than SortedDictionary
            // see: https://docs.microsoft.com/en-us/rest/api/storageservices/authorize-with-shared-key#constructing-the-canonicalized-headers-string
            SplitQueryStringIntoSortedDictionary(QueryString, SortedDictionaryQuery);
            foreach SortedDictionaryEntry in SortedDictionaryQuery do begin
                StringBuilderQuery.Append(AuthenticationHelper.GetNewLineCharacter());
                StringBuilderQuery.Append(StrSubstNo(KeyValuePairLbl, SortedDictionaryEntry."Key", Uri.UnescapeDataString(SortedDictionaryEntry.Value)));
            end;
        end;
        StringBuilderCanonicalizedResource.Append(StringBuilderResource.ToText());
        StringBuilderCanonicalizedResource.Append(StringBuilderQuery.ToText());
        exit(StringBuilderCanonicalizedResource.ToText());
    end;

    local procedure SplitQueryStringIntoSortedDictionary(QueryString: Text; var NewSortedDictionary: DotNet SortedDictionary2)
    var
        Segments: List of [Text];
        Segment: Text;
        CurrIdentifier: Text;
        CurrValue: Text;
    begin
        if QueryString.StartsWith('?') then
            QueryString := CopyStr(QueryString, 2);
        Segments := QueryString.Split('&');

        NewSortedDictionary := NewSortedDictionary.SortedDictionary();

        foreach Segment in Segments do begin
            GetKeyValueFromQueryParameter(Segment, CurrIdentifier, CurrValue);
            NewSortedDictionary.Add(CurrIdentifier, CurrValue);
        end;
    end;

    local procedure GetKeyValueFromQueryParameter(QueryString: Text; var CurrIdentifier: Text; var CurrValue: Text)
    var
        Split: List of [Text];
    begin
        Split := QueryString.Split('=');
        if Split.Count <> 2 then
            Error('This should not happen'); // TODO: Make better error
        CurrIdentifier := Split.Get(1);
        CurrValue := Split.Get(2);
    end;

    procedure CreateSharedKeyStringToSign(ApiVersion: Enum "Storage service API Version"; HeaderValues: Dictionary of [Text, Text]; HttpRequestType: Enum "Http Request Type"; StorageAccount: Text; UriString: Text): Text
    var
        StringToSign: Text;
    begin
        // TODO: Add Handling-structure for different API-versions
        StringToSign += Format(HttpRequestType) + GetNewLineCharacter();
        StringToSign += GetHeaderValueOrEmpty(HeaderValues, 'Content-Encoding') + GetNewLineCharacter();
        StringToSign += GetHeaderValueOrEmpty(HeaderValues, 'Content-Language') + GetNewLineCharacter();
        StringToSign += GetHeaderValueOrEmpty(HeaderValues, 'Content-Length') + GetNewLineCharacter();
        StringToSign += GetHeaderValueOrEmpty(HeaderValues, 'Content-MD5') + GetNewLineCharacter();
        StringToSign += GetHeaderValueOrEmpty(HeaderValues, 'Content-Type') + GetNewLineCharacter();
        StringToSign += GetHeaderValueOrEmpty(HeaderValues, 'Date') + GetNewLineCharacter();
        StringToSign += GetHeaderValueOrEmpty(HeaderValues, 'If-Modified-Since') + GetNewLineCharacter();
        StringToSign += GetHeaderValueOrEmpty(HeaderValues, 'If-Match') + GetNewLineCharacter();
        StringToSign += GetHeaderValueOrEmpty(HeaderValues, 'If-None-Match') + GetNewLineCharacter();
        StringToSign += GetHeaderValueOrEmpty(HeaderValues, 'If-Unmodified-Since') + GetNewLineCharacter();
        StringToSign += GetHeaderValueOrEmpty(HeaderValues, 'Range') + GetNewLineCharacter();
        StringToSign += GetCanonicalizedHeaders(HeaderValues) + GetNewLineCharacter();
        StringToSign += GetCanonicalizedResource(StorageAccount, UriString);
        exit(StringToSign);
    end;

    local procedure GetHeaderValueOrEmpty(HeaderValues: Dictionary of [Text, Text]; HeaderKey: Text): Text
    var
        ReturnValue: Text;
    begin
        if not HeaderValues.Get(HeaderKey, ReturnValue) then
            exit('');
        if HeaderKey = 'Content-Length' then
            if ReturnValue = '0' then // TODO: In version 2014-02-14 and earlier, the content length was included even if zero.  
                exit('');
        exit(ReturnValue);
    end;

    // #region Used for Shared Access Signature creation
    procedure CreateSharedAccessSignatureStringToSign(AccountName: Text; ApiVersion: Enum "Storage Service API Version"; StartDate: DateTime; EndDate: DateTime; Services: List of [Enum "Storage Service Type"]; Resources: List of [Enum "Storage Service Resource Type"]; Permissions: List of [Enum "Storage Service Permission"]; Protocols: List of [Text]; IPRange: Text): Text
    var
        StringToSign: Text;
    begin
        StringToSign += AccountName + GetNewLineCharacter();
        StringToSign += PermissionsToString(Permissions) + GetNewLineCharacter();
        StringToSign += ServicesToString(Services) + GetNewLineCharacter();
        StringToSign += ResourcesToString(Resources) + GetNewLineCharacter();
        StringToSign += DateToString(StartDate) + GetNewLineCharacter();
        StringToSign += DateToString(EndDate) + GetNewLineCharacter();
        StringToSign += IPRange + GetNewLineCharacter();
        StringToSign += ProtocolsToString(Protocols) + GetNewLineCharacter();
        StringToSign += VersionToString(ApiVersion) + GetNewLineCharacter();
        exit(StringToSign);
    end;

    procedure CreateSasUrlString(ApiVersion: Enum "Storage Service API Version"; StartDate: DateTime; EndDate: DateTime; Services: List of [Enum "Storage Service Type"]; Resources: List of [Enum "Storage Service Resource Type"]; Permissions: List of [Enum "Storage Service Permission"]; Protocols: List of [Text]; IPRange: Text; Signature: Text): Text
    var
        Uri: Codeunit Uri;
        Builder: TextBuilder;
        KeyValueLbl: Label '%1=%2', Comment = '%1 = Key; %2 = Value';
    begin
        Builder.Append('?');
        Builder.Append(StrSubstNo(KeyValueLbl, 'sv', VersionToString(ApiVersion)));
        Builder.Append('&');
        Builder.Append(StrSubstNo(KeyValueLbl, 'ss', ServicesToString(Services)));
        Builder.Append('&');
        Builder.Append(StrSubstNo(KeyValueLbl, 'srt', ResourcesToString(Resources)));
        Builder.Append('&');
        Builder.Append(StrSubstNo(KeyValueLbl, 'sp', PermissionsToString(Permissions)));
        Builder.Append('&');
        Builder.Append(StrSubstNo(KeyValueLbl, 'se', DateToString(EndDate)));
        Builder.Append('&');
        Builder.Append(StrSubstNo(KeyValueLbl, 'st', DateToString(StartDate)));
        Builder.Append('&');
        Builder.Append(StrSubstNo(KeyValueLbl, 'spr', ProtocolsToString(Protocols)));
        Builder.Append('&');
        Builder.Append(StrSubstNo(KeyValueLbl, 'sig', Uri.EscapeDataString(Signature)));
        exit(Builder.ToText());
    end;

    local procedure VersionToString(ApiVersion: Enum "Storage Service API Version"): Text
    begin
        exit(Format(ApiVersion));
    end;

    local procedure DateToString(MyDateTime: DateTime): Text
    begin
        exit(GetIso8601DateTime(MyDateTime));
    end;

    local procedure ServicesToString(Services: List of [Enum "Storage Service Type"]): Text
    var
        Service: Enum "Storage Service Type";
        Builder: TextBuilder;
    begin
        // TODO: Add Sorting for correct order
        foreach Service in Services do
            case Service of
                Service::Blob:
                    Builder.Append('b');
                Service::File:
                    Builder.Append('f');
                Service::Queue:
                    Builder.Append('q');
                Service::Table:
                    Builder.Append('t');
            end;
        exit(Builder.ToText());
    end;

    local procedure ResourcesToString(Resources: List of [Enum "Storage Service Resource Type"]): Text
    var
        Resource: Enum "Storage Service Resource Type";
        Builder: TextBuilder;
    begin
        // TODO: Add Sorting for correct order
        foreach Resource in Resources do
            case Resource of
                Resource::Service:
                    Builder.Append('s');
                Resource::Container:
                    Builder.Append('c');
                Resource::Object:
                    Builder.Append('o');
            end;
        exit(Builder.ToText());
    end;

    local procedure PermissionsToString(Permissions: List of [Enum "Storage Service Permission"]): Text
    var
        Permission: Enum "Storage Service Permission";
        Builder: TextBuilder;
    begin
        // TODO: Add Sorting for correct order
        foreach Permission in Permissions do
            case Permission of
                Permission::Read:
                    Builder.Append('r');
                Permission::Write:
                    Builder.Append('w');
                Permission::Delete:
                    Builder.Append('d');
                Permission::PermantDelete:
                    Builder.Append('y'); // TODO: Verify
                Permission::List:
                    Builder.Append('l');
                Permission::Add:
                    Builder.Append('a');
                Permission::Create:
                    Builder.Append('c');
                Permission::Update:
                    Builder.Append('u');
                Permission::Process:
                    Builder.Append('p');
                Permission::VersionDeletion:
                    Builder.Append('x');
                Permission::BlobIndexReadWrite:
                    Builder.Append('t');
                Permission::BlobIndexFilter:
                    Builder.Append('f');
            end;
        exit(Builder.ToText());
    end;

    local procedure ProtocolsToString(Protocols: List of [Text]): Text
    var
        Protocol: Text;
        Builder: TextBuilder;
    begin
        foreach Protocol in Protocols do begin
            if Builder.ToText() <> '' then
                Builder.Append(',');
            Builder.Append(Protocol)
        end;
        exit(Builder.ToText());
    end;
    // #endregion
}