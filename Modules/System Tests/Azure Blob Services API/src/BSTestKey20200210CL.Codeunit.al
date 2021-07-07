/// <summary>
/// Tests for Container-level API operations
/// Version: 2020-02-10
/// Authentication: Shared Key
/// </summary>
codeunit 88157 "B. S. Test Key 2020-02-10 CL"
{
    Subtype = Test;

    [Test]
    procedure ClearStorageAccount()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] This is a helper; it'll remove all containters from the Storage Account (assumes that some other functions are working)
        BlobServiceTestLibrary.ClearStorageAccount(TestContext);
    end;

    [Test]
    procedure CreateContainer()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] A new containter is created in the Storage Account
        BlobServiceTestLibrary.CreateContainer(TestContext);
    end;

    [Test]
    procedure GetContainerProperties()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Get Container Properties
        BlobServiceTestLibrary.GetContainerProperties(TestContext);
    end;

    [Test]
    procedure SetContainerMetadata()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Set Container Metadata
        BlobServiceTestLibrary.GetContainerMetadata(TestContext);
    end;

    [Test]
    procedure GetContainerMetadata()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Get Container Metadata
        BlobServiceTestLibrary.GetContainerMetadata(TestContext);
    end;

    [Test]
    procedure GetContainerACL()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Get Container ACL
        BlobServiceTestLibrary.GetContainerACL(TestContext);
    end;

    [Test]
    procedure SetContainerACL()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Set Container ACL
        BlobServiceTestLibrary.SetContainerACL(TestContext);
    end;

    [Test]
    procedure LeaseContainerAcquireAndRelease()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Acquire a lease for a container
        BlobServiceTestLibrary.LeaseContainerAcquireAndRelease(TestContext);
    end;

    [Test]
    procedure DeleteContainerWithoutLease()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] An existing containter is deleted from the Storage Account
        BlobServiceTestLibrary.DeleteContainerWithoutLease(TestContext);
    end;

    [Test]
    procedure DeleteContainerWithLease()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] An existing containter is deleted from the Storage Account
        BlobServiceTestLibrary.DeleteContainerWithLease(TestContext);
    end;

    // TODO: Add more Lease-related Tests

    [Test]
    procedure ListBlobs()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] List Blob from a container
        BlobServiceTestLibrary.ListBlobs(TestContext);
    end;

    var
        TestContext: codeunit "Blob Service API Test Context";
        BlobServiceTestLibrary: Codeunit "Blob Service Test Library";
}