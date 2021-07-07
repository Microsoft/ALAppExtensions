// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Exposes functionality to handle the creation of an Account SAS (Shared Access Signature)
/// More Information: https://docs.microsoft.com/en-us/rest/api/storageservices/create-account-sas
/// </summary>
codeunit 9062 "Storage Serv. Auth. SAS"
{
    Access = Public;

    /// <summary>
    /// Sets the name of the Azure Storage Account
    /// </summary>
    /// <param name="NewAccountName">The Name of the Azure Storage Account</param>
    procedure SetAccountName(NewAccountName: Text)
    begin
        AccountName := NewAccountName;
    end;

    /// <summary>
    /// Sets the key which is used to sign the generated SAS (Shared Access Signature)
    /// </summary>
    /// <param name="NewSigningKey">The Access Key to sign the SAS</param>
    procedure SetSigningKey(NewSigningKey: Text)
    begin
        SigningKey := NewSigningKey;
    end;

    /// <summary>
    /// Sets the start and end date/time for which this SAS (Shared Access Signature) is valid
    /// </summary>
    /// <param name="NewStartDate">DateTime specifying the start</param>
    /// <param name="NewEndDate">DateTime specifying the expiry</param>
    procedure SetDatePeriod(NewStartDate: DateTime; NewEndDate: DateTime)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;
    end;

    /// <summary>
    /// Sets the IP Range from which a request will be accepted (e.g. 168.1.5.60-168.1.5.70)
    /// </summary>
    /// <param name="NewIPRange">Value (as Text) specifying the IP Range</param>
    procedure SetIPrange(NewIPRange: Text)
    begin
        IPRange := NewIPRange;
    end;

    /// <summary>
    /// Sets the API Version to be used for the desired operation
    /// </summary>
    /// <param name="NewApiVersion">Value of Enum "Storage service API Version" specifying the used version</param>
    procedure SetVersion(NewAPIVersion: Enum "Storage Service API Version")
    begin
        ApiVersion := NewAPIVersion;
    end;

    /// <summary>
    /// Adds an entry to the list of allowed services for the SAS that is to be generated
    /// </summary>
    /// <param name="ServiceType">Value of Enum "Storage Service Type" specifying the used service</param>
    procedure AddService(ServiceType: Enum "Storage Service Type")
    begin
        Services.Add(ServiceType);
    end;

    /// <summary>
    /// Adds an entry to the list of allowed resources for the SAS that is to be generated
    /// </summary>
    /// <param name="ResourceType">Value of Enum "Storage Service Resource Type" specifying the used resource</param>
    procedure AddResource(ResourceType: Enum "Storage Service Resource Type")
    begin
        Resources.Add(ResourceType);
    end;

    /// <summary>
    /// Adds an entry to the list of allowed permissions for the SAS that is to be generated
    /// </summary>
    /// <param name="Permission">Value of Enum "Storage Service Permission" specifying the used permission</param>
    procedure AddPermission(Permission: Enum "Storage Service Permission")
    begin
        Permissions.Add(Permission);
    end;

    /// <summary>
    /// Adds an entry to the list of allowed protocols for the SAS that is to be generated
    /// Allowed values are: http, https
    /// </summary>
    /// <param name="ResourceType">Value (as Text) specifying the used protocols</param>
    procedure AddProtocl(Protocol: Text)
    begin
        Protocols.Add(Protocol);
    end;

    /// <summary>
    /// Generates a signature to authenticate the API operation when using "SAS (Shared Access Signature)"-authentication
    /// </summary>
    /// <returns>The generated signature that is to be appended to the URI</returns>
    procedure GetSharedAccessSignature(): Text
    var
        StringToSign: Text;
        Signature: Text;
        SharedAccessSignature: Text;
    begin
        StringToSign := AuthFormatHelper.CreateSharedAccessSignatureStringToSign(AccountName, ApiVersion, StartDate, EndDate, Services, Resources, Permissions, Protocols, IPRange);
        Signature := AuthFormatHelper.GetAccessKeyHashCode(StringToSign, SigningKey);
        SharedAccessSignature := AuthFormatHelper.CreateSasUrlString(ApiVersion, StartDate, EndDate, Services, Resources, Permissions, Protocols, IPRange, Signature);
        exit(SharedAccessSignature);
    end;

    var
        AuthFormatHelper: Codeunit "Auth. Format Helper";
        AccountName: Text;
        SigningKey: Text;
        StartDate: DateTime;
        EndDate: DateTime;
        ApiVersion: Enum "Storage Service API Version";
        Services: List of [Enum "Storage Service Type"];
        Resources: List of [Enum "Storage Service Resource Type"];
        Permissions: List of [Enum "Storage Service Permission"];
        Protocols: List of [Text];
        IPRange: Text;
}