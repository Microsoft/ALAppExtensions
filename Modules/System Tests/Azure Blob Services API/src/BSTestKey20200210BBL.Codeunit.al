/// <summary>
/// Tests for BlockBlob-level API operations
/// Version: 2020-02-10
/// Authentication: Shared Key
/// </summary>
codeunit 88153 "B. S. Test Key 2020-02-10 BBL"
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
    procedure GetBlobBlockBlobText()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Get text from a block blob
        BlobServiceTestLibrary.GetBlobBlockBlobText(TestContext);
    end;

    [Test]
    procedure PutBlockUncommited()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Put Block Uncommited
        BlobServiceTestLibrary.PutBlockUncommited(TestContext);
    end;

    [Test]
    procedure GetBlockList()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Get Block List
        BlobServiceTestLibrary.GetBlockList(TestContext);
    end;

    [Test]
    procedure PutBlockList()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Put Block List
        BlobServiceTestLibrary.PutBlockList(TestContext);
    end;

    [Test]
    procedure QueryBlobContents()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Query Blob Contents
        BlobServiceTestLibrary.QueryBlobContents(TestContext);
    end;

    var
        TestContext: codeunit "Blob Service API Test Context";
        BlobServiceTestLibrary: Codeunit "Blob Service Test Library";
}