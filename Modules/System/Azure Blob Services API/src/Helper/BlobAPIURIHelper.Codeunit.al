// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 9046 "Blob API URI Helper"
{
    Access = Internal;

    var
        OptionalUriParameters: Dictionary of [Text, Text];

    procedure SetOptionalUriParameter(NewOptionalUriParameters: Dictionary of [Text, Text])
    begin
        OptionalUriParameters := NewOptionalUriParameters;
    end;

    // #region Uri generation
    procedure ConstructUri(var OperationPayload: Codeunit "Blob API Operation Payload"): Text
    begin
        exit(ConstructUri(OperationPayload.GetStorageAccountName(), OperationPayload.GetContainerName(), OperationPayload.GetBlobName(), OperationPayload.GetOperation(), OperationPayload.GetAuthorizationType(), OperationPayload.GetSecret()));
    end;

    procedure ConstructUri(StorageAccountName: Text; ContainerName: Text; BlobName: Text; Operation: Enum "Blob Service API Operation"; AuthType: Enum "Storage Service Authorization Type"; Secret: Text): Text
    var
        FormatHelper: Codeunit "Blob API Format Helper";
        AuthorizationType: Enum "Storage Service Authorization Type";
        ConstructedUrl: Text;
        BlobStorageBaseUrlLbl: Label 'https://%1.blob.core.windows.net', Comment = '%1 = Storage Account Name';
    begin
        TestConstructUrlParameter(StorageAccountName, ContainerName, BlobName, Operation, AuthType, Secret);

        // e.g. https://<StorageAccountName>-secondary.blob.core.windows.net/?restype=service&comp=stats
        if (Operation = Operation::GetBlobServiceStats) and (StorageAccountName <> 'devstoreaccount1') then
            StorageAccountName := StorageAccountName + '-secondary';
        ConstructedUrl := StrSubstNo(BlobStorageBaseUrlLbl, StorageAccountName);

        // If using Azure Storage Emulator (indicated by Account Name "devstoreaccount1") then use a different Uri
        if StorageAccountName = 'devstoreaccount1' then
            ConstructedUrl := 'http://127.0.0.1:10000/devstoreaccount1';

        AppendContainerIfNecessary(ConstructedUrl, ContainerName, Operation);
        AppendBlobIfNecessary(ConstructedUrl, BlobName, Operation);
        AppendRestTypeIfNecessary(ConstructedUrl, Operation);
        AppendCompValueIfNecessary(ConstructedUrl, Operation);

        // e.g. https://<StorageAccountName>.blob.core.windows.net/<Container>/<BlobName>?comp=copy&coppyid=<Id>
        if Operation = Operation::AbortCopyBlob then
            FormatHelper.AppendToUri(ConstructedUrl, 'copyid', RetrieveFromOptionalUriParameters('copyid'));
        if Operation in [Operation::Putblock, Operation::PutBlockFromURL] then
            FormatHelper.AppendToUri(ConstructedUrl, 'blockid', RetrieveFromOptionalUriParameters('blockid'));

        AddOptionalUriParameters(ConstructedUrl);

        // If SaS-Token is used for authentication, append it to the URI
        if AuthType = AuthorizationType::SasToken then
            FormatHelper.AppendToUri(ConstructedUrl, '', Secret);
        exit(ConstructedUrl);
    end;

    local procedure AppendContainerIfNecessary(var ConstructedUrl: Text; ContainerName: Text; Operation: Enum "Blob Service API Operation")
    begin
        // e.g. https://<StorageAccountName>.blob.core.windows.net/<ContainerName>?restype=container
        if not (Operation in [Operation::DeleteContainer, Operation::ListBlobs, Operation::CreateContainer,
                              Operation::GetContainerProperties, Operation::GetBlob, Operation::PutBlob, Operation::DeleteBlob,
                              Operation::CopyBlob, Operation::CopyBlobFromUrl, Operation::LeaseContainer, Operation::LeaseBlob, Operation::AbortCopyBlob,
                              Operation::GetBlobProperties, Operation::SetBlobProperties, Operation::GetContainerMetadata, Operation::SetContainerMetadata,
                              Operation::GetBlobMetadata, Operation::SetBlobMetadata, Operation::GetContainerAcl, Operation::SetContainerAcl,
                              Operation::GetBlobTags, Operation::SetBlobTags, Operation::SetBlobExpiry, Operation::SnapshotBlob,
                              Operation::UndeleteBlob, Operation::AppendBlock, Operation::AppendBlockFromURL, Operation::SetBlobTier, Operation::PutPage, Operation::PutPageFromURL, Operation::GetPageRanges, Operation::IncrementalCopyBlob,
                              Operation::PutBlock, Operation::PutBlockFromURL, Operation::PutBlockList, Operation::GetBlockList, Operation::PreflightBlobRequest, Operation::QueryBlobContents]) then
            exit;
        if not ConstructedUrl.EndsWith('/') then
            ConstructedUrl += '/';
        ConstructedUrl += ContainerName;
    end;

    local procedure AppendBlobIfNecessary(var ConstructedUrl: Text; BlobName: Text; Operation: Enum "Blob Service API Operation")
    begin
        // e.g. https://<StorageAccountName>.blob.core.windows.net/<Container>/<BlobName>
        if not (Operation in [Operation::GetBlob, Operation::PutBlob, Operation::DeleteBlob, Operation::CopyBlob, Operation::CopyBlobFromUrl, Operation::LeaseBlob,
                              Operation::AbortCopyBlob, Operation::GetBlobProperties, Operation::SetBlobProperties, Operation::GetBlobMetadata,
                              Operation::SetBlobMetadata, Operation::GetBlobTags, Operation::SetBlobTags, Operation::SetBlobExpiry, Operation::SnapshotBlob,
                              Operation::UndeleteBlob, Operation::AppendBlock, Operation::AppendBlockFromURL, Operation::SetBlobTier, Operation::PutPage, Operation::PutPageFromURL, Operation::GetPageRanges, Operation::IncrementalCopyBlob,
                              Operation::PutBlock, Operation::PutBlockFromURL, Operation::PutBlockList, Operation::GetBlockList, Operation::PreflightBlobRequest, Operation::QueryBlobContents]) then
            exit;
        if (Operation = Operation::PreflightBlobRequest) and (BlobName = '') then // Blob is not mandatory for Operation::PreflightBlobRequest, so only proceed if given
            exit;
        if not ConstructedUrl.EndsWith('/') then
            ConstructedUrl += '/';
        ConstructedUrl += BlobName;
    end;

    local procedure AppendRestTypeIfNecessary(var ConstructedUrl: Text; Operation: Enum "Blob Service API Operation")
    var
        FormatHelper: Codeunit "Blob API Format Helper";
        RestType: Text;
        RestTypeLbl: Label 'restype';
        ContainerRestTypeLbl: Label 'container';
        ServiceRestTypeLbl: Label 'service';
        AccountRestTypeLbl: Label 'account';
    begin
        // e.g. https://<StorageAccountName>.blob.core.windows.net/?restype=account&comp=properties
        case Operation of
            Operation::LeaseContainer, Operation::CreateContainer, Operation::GetContainerProperties, Operation::ListBlobs,
            Operation::DeleteContainer, Operation::ListContainers, Operation::GetContainerMetadata, Operation::SetContainerMetadata,
            Operation::GetContainerAcl, Operation::SetContainerAcl:
                RestType := ContainerRestTypeLbl;
            Operation::GetAccountInformation:
                RestType := AccountRestTypeLbl;
            Operation::GetBlobServiceProperties, Operation::SetBlobServiceProperties, Operation::GetBlobServiceStats:
                RestType := ServiceRestTypeLbl;
            Operation::GetUserDelegationKey:
                RestType := ServiceRestTypeLbl;
        end;
        if RestType = '' then
            exit;
        FormatHelper.AppendToUri(ConstructedUrl, RestTypeLbl, RestType);
    end;

    local procedure AppendCompValueIfNecessary(var ConstructedUrl: Text; Operation: Enum "Blob Service API Operation")
    var
        FormatHelper: Codeunit "Blob API Format Helper";
        CompValue: Text;
        CompIdentifierLbl: Label 'comp';
        ListExtensionLbl: Label 'list';
        LeaseExtensionLbl: Label 'lease';
        CopyExtensionLbl: Label 'copy';
        PropertiesExtensionLbl: Label 'properties';
        MetadataExtensionLbl: Label 'metadata';
        AclExtensionLbl: Label 'acl';
        StatsExtensionLbl: Label 'stats';
        TagsExtensionLbl: Label 'tags';
        BlobsExtensionLbl: Label 'blobs';
        ExpiryExtensionLbl: Label 'expiry';
        SnapshotExtensionLbl: Label 'snapshot';
        UndeleteExtensionLbl: Label 'undelete';
        AppendBlockExtensionLbl: Label 'appendblock';
        TierExtensionLbl: Label 'tier';
        PageExtensionLbl: Label 'page';
        PageListExtensionLbl: Label 'pagelist';
        IncrementalCopyExtensionLbl: Label 'incrementalcopy';
        BlockExtensionLbl: Label 'block';
        BlockListExtensionLbl: Label 'blocklist';
        UserDelegationKeyExtensionLbl: Label 'userdelegationkey';
        QueryExtensionLbl: Label 'query';
    begin
        // e.g. https://<StorageAccountName>.blob.core.windows.net/?restype=account&comp=properties
        case Operation of
            Operation::ListContainers, Operation::ListBlobs:
                CompValue := ListExtensionLbl;
            Operation::LeaseContainer, Operation::LeaseBlob:
                CompValue := LeaseExtensionLbl;
            Operation::AbortCopyBlob:
                CompValue := CopyExtensionLbl;
            Operation::GetAccountInformation, Operation::GetBlobServiceProperties, Operation::SetBlobServiceProperties, Operation::SetBlobProperties:
                CompValue := PropertiesExtensionLbl;
            Operation::GetContainerMetadata, Operation::SetContainerMetadata, Operation::GetBlobMetadata, Operation::SetBlobMetadata:
                CompValue := MetadataExtensionLbl;
            Operation::GetContainerAcl, Operation::SetContainerAcl:
                CompValue := AclExtensionLbl;
            Operation::GetBlobServiceStats:
                CompValue := StatsExtensionLbl;
            Operation::GetBlobTags, Operation::SetBlobTags:
                CompValue := TagsExtensionLbl;
            Operation::FindBlobByTags:
                CompValue := BlobsExtensionLbl;
            Operation::SetBlobExpiry:
                CompValue := ExpiryExtensionLbl;
            Operation::SnapshotBlob:
                CompValue := SnapshotExtensionLbl;
            Operation::UndeleteBlob:
                CompValue := UndeleteExtensionLbl;
            Operation::AppendBlock:
                CompValue := AppendBlockExtensionLbl;
            Operation::SetBlobTier:
                CompValue := TierExtensionLbl;
            Operation::PutPage, Operation::PutPageFromURL:
                CompValue := PageExtensionLbl;
            Operation::GetPageRanges:
                CompValue := PageListExtensionLbl;
            Operation::IncrementalCopyBlob:
                CompValue := IncrementalCopyExtensionLbl;
            Operation::PutBlock, Operation::PutBlockFromURL:
                CompValue := BlockExtensionLbl;
            Operation::GetBlockList, Operation::PutBlockList:
                CompValue := BlockListExtensionLbl;
            Operation::GetUserDelegationKey:
                CompValue := UserDelegationKeyExtensionLbl;
            Operation::AppendBlockFromURL:
                CompValue := AppendBlockExtensionLbl;
            Operation::QueryBlobContents:
                CompValue := QueryExtensionLbl;
        end;
        if CompValue = '' then
            exit;
        FormatHelper.AppendToUri(ConstructedUrl, CompIdentifierLbl, CompValue);
    end;

    local procedure RetrieveFromOptionalUriParameters(Identifier: Text): Text
    var
        ReturnValue: Text;
    begin
        if not OptionalUriParameters.ContainsKey(Identifier) then
            exit;

        OptionalUriParameters.Get(Identifier, ReturnValue);
        exit(ReturnValue);
    end;

    local procedure AddOptionalUriParameters(var Uri: Text)
    var
        FormatHelper: Codeunit "Blob API Format Helper";
        ParameterIdentifier: Text;
        ParameterValue: Text;
    begin
        if OptionalUriParameters.Count = 0 then
            exit;

        foreach ParameterIdentifier in OptionalUriParameters.Keys do
            if not (ParameterIdentifier in ['copyid', 'blockid']) then begin
                OptionalUriParameters.Get(ParameterIdentifier, ParameterValue);
                FormatHelper.AppendToUri(Uri, ParameterIdentifier, ParameterValue);
            end;
    end;

    local procedure TestConstructUrlParameter(StorageAccountName: Text; ContainerName: Text; BlobName: Text; Operation: Enum "Blob Service API Operation"; AuthType: Enum "Storage Service Authorization Type"; Secret: Text)
    var
        AuthorizationType: Enum "Storage Service Authorization Type";
        ValueCanNotBeEmptyErr: Label '%1 can not be empty', Comment = '%1 = Variable Name';
        StorageAccountNameLbl: Label 'Storage Account Name';
        SasTokenLbl: Label 'Shared Access Signature (Token)';
        AccesKeyLbl: Label 'Access Key';
        ContainerNameLbl: Label 'Container Name';
        BlobNameLbl: Label 'Blob Name';
    begin
        if StorageAccountName = '' then
            Error(ValueCanNotBeEmptyErr, StorageAccountNameLbl);

        case AuthType of
            AuthorizationType::SasToken:
                if Secret = '' then
                    Error(ValueCanNotBeEmptyErr, SasTokenLbl);
            AuthorizationType::AccessKey:
                if Secret = '' then
                    Error(ValueCanNotBeEmptyErr, AccesKeyLbl);
        end;

        case true of
            Operation in [Operation::GetBlob, Operation::PutBlob, Operation::DeleteBlob]:
                begin
                    if ContainerName = '' then
                        Error(ValueCanNotBeEmptyErr, ContainerNameLbl);
                    if BlobName = '' then
                        Error(ValueCanNotBeEmptyErr, BlobNameLbl);
                end;
        end;
    end;
    // #endregion Uri generation
}