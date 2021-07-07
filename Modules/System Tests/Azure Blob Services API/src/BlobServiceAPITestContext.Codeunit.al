codeunit 88155 "Blob Service API Test Context"
{
    procedure SetSharedKeyAuth()
    begin
        SetAuthType(AuthType::AccessKey);
    end;

    procedure SetSasTokenAuth()
    begin
        SetAuthType(AuthType::SasToken);
    end;

    procedure SetAuthType(NewAuthType: Enum "Storage Service Authorization Type")
    begin
        AuthType := NewAuthType;
    end;

    procedure GetAuthType(): Enum "Storage Service Authorization Type"
    begin
        exit(AuthType);
    end;

    procedure SetApiVersion(NewApiVersion: Enum "Storage Service API Version")
    begin
        ApiVersion := NewApiVersion;
    end;

    procedure GetApiVersion(): Enum "Storage Service API Version"
    begin
        exit(ApiVersion);
    end;

    procedure SetAccessKey(NewAccessKey: Text)
    begin
        AccessKey := NewAccessKey;
    end;

    procedure GetAccessKey(): Text
    begin
        exit(AccessKey);
    end;

    procedure SetSasToken(NewSasToken: Text)
    begin
        SasToken := NewSasToken;
    end;

    procedure GetSasToken(): Text
    begin
        exit(SasToken);
    end;

    procedure GetSecret(): Text
    begin
        if AuthType = AuthType::SasToken then
            exit(SasToken);
        if AuthType = AuthType::AccessKey then
            exit(AccessKey);
    end;

    procedure SetStorageAccountName(NewStorageAccountName: Text)
    begin
        StorageAccountName := NewStorageAccountName;
    end;

    procedure GetStorageAccountName(): Text
    begin
        exit(StorageAccountName);
    end;

    procedure InitializeContextSharedKeyVersion20200210()
    begin
        InitializeContextSharedKeyVersion20200210('');
    end;

    procedure InitializeContextSharedKeyVersion20200210(NewStorageAccountName: Text)
    begin
        ClearAll();
        SetSharedKeyAuth();
        SetApiVersion(ApiVersion::"2020-02-10");
        if NewStorageAccountName = '' then
            NewStorageAccountName := HelperLibrary.GetStorageAccountName();
        StorageAccountName := NewStorageAccountName;
        AccessKey := HelperLibrary.GetAccessKey();
    end;

    var
        HelperLibrary: Codeunit "Blob Service API Test Help Lib";
        AuthType: Enum "Storage Service Authorization Type";
        ApiVersion: Enum "Storage Service API Version";
        StorageAccountName: Text;
        AccessKey: Text;
        SasToken: Text;
}