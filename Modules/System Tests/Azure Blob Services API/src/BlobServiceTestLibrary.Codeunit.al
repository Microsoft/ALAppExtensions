codeunit 88154 "Blob Service Test Library"
{
    Access = Internal;

    procedure ClearStorageAccount(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        Container: Record "Container";
        OperationPayload: Codeunit "Blob API Operation Payload";
    begin
        // [SCENARIO] This is a helper; it'll remove all containters from the Storage Account (assumes that some other functions are working)
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload);
        OperationResponse := BlobServicesAPI.ListContainers(OperationPayload, Container);

        if not Container.Find('-') then
            exit;

        repeat
            OperationPayload.SetContainerName(Container.Name);
            OperationResponse := BlobServicesAPI.DeleteContainer(OperationPayload);
            Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Cleanup / Delete Container', OperationResponse.GetHttpResponseStatusCode()));
        until Container.Next() = 0;
    end;

    procedure CreateContainer(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        ContainerName: Text;
    begin
        // [SCENARIO] A new containter is created in the Storage Account

        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure ListContainers(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        Container: Record "Container";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerNames: List of [Text];
        ContainerName: Text;
        Count1: Integer;
        Count2: Integer;
    begin
        // [SCENARIO] Existing containters are listed from the Storage Account

        // [GIVEN] A list of Container Names
        HelperLibrary.GetListOfContainerNames(ContainerNames);

        // [GIVEN] A Storage Account exists
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload);

        // [THEN] Create the Containers in the Storage Account
        foreach ContainerName in ContainerNames do begin
            OperationPayload.SetContainerName(ContainerName);
            OperationResponse := BlobServicesAPI.CreateContainer(OperationPayload);
            Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Create Container', OperationResponse.GetHttpResponseStatusCode()));
        end;

        // [THEN] List the Containers in the Storage Account
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload);
        OperationResponse := BlobServicesAPI.ListContainers(OperationPayload, Container);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'List Container', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Compare number of returned containers with number of expected containers
        Count1 := Container.Count();
        Count2 := ContainerNames.Count();
        Assert.AreEqual(Count1, Count2, 'Number of returned Containers does not match the ones created.');

        // [THEN] Cleanup / Delete the Containers from the Storage Account
        foreach ContainerName in ContainerNames do begin
            OperationPayload.SetContainerName(ContainerName);
            OperationResponse := BlobServicesAPI.DeleteContainer(OperationPayload);
            Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Cleanup / Delete Container', OperationResponse.GetHttpResponseStatusCode()));
        end;
    end;

    procedure GetBlobServiceProperties(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        Document: XmlDocument;
    begin
        // [SCENARIO] Get Blob Service Properties

        // [GIVEN] A Storage Account exists
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload);

        // [THEN] Retrieve properties via GetBlobServiceProperties
        OperationResponse := BlobServicesAPI.GetBlobServiceProperties(OperationPayload, Document);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Get Blob Service Properties', OperationResponse.GetHttpResponseStatusCode()));
        Assert.IsTrue(StrPos(Format(Document), 'StorageServiceProperties') > 0, StrSubstNo(OperationFailedErr, 'Get Blob Service Properties', OperationResponse.GetHttpResponseStatusCode()));
    end;

    procedure SetBlobServiceProperties(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        Document: XmlDocument;
    begin
        // [SCENARIO] Set Blob Service Properties

        // [GIVEN] A Storage Account exists
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload);

        // [GIVEN] Default properties
        Document := HelperLibrary.GetDefaultBlobServiceProperties(false);

        // [THEN] Set properties (unchanged)
        OperationResponse := BlobServicesAPI.SetBlobServiceProperties(OperationPayload, Document);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Blob Service Properties', OperationResponse.GetHttpResponseStatusCode()));
    end;

    procedure PreflightBlobRequest(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        Document: XmlDocument;
        AccessControlRequestMethod: Enum "Http Request Type";
    begin

        // [SCENARIO] Preflight Blob Request

        // [GIVEN] A Storage Account exists        
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload);

        // [THEN] Set properties (CORS)
        Document := HelperLibrary.GetDefaultBlobServiceProperties(true);

        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload);

        OperationResponse := BlobServicesAPI.SetBlobServiceProperties(OperationPayload, Document);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Blob Service Properties (CORS)', OperationResponse.GetHttpResponseStatusCode()));

        // In the emulator the change is immeadiate, but on a real account it takes up to 60 seconds to be applied
        if OperationPayload.GetStorageAccountName() <> 'devstoreaccount1' then
            Sleep(1000 * 60);

        // [THEN] Test with updated settings
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload);

        OperationResponse := BlobServicesAPI.PreflightBlobRequest(OperationPayload, '127.0.0.1', enum::"Http Request Type"::PUT);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Preflight Blob Request (CORS)', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Set back to defaults
        Document := HelperLibrary.GetDefaultBlobServiceProperties(false);

        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload);

        OperationResponse := BlobServicesAPI.SetBlobServiceProperties(OperationPayload, Document);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Blob Service Properties', OperationResponse.GetHttpResponseStatusCode()));
    end;

    procedure GetBlobServiceStats(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        Document: XmlDocument;
    begin
        // [SCENARIO] Get Blob Service Stats

        // [GIVEN] A Storage Account exists
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload);

        OperationResponse := BlobServicesAPI.GetBlobServiceStats(OperationPayload, Document);

        Assert.IsTrue(StrPos(Format(Document), 'StorageServiceStats') > 0, StrSubstNo(OperationFailedErr, 'Get Blob Service Stats', OperationResponse.GetHttpResponseStatusCode()));
    end;

    procedure GetAccountInformation(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        AccountInformationHeaders: HttpHeaders;
        ReturnValue: Text;
    begin
        // [SCENARIO] Get Account Information

        // [GIVEN] A Storage Account exists
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload);

        OperationResponse := BlobServicesAPI.GetAccountInformation(OperationPayload, AccountInformationHeaders);
        ReturnValue := OperationResponse.GetSkuNameFromResponseHeaders();
        Assert.IsTrue(StrLen(ReturnValue) > 0, StrSubstNo(OperationFailedErr, 'Get Account Information', OperationResponse.GetHttpResponseStatusCode()));
        ReturnValue := OperationResponse.GetAccountKindFromResponseHeaders();
        Assert.IsTrue(StrLen(ReturnValue) > 0, StrSubstNo(OperationFailedErr, 'Get Account Information', OperationResponse.GetHttpResponseStatusCode()));
    end;

    procedure GetUserDelegationKeyExpectedError(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        StartDateTime: DateTime;
        ExpiryDateTime: DateTime;
        ReturnValue: Text;
    begin
        // [SCENARIO] Get User Delegation Key
        // As of today (2021-04-05) this is not implemented yet in Azurite; only test against real Storage Account

        // [GIVEN] A Storage Account exists
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload);

        StartDateTime := CurrentDateTime();
        ExpiryDateTime := CurrentDateTime() + 60000;
        OperationResponse := BlobServicesAPI.GetUserDelegationKey(OperationPayload, ExpiryDateTime, StartDateTime, ReturnValue);
        Assert.AreEqual(GetLastErrorText, 'Only works with Azure AD authentication, which is not implemented yet', 'Not as expected');
    end;

    procedure GetContainerProperties(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        ReturnValue: Text;
        PropertyHeaders: HttpHeaders;
    begin
        // [SCENARIO] Get Container Properties

        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [THEN] Get Container Properties
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);

        OperationResponse := BlobServicesAPI.GetContainerProperties(OperationPayload, PropertyHeaders);
        ReturnValue := OperationResponse.GetLeaseStateFromResponseHeaders(OperationPayload);
        Assert.AreEqual(ReturnValue.ToLower(), 'available', StrSubstNo(OperationFailedErr, 'Get Container Properties', OperationResponse.GetHttpResponseStatusCode()));
        // TODO: maybe check more properties from the result

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure SetContainerMetadata(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
    begin
        // [SCENARIO] Set Container Metadata

        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [THEN] Set Container Metadata
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);

        BlobAPIValueHelper.SetMetadataNameValueHeader(OperationPayload, 'Dummy01', 'DummyValue01');
        BlobAPIValueHelper.SetMetadataNameValueHeader(OperationPayload, 'Dummy02', 'DummyValue02');
        OperationResponse := BlobServicesAPI.SetContainerMetadata(OperationPayload);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Container Metadata', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure GetContainerMetadata(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        ReturnValue: Text;
        MetadataHeaders: HttpHeaders;
    begin
        // [SCENARIO] Get Container Metadata

        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [THEN] Set Container Metadata
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);

        BlobAPIValueHelper.SetMetadataNameValueHeader(OperationPayload, 'Dummy01', 'DummyValue01');
        BlobAPIValueHelper.SetMetadataNameValueHeader(OperationPayload, 'Dummy02', 'DummyValue02');
        OperationResponse := BlobServicesAPI.SetContainerMetadata(OperationPayload);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Container Metadata', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Get Container Metadata
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);

        OperationResponse := BlobServicesAPI.GetContainerMetadata(OperationPayload, MetadataHeaders);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Get Container Metadata', OperationResponse.GetHttpResponseStatusCode()));
        ReturnValue := OperationResponse.GetMetaValueFromResponseHeaders('Dummy01');
        Assert.AreEqual(ReturnValue, 'DummyValue01', StrSubstNo(OperationFailedErr, 'Get Container Metadata', OperationResponse.GetHttpResponseStatusCode()));
        ReturnValue := OperationResponse.GetMetaValueFromResponseHeaders('Dummy02');
        Assert.AreEqual(ReturnValue, 'DummyValue02', StrSubstNo(OperationFailedErr, 'Get Container Metadata', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure GetContainerACL(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        Document: XmlDocument;
    begin
        // [SCENARIO] Get Container ACL

        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [THEN] Get Container ACL
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);

        OperationResponse := BlobServicesAPI.GetContainerACL(OperationPayload, Document);
        Assert.IsTrue(StrPos(Format(Document), 'SignedIdentifiers') > 0, StrSubstNo(OperationFailedErr, 'Get Container ACL', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure SetContainerACL(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        Document1: XmlDocument;
        Document2: XmlDocument;
    begin
        // [SCENARIO] Set Container ACL

        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [THEN] Set Container ACL
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);

        Document1 := HelperLibrary.GetSampleContainerACL();
        OperationResponse := BlobServicesAPI.SetContainerACL(OperationPayload, Document1);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Container ACL', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Get Container ACL
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);

        OperationResponse := BlobServicesAPI.GetContainerACL(OperationPayload, Document2);
        Assert.IsTrue(StrPos(Format(Document2), 'SignedIdentifiers') > 0, StrSubstNo(OperationFailedErr, 'Get Container ACL', OperationResponse.GetHttpResponseStatusCode()));
        Assert.IsTrue(StrPos(Format(Document2), '<Start>2020-09-28T08:49:37.0000000Z</Start>') > 0, StrSubstNo(OperationFailedErr, 'Get Container ACL', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure LeaseContainerAcquireAndRelease(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        LeaseId: Guid;
        EmptyGuid: Guid;

    begin
        // [SCENARIO] Acquire a lease for a container
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [THEN] Acquire Lease
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);
        OperationResponse := BlobServicesAPI.ContainerLeaseAcquire(OperationPayload, 60, LeaseId);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Acquire Lease', OperationResponse.GetHttpResponseStatusCode()));
        Assert.AreNotEqual(LeaseId, EmptyGuid, StrSubstNo(OperationFailedErr, 'Acquire Lease', OperationResponse.GetHttpResponseStatusCode()));

        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);
        OperationResponse := BlobServicesAPI.ContainerLeaseRelease(OperationPayload, LeaseId);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Release Lease', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure DeleteContainerWithoutLease(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        ContainerName: Text;
    begin
        // [SCENARIO] An existing containter is deleted from the Storage Account

        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure DeleteContainerWithLease(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        LeaseId: Guid;
        EmptyGuid: Guid;

    begin
        // [SCENARIO] Delete a leased container
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [THEN] Acquire Lease
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);
        OperationResponse := BlobServicesAPI.ContainerLeaseAcquire(OperationPayload, 60, LeaseId);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Acquire Lease', OperationResponse.GetHttpResponseStatusCode()));
        Assert.AreNotEqual(LeaseId, EmptyGuid, StrSubstNo(OperationFailedErr, 'Acquire Lease', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName, LeaseId);
    end;

    procedure ListBlobs(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        ContainerContent: Record "Container Content";

        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
        BlobNames: List of [Text];
    begin
        // [SCENARIO] List Blob from a container
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        HelperLibrary.GetListOfBlobNames(BlobNames);
        // [THEN] Upload some BlockBlobs to the Container
        foreach BlobName in BlobNames do
            PutBlockBlobTextImpl(TestContext, ContainerName, BlobName);

        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);
        OperationResponse := BlobServicesAPI.ListBlobs(OperationPayload, ContainerContent);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'List Blobs', OperationResponse.GetHttpResponseStatusCode()));
        Assert.AreEqual(ContainerContent.Count(), BlobNames.Count, 'Number of returned Blobs does not match the ones created.');

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure SetBlobProperties(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
    begin
        // [SCENARIO] Get a blob from a container
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Set blob properties
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationPayload.AddOptionalHeader('x-ms-blob-content-type', 'text/plain; charset=UTF-16');
        OperationResponse := BlobServicesAPI.SetBlobProperties(OperationPayload);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set blob properties', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure GetBlobProperties(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
        ReturnValue: Text;
    begin
        // [SCENARIO] Get a blob from a container
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Get blob properties
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.GetBlobProperties(OperationPayload);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Get blob properties', OperationResponse.GetHttpResponseStatusCode()));

        ReturnValue := OperationResponse.GetHeaderValueFromResponseHeaders('x-ms-blob-type');
        Assert.AreEqual(ReturnValue, 'BlockBlob', 'Return Value not as expected');

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure SetBlobMetadata(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
    begin
        // [SCENARIO] Set blob metadata
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Set blob metadata
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        BlobAPIValueHelper.SetMetadataNameValueHeader(OperationPayload, 'Dummy01', 'DummyValue01');
        BlobAPIValueHelper.SetMetadataNameValueHeader(OperationPayload, 'Dummy02', 'DummyValue02');
        OperationResponse := BlobServicesAPI.SetBlobMetadata(OperationPayload);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Blob Metadata', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure GetBlobMetadata(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
        ReturnValue: Text;
    begin
        // [SCENARIO] Get blob metadata
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Set blob metadata
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);

        BlobAPIValueHelper.SetMetadataNameValueHeader(OperationPayload, 'Dummy01', 'DummyValue01');
        BlobAPIValueHelper.SetMetadataNameValueHeader(OperationPayload, 'Dummy02', 'DummyValue02');
        OperationResponse := BlobServicesAPI.SetBlobMetadata(OperationPayload);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Blob Metadata', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Get blob Metadata
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);

        OperationResponse := BlobServicesAPI.GetBlobMetadata(OperationPayload);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Get blob Metadata', OperationResponse.GetHttpResponseStatusCode()));
        ReturnValue := OperationResponse.GetMetaValueFromResponseHeaders('Dummy01');
        Assert.AreEqual(ReturnValue, 'DummyValue01', StrSubstNo(OperationFailedErr, 'Get blob Metadata', OperationResponse.GetHttpResponseStatusCode()));
        ReturnValue := OperationResponse.GetMetaValueFromResponseHeaders('Dummy02');
        Assert.AreEqual(ReturnValue, 'DummyValue02', StrSubstNo(OperationFailedErr, 'Get blob Metadata', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure SetBlobTags(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
        Tags: Dictionary of [Text, Text];
    begin
        // Does not work in Azurite-emulator

        // [SCENARIO] Set blob tags
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Set blob tags
        Tags.Add('Dummy01', 'DummyValue01');
        Tags.Add('Dummy02', 'DummyValue02');
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);

        OperationResponse := BlobServicesAPI.SetBlobTags(OperationPayload, Tags);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Blob Tags', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure GetBlobTags(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
        Document: XmlDocument;
        Tags: Dictionary of [Text, Text];
    begin
        // Does not work in Azurite-emulator

        // [SCENARIO] Set blob tags
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Set blob tags
        Tags.Add('Dummy01', 'DummyValue01');
        Tags.Add('Dummy02', 'DummyValue02');
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);

        OperationResponse := BlobServicesAPI.SetBlobTags(OperationPayload, Tags);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Blob Tags', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Get blob tags        
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);

        OperationResponse := BlobServicesAPI.GetBlobTags(OperationPayload, Document);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Get Blob Tags', OperationResponse.GetHttpResponseStatusCode()));
        Assert.AreEqual(StrPos(Format(Document), 'DummyValue01') > 0, true, 'Return Value not as expected');
        Assert.AreEqual(StrPos(Format(Document), 'DummyValue02') > 0, true, 'Return Value not as expected');

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure FindBlobsByTags(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
        Document: XmlDocument;
        Tags: Dictionary of [Text, Text];
    begin
        // Does not work in Azurite-emulator

        // [SCENARIO] Set blob tags
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] Multiple blobs with tags
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Set blob tags
        Tags.Add('Dummy01', 'DummyValue01');
        Tags.Add('Dummy02', 'DummyValue02');
        Tags.Add('Dummy03', 'DummyValue03');
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);

        OperationResponse := BlobServicesAPI.SetBlobTags(OperationPayload, Tags);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Blob Tags', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Set blob tags
        Clear(Tags);
        Tags.Add('Dummy01', 'DummyValue01');
        Tags.Add('Dummy02', 'DummyValue02');
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);

        OperationResponse := BlobServicesAPI.SetBlobTags(OperationPayload, Tags);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Blob Tags', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Set blob tags
        Clear(Tags);
        Tags.Add('Dummy02', 'DummyValue02');
        Tags.Add('Dummy03', 'DummyValue03');
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);

        OperationResponse := BlobServicesAPI.SetBlobTags(OperationPayload, Tags);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Set Blob Tags', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Find Blobs by Tags
        Clear(Tags);
        Tags.Add('Dummy02', '= DummyValue02');
        Tags.Add('Dummy03', '= DummyValue03');
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);

        OperationResponse := BlobServicesAPI.FindBlobsByTags(OperationPayload, Tags, Document);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Find Blobs by Tags', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure DeleteBlobWithoutLease(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
    begin
        // [SCENARIO] Set blob tags
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Delete blob
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.DeleteBlob(OperationPayload);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Delete Blob', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure DeleteBlobWithLease(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
        LeaseId: Guid;
        EmptyGuid: Guid;
    begin
        // [SCENARIO] Set blob tags
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Acquire Lease
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.BlobLeaseAcquire(OperationPayload, 60, LeaseId);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Acquire Lease', OperationResponse.GetHttpResponseStatusCode()));
        Assert.AreNotEqual(LeaseId, EmptyGuid, StrSubstNo(OperationFailedErr, 'Acquire Lease', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Delete blob
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        BlobAPIValueHelper.SetLeaseIdHeader(OperationPayload, LeaseId);
        OperationResponse := BlobServicesAPI.DeleteBlob(OperationPayload);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Delete Blob', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure UndeleteBlob(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
    begin
        // Does not work in Azurite-emulator

        // [SCENARIO] Set blob tags
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Delete blob
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.DeleteBlob(OperationPayload);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Delete Blob', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Undelete blob
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.UndeleteBlob(OperationPayload);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Undelete Blob', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure LeaseBlobAcquireAndRelease(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        LeaseId: Guid;
        EmptyGuid: Guid;
        BlobName: Text;
    begin
        // [SCENARIO] Acquire a lease for a container
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [THEN] Upload a BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Acquire Lease
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.BlobLeaseAcquire(OperationPayload, 60, LeaseId);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Acquire Lease', OperationResponse.GetHttpResponseStatusCode()));
        Assert.AreNotEqual(LeaseId, EmptyGuid, StrSubstNo(OperationFailedErr, 'Acquire Lease', OperationResponse.GetHttpResponseStatusCode()));

        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.BlobLeaseRelease(OperationPayload, LeaseId);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Release Lease', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure SnapshotBlob(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
    begin
        // [SCENARIO] Snapshot Blob
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Snapshot blob
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.SnapshotBlob(OperationPayload);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Snapshot Blob', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure CopyBlob(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        OperationPayload2: Codeunit "Blob API Operation Payload";
        Operation: Enum "Blob Service API Operation";
        ContainerName: Text;
        ContainerName2: Text;
        BlobName: Text;
        BlobName2: Text;
        SourceName: Text;
    begin
        // [SCENARIO] Copy Blob
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);
        ContainerName2 := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);
        BlobName2 := HelperLibrary.GetBlobName();

        // [THEN] Copy blob        
        // Prepare "source" operation object (for URI generation)
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationPayload.SetOperation(Operation::GetBlob);
        SourceName := OperationPayload.ConstructUri();

        // Call Copy Blob
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload2, ContainerName2, BlobName2);

        OperationResponse := BlobServicesAPI.CopyBlob(OperationPayload2, SourceName);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Copy Blob', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure CopyBlobFromUrl(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        OperationPayload2: Codeunit "Blob API Operation Payload";
        Operation: Enum "Blob Service API Operation";
        ContainerName: Text;
        ContainerName2: Text;
        BlobName: Text;
        BlobName2: Text;
    begin
        // [SCENARIO] Copy Blob from URL
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);
        ContainerName2 := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);
        BlobName2 := HelperLibrary.GetBlobName();

        // [THEN] Copy blob        
        // Prepare "source" operation object (for URI generation)
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationPayload.SetOperation(Operation::GetBlob);

        // Call Copy Blob
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload2, ContainerName2, BlobName2);

        OperationResponse := BlobServicesAPI.CopyBlob(OperationPayload2, OperationPayload.ConstructUri());

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Copy Blob from URL', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure GetBlobBlockBlobText(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
        BlobName: Text;
        TargetText: Text;
    begin
        // [SCENARIO] Get a blob from a container
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        // [THEN] Upload BlockBlob to the Container
        BlobName := PutBlockBlobTextImpl(TestContext, ContainerName);

        // [THEN] Get blob from Container
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.GetBlobAsText(OperationPayload, TargetText);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Get Blob', OperationResponse.GetHttpResponseStatusCode()));
        Assert.AreEqual(HelperLibrary.GetSampleTextBlobContent(), TargetText, 'Content is not identical.');

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure PutBlockUncommited(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        FormatHelper: Codeunit "Blob API Format Helper";
        ContainerName: Text;
        BlobName: Text;
        BlobContent: Text;
        BlockID: Text;
    begin
        // [SCENARIO] Put Block Uncommited
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        BlobName := HelperLibrary.GetBlobName();

        // [GIVEN] Sample Content
        BlobContent := HelperLibrary.GetSampleTextBlobContent();

        // [GIVEN] A BlockId (Base64-Guid)
        BlockID := FormatHelper.GetBase64BlockId();

        // [THEN] Put Block
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.PutBlock(OperationPayload, BlobContent);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Put Block', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure GetBlockList(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        FormatHelper: Codeunit "Blob API Format Helper";
        ContainerName: Text;
        BlobName: Text;
        BlobContent: Text;
        BlockID: Text;
        BlockID2: Text;
        BlockListType: Enum "Block List Type";
        CommitedBlocks: Dictionary of [Text, Integer];
        UncommitedBlocks: Dictionary of [Text, Integer];
    begin
        // [SCENARIO] Get Block List
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        BlobName := HelperLibrary.GetBlobName();

        // [GIVEN] Sample Content
        BlobContent := HelperLibrary.GetSampleTextBlobContent();

        // [GIVEN] A BlockId (Base64-Guid)
        BlockID := FormatHelper.GetBase64BlockId();
        BlockID2 := FormatHelper.GetBase64BlockId();

        // [THEN] Put Block
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.PutBlock(OperationPayload, BlobContent, BlockID);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Put Block', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Put another Block
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.PutBlock(OperationPayload, BlobContent, BlockID2);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Put Block', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Get Block List
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.GetBlockList(OperationPayload, BlockListType::all, CommitedBlocks, UncommitedBlocks);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Get Block List', OperationResponse.GetHttpResponseStatusCode()));
        Assert.AreEqual(UncommitedBlocks.Count(), 2, 'Number of returned Blocks does not match the ones created.');
        Assert.AreEqual(UncommitedBlocks.ContainsKey(BlockID), true, 'Return value not as expected');
        Assert.AreEqual(UncommitedBlocks.ContainsKey(BlockID2), true, 'Return value not as expected');

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure PutBlockList(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        FormatHelper: Codeunit "Blob API Format Helper";
        ContainerName: Text;
        BlobName: Text;
        BlobContent: Text;
        BlockID: Text;
        BlockID2: Text;
        BlockListType: Enum "Block List Type";
        CommitedBlocks: Dictionary of [Text, Integer];
        UncommitedBlocks: Dictionary of [Text, Integer];
    begin
        // [SCENARIO] Put Block List
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        BlobName := HelperLibrary.GetBlobName();

        // [GIVEN] Sample Content
        BlobContent := HelperLibrary.GetSampleTextBlobContent();

        // [GIVEN] A BlockId (Base64-Guid)
        BlockID := FormatHelper.GetBase64BlockId();
        BlockID2 := FormatHelper.GetBase64BlockId();

        // [THEN] Put Block
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.PutBlock(OperationPayload, BlobContent, BlockID);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Put Block', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Put another Block
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.PutBlock(OperationPayload, BlobContent, BlockID2);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Put Block', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Get Block List
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.GetBlockList(OperationPayload, BlockListType::all, CommitedBlocks, UncommitedBlocks);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Get Block List', OperationResponse.GetHttpResponseStatusCode()));
        Assert.AreEqual(UncommitedBlocks.Count(), 2, 'Number of returned Blocks does not match the ones created.');
        Assert.AreEqual(UncommitedBlocks.ContainsKey(BlockID), true, 'Return value not as expected');
        Assert.AreEqual(UncommitedBlocks.ContainsKey(BlockID2), true, 'Return value not as expected');

        // [THEN] Put Block List
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.PutBlockList(OperationPayload, CommitedBlocks, UncommitedBlocks);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Put Block List', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Get Block List for validation
        Clear(OperationPayload);
        Clear(CommitedBlocks);
        Clear(UncommitedBlocks);
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.GetBlockList(OperationPayload, BlockListType::all, CommitedBlocks, UncommitedBlocks);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Get Block List', OperationResponse.GetHttpResponseStatusCode()));
        Assert.AreEqual(CommitedBlocks.Count(), 2, 'Number of returned Blocks does not match the ones created.');
        Assert.AreEqual(UncommitedBlocks.Count(), 0, 'Number of returned Blocks does not match the ones created.');
        Assert.AreEqual(UncommitedBlocks.ContainsKey(BlockID), false, 'Return value not as expected');
        Assert.AreEqual(UncommitedBlocks.ContainsKey(BlockID2), false, 'Return value not as expected');
        Assert.AreEqual(CommitedBlocks.ContainsKey(BlockID), true, 'Return value not as expected');
        Assert.AreEqual(CommitedBlocks.ContainsKey(BlockID2), true, 'Return value not as expected');

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;

    procedure QueryBlobContents(TestContext: Codeunit "Blob Service API Test Context")
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        FormatHelper: Codeunit "Blob API Format Helper";
        ApiVersion: Enum "Storage Service API Version";
        ContainerName: Text;
        BlobName: Text;
        BlobContent: Text;
        BlockID: Text;
        BlockID2: Text;
        BlockListType: Enum "Block List Type";
        CommitedBlocks: Dictionary of [Text, Integer];
        UncommitedBlocks: Dictionary of [Text, Integer];
        Result: InStream;
        SearchExpression: Text;
    begin
        // Does not work in Azurite-emulator

        // [SCENARIO] Put Block List
        // [GIVEN] A Storage Account exists
        // [GIVEN] A Container Name
        // [THEN] Create the Container in the Storage Account
        ContainerName := CreateContainerImpl(TestContext);

        // [GIVEN] A Blob Name
        BlobName := HelperLibrary.GetBlobName();

        // [GIVEN] Sample Content
        BlobContent := HelperLibrary.GetSampleTextBlobContent();

        // [GIVEN] A BlockId (Base64-Guid)
        BlockID := FormatHelper.GetBase64BlockId();
        BlockID2 := FormatHelper.GetBase64BlockId();

        // [THEN] Put Block
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.PutBlock(OperationPayload, BlobContent, BlockID);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Put Block', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Put another Block
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.PutBlock(OperationPayload, BlobContent, BlockID2);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Put Block', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Get Block List
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.GetBlockList(OperationPayload, BlockListType::all, CommitedBlocks, UncommitedBlocks);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Get Block List', OperationResponse.GetHttpResponseStatusCode()));
        Assert.AreEqual(UncommitedBlocks.Count(), 2, 'Number of returned Blocks does not match the ones created.');
        Assert.AreEqual(UncommitedBlocks.ContainsKey(BlockID), true, 'Return value not as expected');
        Assert.AreEqual(UncommitedBlocks.ContainsKey(BlockID2), true, 'Return value not as expected');

        // [THEN] Put Block List
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.PutBlockList(OperationPayload, CommitedBlocks, UncommitedBlocks);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Put Block List', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Get Block List for validation
        Clear(OperationPayload);
        Clear(CommitedBlocks);
        Clear(UncommitedBlocks);
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationResponse := BlobServicesAPI.GetBlockList(OperationPayload, BlockListType::all, CommitedBlocks, UncommitedBlocks);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Get Block List', OperationResponse.GetHttpResponseStatusCode()));
        Assert.AreEqual(CommitedBlocks.Count(), 2, 'Number of returned Blocks does not match the ones created.');
        Assert.AreEqual(UncommitedBlocks.Count(), 0, 'Number of returned Blocks does not match the ones created.');
        Assert.AreEqual(UncommitedBlocks.ContainsKey(BlockID), false, 'Return value not as expected');
        Assert.AreEqual(UncommitedBlocks.ContainsKey(BlockID2), false, 'Return value not as expected');
        Assert.AreEqual(CommitedBlocks.ContainsKey(BlockID), true, 'Return value not as expected');
        Assert.AreEqual(CommitedBlocks.ContainsKey(BlockID2), true, 'Return value not as expected');

        // [THEN] Query Blob Contents
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        OperationPayload.SetApiVersion(ApiVersion::"2020-02-10");
        SearchExpression := 'SELECT * FROM BlobStorage';
        OperationResponse := BlobServicesAPI.QueryBlobContents(OperationPayload, SearchExpression, Result);

        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Query Blob Contents', OperationResponse.GetHttpResponseStatusCode()));

        // [THEN] Cleanup / Delete the Container from the Storage Account
        DeleteContainerImpl(TestContext, ContainerName);
    end;
    // TODO: Check that there is no manual ApiVersion setting in this codeunit

    procedure CreateContainerImpl(TestContext: Codeunit "Blob Service API Test Context"): Text
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        ContainerName: Text;
    begin
        // [GIVEN] A Container Name
        ContainerName := HelperLibrary.GetContainerName();

        // [GIVEN] A Storage Account exists
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);

        // [THEN] Create the Container in the Storage Account
        OperationResponse := BlobServicesAPI.CreateContainer(OperationPayload);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Create Container', OperationResponse.GetHttpResponseStatusCode()));
        exit(ContainerName);
    end;

    procedure DeleteContainerImpl(TestContext: Codeunit "Blob Service API Test Context"; ContainerName: Text)
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
    begin
        // [THEN] Cleanup / Delete the Container from the Storage Account
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);

        OperationResponse := BlobServicesAPI.DeleteContainer(OperationPayload);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Cleanup / Delete Container', OperationResponse.GetHttpResponseStatusCode()));
    end;

    procedure DeleteContainerImpl(TestContext: Codeunit "Blob Service API Test Context"; ContainerName: Text; LeaseId: Guid)
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
    begin
        // [THEN] Cleanup / Delete the Container from the Storage Account
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName);

        BlobAPIValueHelper.SetLeaseIdHeader(OperationPayload, LeaseId);
        OperationResponse := BlobServicesAPI.DeleteContainer(OperationPayload);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Cleanup / Delete Container', OperationResponse.GetHttpResponseStatusCode()));
    end;

    procedure PutBlockBlobTextImpl(TestContext: Codeunit "Blob Service API Test Context"; ContainerName: Text): Text
    var
        BlobName: Text;
    begin
        BlobName := HelperLibrary.GetBlobName();
        PutBlockBlobTextImpl(TestContext, ContainerName, BlobName);
        exit(BlobName);
    end;

    procedure PutBlockBlobTextImpl(TestContext: Codeunit "Blob Service API Test Context"; ContainerName: Text; BlobName: Text)
    var
        OperationResponse: Codeunit "Blob API Operation Response";
        OperationPayload: Codeunit "Blob API Operation Payload";
        SampleContent: Text;
    begin
        HelperLibrary.InitializeRequestFromContext(TestContext, OperationPayload, ContainerName, BlobName);
        SampleContent := HelperLibrary.GetSampleTextBlobContent();
        OperationResponse := BlobServicesAPI.PutBlobBlockBlobText(OperationPayload, BlobName, SampleContent);
        Assert.AreEqual(OperationResponse.GetHttpResponseIsSuccessStatusCode(), true, StrSubstNo(OperationFailedErr, 'Put Blob', OperationResponse.GetHttpResponseStatusCode()));
    end;

    var
        BlobServicesAPI: Codeunit "Blob Services API";
        BlobAPIValueHelper: Codeunit "Blob API Value Helper";
        Assert: Codeunit "Library Assert";
        HelperLibrary: Codeunit "Blob Service API Test Help Lib";
        OperationFailedErr: Label 'Operation "%1" failed. Status Code: %2', Comment = '%1 = Operation, %2 = Status Code';
}