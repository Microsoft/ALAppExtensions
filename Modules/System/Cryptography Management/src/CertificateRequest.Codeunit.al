// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary> 
/// Provides helper functionality for creating Certificate Signing Requests (CSR:s) and Self Signed Certificates.
/// </summary>
codeunit 1449 CertificateRequest
{
    var
        CertSigningRequestImpl: Codeunit "CertificateRequest Impl.";

    /// <summary>
    /// Initializes a new instance of RSACryptoServiceProvider class with the specified key size and returns the key as a xml string.
    /// </summary>
    /// <param name="KeySize">The size of the key in bits.</param>
    /// <param name="IncludePrivateParameters">true to include a public and private RSA key in KeyAsXmlString; false to include only the public key.</param>
    /// <param name="KeyAsXmlString">Returns an XML string containing the key of the created RSA object.</param>
    procedure InitializeRSA(KeySize: Integer; IncludePrivateParameters: Boolean; var KeyAsXmlString: Text)
    begin
        CertSigningRequestImpl.InitializeRSA(KeySize, IncludePrivateParameters, KeyAsXmlString);
    end;

    /// <summary>
    /// Initializes a new instance of the CertificateRequest class with the specified parameters and the initialized RSA key.
    /// </summary>
    /// <param name="SubjectName">The string representation of the subject name for the certificate or certificate request.</param>
    /// <param name="HashAlgorithm">The hash algorithm to use when signing the certificate or certificate request.</param>
    /// <param name="RSASignaturePaddingMode">The RSA signature padding to apply if self-signing or being signed with an X509Certificate2.</param>
    procedure InitializeCertificateRequestUsingRSA(SubjectName: Text; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePaddingMode: Enum "RSA Signature Padding")
    begin
        CertSigningRequestImpl.InitializeCertificateRequestUsingRSA(SubjectName, HashAlgorithm, RSASignaturePaddingMode);
    end;

    /// <summary> 
    /// Adds a X509BasicConstraint to the Certificate Request. See https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509basicconstraintsextension
    /// </summary>
    /// <param name="CertificateAuthority">true if the certificate is a certificate authority (CA) certificate; otherwise, false.</param>
    /// <param name="HasPathLengthConstraint">true if the certificate has a restriction on the number of path levels it allows; otherwise, false.</param>
    /// <param name="PathLengthConstraint">The number of levels allowed in a certificate's path.</param>
    /// <param name="Critical">true if the extension is critical; otherwise, false.</param>
    procedure AddX509BasicConstraintToCertificateRequest(CertificateAuthority: Boolean; HasPathLengthConstraint: Boolean; PathLengthConstraint: Integer; Critical: Boolean)
    begin
        CertSigningRequestImpl.AddX509BasicConstraintToCertificateRequest(CertificateAuthority, HasPathLengthConstraint, PathLengthConstraint, Critical);
    end;

    /// <summary> 
    /// Adds a X509EnhancedKeyUsage to the Certificate Request. See https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509enhancedkeyusageextension
    /// </summary>
    /// <param name="OidValues">List of Oid values (for example '1.3.6.1.5.5.7.3.2') to add.</param>
    /// <param name="Critical">true if the extension is critical; otherwise, false.</param>
    procedure AddX509EnhancedKeyUsageToCertificateRequest(OidValues: List of [Text]; Critical: Boolean)
    begin
        CertSigningRequestImpl.AddX509EnhancedKeyUsageToCertificateRequest(OidValues, Critical);
    end;

    /// <summary>
    /// Adds a X509KeyUsage to the Certificate Request. See https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509keyusageextension
    /// </summary>
    /// <param name="X509KeyUsageFlags">The sum of all flag values that are to be added. See https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509keyusageflags</param>
    /// <param name="Critical">true if the extension is critical; otherwise, false.</param>
    procedure AddX509KeyUsageToCertificateRequest(X509KeyUsageFlags: Integer; Critical: Boolean)
    begin
        CertSigningRequestImpl.AddX509KeyUsageToCertificateRequest(X509KeyUsageFlags, Critical);
    end;

    /// <summary>
    /// Creates an ASN.1 DER-encoded PKCS#10 CertificationRequest and returns a Base 64 encoded string.
    /// </summary>
    /// <param name="SigningRequestPemString">Returns the SigningRequest in Base 64 string format.</param>
    procedure CreateSigningRequest(var SigningRequestPemString: Text)
    begin
        CertSigningRequestImpl.CreateSigningRequest(SigningRequestPemString);
    end;

    /// <summary>
    /// Creates an ASN.1 DER-encoded PKCS#10 CertificationRequest and returns it in an OutStream.
    /// </summary>
    /// <param name="SigningRequestOutStream">OutStream.</param>
    procedure CreateSigningRequest(SigningRequestOutStream: OutStream)
    begin
        CertSigningRequestImpl.CreateSigningRequest(SigningRequestOutStream);
    end;

    /// <summary>
    /// Creates a self-signed certificate using the established subject, key, and optional extensions.
    /// </summary>
    /// <param name="NotBefore">The oldest date and time when this certificate is considered valid.</param>
    /// <param name="NotAfter">The date and time when this certificate is no longer considered valid.</param>
    /// <param name="X509ContentType">Specifies the format of an X.509 certificate.</param>
    /// <param name="CertBase64Value">Returns the certificate value encoded using the Base64 algorithm.</param>
    procedure CreateSelfSigned(NotBefore: DateTime; NotAfter: DateTime; X509ContentType: Enum "X509 Content Type"; var CertBase64Value: Text)
    begin
        CertSigningRequestImpl.CreateSelfSigned(NotBefore, NotAfter, X509ContentType, CertBase64Value);
    end;
}