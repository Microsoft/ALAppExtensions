This module exposes functionality to assist with Authentication against the [Azure Storage Services REST API](https://docs.microsoft.com/en-us/rest/api/storageservices/).

### Access Key / Shared Key
An access key is one possible way to authenticate requests against the API. See [Authorize with Shared Key](https://docs.microsoft.com/en-us/rest/api/storageservices/authorize-with-shared-key) for more information.

### SAS (Shared Access Signature)
A SAS (Shared Access Signature) is one possible way to authenticate requests against the API. See [Grant limited access to Azure Storage resources using shared access signatures (SAS)](https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview) for more information.

# Public Objects
## Storage Serv. Auth. Access Key (Codeunit 87001)

Exposes functionality to handle the creation of a signature to sign requests to the Storage Services REST API.

## Storage Serv. Auth. SAS (Codeunit 87002)

Exposes functionality to handle the creation of an Account SAS (Shared Access Signature).

...