codeunit 87150 "Auth. Helper Tests"
{
    Subtype = Test;
    trigger OnRun()
    begin

    end;

    [Test]
    procedure CalculateFullAccessSharedAccessSignatureVersion20200210()
    var
        StorageServAuthSAS: Codeunit "Storage Serv. Auth. SAS";
        DotNetDateTime: DotNet DateTime;
        DotNet_DateTimeKind: DotNet DateTimeKind;
        ResultFromAzurePortal: Text;
        ResultFromTest: Text;
        StartDate: DateTime;
        ExpiryDate: DateTime;
        ApiVersion: Enum "Storage Service API Version";
        ServiceType: Enum "Storage Service Type";
        ResourceType: Enum "Storage Service Resource Type";
        Permission: Enum "Storage Service Permission";
    begin
        // [SCENARIO] Generate a Shared Access Signature

        // [GIVEN] Known parameters and result from a manual generation in Azure Portal (for validation)
        ResultFromAzurePortal := '?sv=2020-02-10&ss=bfqt&srt=sco&sp=rwdlacuptfx&se=2021-04-03T21:00:00Z&st=2021-04-03T08:00:00Z&spr=https,http&sig=u6nNFZU%2BgAMu4ryx00Y7CKehsJPCr4wK5EwuYOCeY34%3D';

        DotNet_DateTimeKind := DotNet_DateTimeKind.Utc;
        DotNetDateTime := DotNetDateTime.DateTime(2021, 04, 03, 08, 00, 00, DotNet_DateTimeKind);
        StartDate := DotNetDateTime;
        DotNetDateTime := DotNetDateTime.DateTime(2021, 04, 03, 21, 00, 00, DotNet_DateTimeKind);
        ExpiryDate := DotNetDateTime;

        StorageServAuthSAS.SetVersion(ApiVersion::"2020-02-10");
        StorageServAuthSAS.SetAccountName('sasgeneratortest');
        StorageServAuthSAS.SetSigningKey('SYeXHtTn/5xbKGsccP5Pvu5qDVb2xSHh11MUtD7UEsj5esRkVvWfk1f1S/fdS7uB9onWkQ0Netqjn3u6VubjOQ==');
        StorageServAuthSAS.SetDatePeriod(StartDate, ExpiryDate);
        StorageServAuthSAS.AddService(ServiceType::Blob);
        StorageServAuthSAS.AddService(ServiceType::File);
        StorageServAuthSAS.AddService(ServiceType::Queue);
        StorageServAuthSAS.AddService(ServiceType::Table);
        StorageServAuthSAS.AddResource(ResourceType::Service);
        StorageServAuthSAS.AddResource(ResourceType::Container);
        StorageServAuthSAS.AddResource(ResourceType::Object);
        StorageServAuthSAS.AddPermission(Permission::Read);
        StorageServAuthSAS.AddPermission(Permission::Write);
        StorageServAuthSAS.AddPermission(Permission::Delete);
        StorageServAuthSAS.AddPermission(Permission::List);
        StorageServAuthSAS.AddPermission(Permission::Add);
        StorageServAuthSAS.AddPermission(Permission::Create);
        StorageServAuthSAS.AddPermission(Permission::Update);
        StorageServAuthSAS.AddPermission(Permission::Process);
        StorageServAuthSAS.AddPermission(Permission::BlobIndexReadWrite);
        StorageServAuthSAS.AddPermission(Permission::BlobIndexFilter);
        StorageServAuthSAS.AddPermission(Permission::VersionDeletion);
        StorageServAuthSAS.AddProtocl('https');
        StorageServAuthSAS.AddProtocl('http');

        // [THEN] Generate Shared Access Signature
        ResultFromTest := StorageServAuthSAS.GetSharedAccessSignature();

        Assert.AreEqual(ResultFromTest, ResultFromAzurePortal, 'Generated Signature is not as expected');
    end;

    var
        Assert: Codeunit "Library Assert";
}