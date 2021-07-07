/// <summary>
/// Tests for Blob-level API operations
/// Version: 2020-02-10
/// Authentication: Shared Key
/// </summary>
codeunit 88158 "B. S. Test Key 2020-02-10 BL"
{
    Subtype = Test;

    // TODO: Put Blob    
    // TODO: Get Blob
    [Test]
    procedure ClearStorageAccount()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] This is a helper; it'll remove all containters from the Storage Account (assumes that some other functions are working)
        BlobServiceTestLibrary.ClearStorageAccount(TestContext);
    end;

    [Test]
    procedure SetBlobProperties()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Set properties from a blob
        BlobServiceTestLibrary.SetBlobProperties(TestContext);
    end;

    [Test]
    procedure GetBlobProperties()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Get properties from a blob
        BlobServiceTestLibrary.GetBlobProperties(TestContext);
    end;

    [Test]
    procedure SetBlobMetadata()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Set blob metadata
        BlobServiceTestLibrary.SetBlobMetadata(TestContext);
    end;

    [Test]
    procedure GetBlobMetadata()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Get blob metadata
        BlobServiceTestLibrary.GetBlobMetadata(TestContext);
    end;

    [Test]
    procedure SetBlobTags()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Set blob tags
        BlobServiceTestLibrary.SetBlobTags(TestContext);
    end;

    [Test]
    procedure GetBlobTags()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Get blob tags
        BlobServiceTestLibrary.GetBlobTags(TestContext);
    end;

    [Test]
    procedure FindBlobsByTags()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Set blob tags
        BlobServiceTestLibrary.FindBlobsByTags(TestContext);
    end;

    [Test]
    procedure DeleteBlobWithoutLease()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Delete Blob (without active Lease)
        BlobServiceTestLibrary.DeleteBlobWithoutLease(TestContext);
    end;

    [Test]
    procedure DeleteBlobWithLease()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Delete Blob (with active Lease)
        BlobServiceTestLibrary.DeleteBlobWithLease(TestContext);
    end;

    [Test]
    procedure UndeleteBlob()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Undelete blob
        BlobServiceTestLibrary.UndeleteBlob(TestContext);
    end;

    [Test]
    procedure LeaseBlobAcquireAndRelease()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Acquire a lease for a container
        BlobServiceTestLibrary.LeaseBlobAcquireAndRelease(TestContext);
    end;

    [Test]
    procedure SnapshotBlob()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Snapshot Blob
        BlobServiceTestLibrary.SnapshotBlob(TestContext);
    end;

    [Test]
    procedure CopyBlob()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Copy Blob
        BlobServiceTestLibrary.CopyBlob(TestContext);
    end;

    [Test]
    procedure CopyBlobFromUrl()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Copy Blob from URL
        BlobServiceTestLibrary.CopyBlobFromUrl(TestContext);
    end;

    var
        TestContext: codeunit "Blob Service API Test Context";
        BlobServiceTestLibrary: Codeunit "Blob Service Test Library";
}