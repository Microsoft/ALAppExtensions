// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
enum 9040 "Blob Service API Operation"
{
    Extensible = false;

    // #region Account-level operations
    value(0; ListContainers)
    {
        Caption = 'List Containers';
    }
    value(1; SetBlobServiceProperties)
    {
        Caption = 'Set Blob Service Properties';
    }
    value(2; GetBlobServiceProperties)
    {
        Caption = 'Get Blob Service Properties';
    }
    value(3; PreflightBlobRequest)
    {
        Caption = 'Preflight Blob Request';
    }
    value(4; GetBlobServiceStats)
    {
        Caption = 'Get Blob Service Stats';
    }
    value(5; GetAccountInformation)
    {
        Caption = 'Get Account Information';
    }
    value(6; GetUserDelegationKey)
    {
        Caption = 'Get User Delegation Key';
    }
    // #endregion Account-level operations
    // #region Container-level operations    
    value(20; CreateContainer)
    {
        Caption = 'Create Container';
    }
    value(21; GetContainerProperties)
    {
        Caption = 'Get Container Properties';
    }
    value(22; GetContainerMetadata)
    {
        Caption = 'Get Container Metadata';
    }
    value(23; SetContainerMetadata)
    {
        Caption = 'Set Container Metadata';
    }
    value(24; GetContainerAcl)
    {
        Caption = 'Get Container ACL';
    }
    value(25; SetContainerAcl)
    {
        Caption = 'Set Container ACL';
    }
    value(26; DeleteContainer)
    {
        Caption = 'Delete Container';
    }
    value(27; LeaseContainer)
    {
        Caption = 'Lease Container';
    }
    /*
    value(28; RestoreContainer)
    {
        Caption = 'Restore Container';
    }
    */
    value(29; ListBlobs)
    {
        Caption = 'List Blobs';
    }
    // #endregion Container-level operations
    // #region Blob-level operations    
    value(40; PutBlob)
    {
        Caption = 'Upload Blob';
    }
    value(41; PutBlobFromURL)
    {
        Caption = 'Upload Blob';
    }
    value(42; GetBlob)
    {
        Caption = 'Get Blob';
    }
    value(43; GetBlobProperties)
    {
        Caption = 'Get Blob Properties';
    }
    value(44; SetBlobProperties)
    {
        Caption = 'Set Blob Properties';
    }
    value(45; GetBlobMetadata)
    {
        Caption = 'Get Blob Metadata';
    }
    value(46; SetBlobMetadata)
    {
        Caption = 'Set Blob Metadata';
    }
    value(47; GetBlobTags)
    {
        Caption = 'Get Blob Tags';
    }
    value(48; SetBlobTags)
    {
        Caption = 'Set Blob Tags';
    }
    value(49; FindBlobByTags)
    {
        Caption = 'Find Blobs by Tags';
    }
    value(50; LeaseBlob)
    {
        Caption = 'Lease Blob';
    }
    value(51; SnapshotBlob)
    {
        Caption = 'Snapshot Blob';
    }
    value(52; CopyBlob)
    {
        Caption = 'Copy Blob';
    }
    value(53; CopyBlobFromUrl)
    {
        Caption = 'Copy Blob from URL';
    }
    value(54; AbortCopyBlob)
    {
        Caption = 'Abort Copy Blob';
    }
    value(55; DeleteBlob)
    {
        Caption = 'Delete Blob';
    }
    value(56; UndeleteBlob)
    {
        Caption = 'Undelete Blob';
    }
    value(57; SetBlobTier)
    {
        Caption = 'Set Blob Tier';
    }
    /*
    value(58; BlobBatch)
    {
        Caption = 'Blob Batch';
    }
    */
    // #region Block Blob-level operations
    value(70; PutBlock)
    {
        Caption = 'Put Block';
    }
    value(71; PutBlockFromURL)
    {
        Caption = 'Put Block from URL';
    }
    value(72; PutBlockList)
    {
        Caption = 'Put Block List';
    }
    value(73; GetBlockList)
    {
        Caption = 'Get Block List';
    }
    value(74; QueryBlobContents)
    {
        Caption = 'Query Blob Contents';
    }
    // #endregion Block Blob-level operations
    // #region Page Blob-level operations
    value(80; PutPage)
    {
        Caption = 'Put Page';
    }
    value(81; PutPageFromURL)
    {
        Caption = 'Put Page from URL';
    }
    value(82; GetPageRanges)
    {
        Caption = 'Get Page Ranges';
    }
    value(83; IncrementalCopyBlob)
    {
        Caption = 'Incremental Copy Blob';
    }
    // #endregion Page Blob-level operations
    // #region Append Blob-level operations
    value(100; AppendBlock)
    {
        Caption = 'Append Block';
    }
    value(101; AppendBlockFromURL)
    {
        Caption = 'Append Block from URL';
    }
    // #endregion Append Blob-level operations
    // #region Hierarchical Namespaces-level operations
    value(120; SetBlobExpiry)
    {
        Caption = 'Set Blob Expiry';
    }
    // #endregion Hierarchical Namespaces-level operations
    // #endregion Blob-level operations
}