/// <summary>
/// Tests for Account-level API operations
/// Version: 2020-02-10
/// Authentication: Shared Key
/// </summary>
codeunit 88156 "B. S. Test Key 2020-02-10 AL"
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
    procedure TestDateConversion()
    var
        SourceString: Text;
        TargetDate: DateTime;
        CompareDate: DateTime;
    begin
        CompareDate := CreateDateTime(DMY2Date(24, 5, 2021), 142527T);
        SourceString := 'Mon, 24 May 2021 12:25:27 GMT';
        Evaluate(TargetDate, SourceString);
        Assert.AreEqual(TargetDate, CompareDate, 'Dates are not equal');
    end;

    [Test]
    procedure ListContainers()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Existing containters are listed from the Storage Account
        BlobServiceTestLibrary.ListContainers(TestContext);
    end;

    [Test]
    procedure GetBlobServiceProperties()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Get Blob Service Properties
        BlobServiceTestLibrary.GetBlobServiceProperties(TestContext);
    end;

    [Test]
    procedure SetBlobServiceProperties()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Set Blob Service Properties
        BlobServiceTestLibrary.SetBlobServiceProperties(TestContext);
    end;

    [Test]
    procedure PreflightBlobRequest()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Preflight Blob Request
        BlobServiceTestLibrary.PreflightBlobRequest(TestContext);
    end;

    [Test]
    procedure GetBlobServiceStats()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Get Blob Service Stats
        BlobServiceTestLibrary.GetBlobServiceStats(TestContext);
    end;

    [Test]
    procedure GetAccountInformation()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Get Account Information
        BlobServiceTestLibrary.GetAccountInformation(TestContext);
    end;

    [Test]
    procedure GetUserDelegationKeyExpectedError()
    begin
        TestContext.InitializeContextSharedKeyVersion20200210();

        // [SCENARIO] Get User Delegation Key
        asserterror BlobServiceTestLibrary.GetUserDelegationKeyExpectedError(TestContext);
        Assert.AreEqual(GetLastErrorText, 'Only works with Azure AD authentication, which is not implemented yet', 'Not as expected');
    end;

    var
        TestContext: codeunit "Blob Service API Test Context";
        BlobServiceTestLibrary: Codeunit "Blob Service Test Library";
        Assert: Codeunit "Library Assert";
}