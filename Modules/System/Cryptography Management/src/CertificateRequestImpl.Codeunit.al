// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 1450 "CertificateRequest Impl."
{
    Access = Internal;

    var
        DotNetRSACryptoServiceProvider: DotNet RSACryptoServiceProvider;
        DotNetCertificateRequest: DotNet CertificateRequest;

    procedure InitializeRSA(KeySize: Integer; IncludePrivateParameters: Boolean; var KeyAsXmlString: Text)
    begin
        DotNetRSACryptoServiceProvider := DotNetRSACryptoServiceProvider.RSACryptoServiceProvider(KeySize);
        DotNetRSACryptoServiceProvider.PersistKeyInCsp(false);
        KeyAsXmlString := DotNetRSACryptoServiceProvider.ToXmlString(IncludePrivateParameters);
    end;

    procedure InitializeCertificateRequestUsingRSA(SubjectName: Text; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePaddingMode: Enum "RSA Signature Padding")
    var
        DotNetHashAlgorithmName: DotNet HashAlgorithmName;
        DotNetRSASignaturePadding: DotNet RSASignaturePadding;
    begin
        case RSASignaturePaddingMode of
            RSASignaturePaddingMode::Pkcs1:
                DotNetRSASignaturePadding := DotNetRSASignaturePadding.Pkcs1();
            RSASignaturePaddingMode::Pss:
                DotNetRSASignaturePadding := DotNetRSASignaturePadding.Pss();
        end;

        case HashAlgorithm of
            HashAlgorithm::MD5:
                DotNetHashAlgorithmName := DotNetHashAlgorithmName.MD5();
            HashAlgorithm::SHA1:
                DotNetHashAlgorithmName := DotNetHashAlgorithmName.SHA1();
            HashAlgorithm::SHA256:
                DotNetHashAlgorithmName := DotNetHashAlgorithmName.SHA256();
            HashAlgorithm::SHA384:
                DotNetHashAlgorithmName := DotNetHashAlgorithmName.SHA384();
            HashAlgorithm::SHA512:
                DotNetHashAlgorithmName := DotNetHashAlgorithmName.SHA512();
        end;

        DotNetCertificateRequest := DotNetCertificateRequest.CertificateRequest(SubjectName, DotNetRSACryptoServiceProvider, DotNetHashAlgorithmName, DotNetRSASignaturePadding);
    end;

    procedure AddX509BasicConstraintToCertificateRequest(CertificateAuthority: Boolean; HasPathLengthConstraint: Boolean; PathLengthConstraint: Integer; Critical: Boolean)
    var
        DotNetX509BasicConstraintsExtension: DotNet X509BasicConstraintsExtension;
    begin
        DotNetCertificateRequest.CertificateExtensions.Add(
            DotNetX509BasicConstraintsExtension.X509BasicConstraintsExtension(
                CertificateAuthority, HasPathLengthConstraint, PathLengthConstraint, Critical));
    end;

    procedure AddX509EnhancedKeyUsageToCertificateRequest(OidValues: List of [Text]; Critical: Boolean)
    var
        DotNetX509EnhancedKeyUsageExtension: DotNet X509EnhancedKeyUsageExtension;
        DotNetOidCollection: DotNet OidCollection;
        DotNetOid: DotNet Oid;
        Item: Text;
    begin
        DotNetOidCollection := DotNetOidCollection.OidCollection();
        foreach Item in OidValues do
            DotNetOidCollection.Add(DotNetOid.Oid(Item));

        DotNetCertificateRequest.CertificateExtensions.Add(
            DotNetX509EnhancedKeyUsageExtension.X509EnhancedKeyUsageExtension(DotNetOidCollection, Critical));
    end;

    procedure AddX509KeyUsageToCertificateRequest(X509KeyUsageFlags: Integer; Critical: Boolean)
    var
        DotNetX509KeyUsageExtension: DotNet X509KeyUsageExtension;
        DotNetX509KeyUsageFlags: Dotnet X509KeyUsageFlags;
    begin
        DotNetX509KeyUsageFlags := X509KeyUsageFlags;
        DotNetCertificateRequest.CertificateExtensions.Add(
            DotNetX509KeyUsageExtension.X509KeyUsageExtension(DotNetX509KeyUsageFlags, Critical));
    end;

    procedure CreateSigningRequest(var SigningRequestPemString: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        SigningRequestOutStream: OutStream;
        SigningRequestInStream: InStream;
        Pem: TextBuilder;
        B64: Text;
        Pos: Integer;
        BeginCertReqTok: Label '-----BEGIN CERTIFICATE REQUEST-----', Locked = true;
        EndCertReqTok: Label '-----END CERTIFICATE REQUEST-----', Locked = true;
    begin
        TempBlob.CreateOutStream(SigningRequestOutStream);
        TempBlob.CreateInStream(SigningRequestInStream);
        CreateSigningRequest(SigningRequestOutStream);
        B64 := Base64Convert.ToBase64(SigningRequestInStream);

        Pos := 1;
        Pem.AppendLine(BeginCertReqTok);
        while Pos < StrLen(B64) do begin
            Pem.AppendLine(CopyStr(B64, Pos, 64));
            Pos += 64;
        end;
        Pem.Append(EndCertReqTok);

        SigningRequestPemString := Pem.ToText();
    end;

    procedure CreateSigningRequest(SigningRequestOutStream: OutStream)
    var
        DotNetSigningRequest: DotNet Array;
    begin
        CreateSigningRequest(DotNetSigningRequest);
        ArrayToOutStream(DotNetSigningRequest, SigningRequestOutStream);
    end;

    local procedure CreateSigningRequest(var DotNetSigningRequest: DotNet Array)
    begin
        DotNetSigningRequest := DotNetCertificateRequest.CreateSigningRequest();
    end;

    procedure CreateSelfSigned(NotBefore: DateTime; NotAfter: DateTime; X509ContentType: Enum "X509 Content Type"; var CertBase64Value: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        DotNetNotBefore: DotNet DateTimeOffset;
        DotNetNotAfter: DotNet DateTimeOffset;
        DotNetX509Certificate2: DotNet X509Certificate2;
    begin
        DotNetNotBefore := DotNetNotBefore.DateTimeOffset(NotBefore);
        DotNetNotAfter := DotNetNotBefore.DateTimeOffset(NotAfter);
        DotNetX509Certificate2 := DotNetCertificateRequest.CreateSelfSigned(DotNetNotBefore, DotNetNotAfter);
        TryExportToBase64String(DotNetX509Certificate2, X509ContentType, CertBase64Value)
    end;

    local procedure ArrayToOutStream(DotNetBytes: DotNet Array; OutputOutStream: OutStream)
    var
        DotNetMemoryStream: DotNet MemoryStream;
    begin
        DotNetMemoryStream := DotNetMemoryStream.MemoryStream(DotNetBytes);
        CopyStream(OutputOutStream, DotNetMemoryStream);
    end;

    [TryFunction]
    local procedure TryExportToBase64String(DotNetX509Certificate2: DotNet X509Certificate2; X509ContentType: Enum "X509 Content Type"; var CertBase64Value: Text)
    var
        DotNetConvert: DotNet Convert;
        DotNetX509ContentType: DotNet X509ContentType;
        DotNetEnum: DotNet Enum;
    begin
        DotNetX509ContentType := DotNetEnum.Parse(GetDotNetType(DotNetX509ContentType), Format(X509ContentType));
        CertBase64Value := DotNetConvert.ToBase64String(DotNetX509Certificate2.Export(DotNetX509ContentType));
    end;
}