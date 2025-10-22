import 'dart:convert';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/keeta.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/account_feature/account_builder.dart';
import 'package:keeta/src/utils/asn1_distinguished_names.dart';
import 'package:keeta/src/utils/custom_exception.dart';
import 'package:keeta/src/utils/hash.dart';
import 'package:keeta/src/utils/oid.dart';
import 'package:keeta/src/utils/x509_certificate.dart';

typedef Serial = BigInt;

/*
 -- Votes are X.509v3 Certificates with additional information stored within 
    the extensions
     Vote ::= SEQUENCE {
         -- Data (to be signed)
         data SEQUENCE {
             -- Version
             version        [0] EXPLICIT INTEGER { v3(2) },
             -- Serial number
             serial         INTEGER,
             -- Signature algorithm
             signature      SEQUENCE {
                 -- Algorithm
                 algorithm    OBJECT IDENTIFIER,
                 -- Parameters
                 parameters   ANY OPTIONAL
             },
             -- Issuer
             issuer         SEQUENCE {
                 dn     SET OF SEQUENCE {
                     -- Attribute type (commonName, 2.5.4.3)
                     type   OBJECT IDENTIFIER ( commonName ),
                     -- Attribute value
                     value  UTF8String
                 }
             },
             -- Validity
             validity       SEQUENCE {
                 -- Not before
                 notBefore     GeneralizedTime,
                 -- Not after
                 notAfter      GeneralizedTime
             },
             -- Subject
             subject        SEQUENCE {
                 dn     SET OF SEQUENCE {
                     -- Attribute type (serialNumber, 2.5.4.5)
                     type   OBJECT IDENTIFIER ( serialNumber ),
                     -- Attribute value
                     value  UTF8String
                 }
             },
             -- Subject public key info
             subjectPKInfo  SEQUENCE {
                 -- Algorithm
                 algorithm    SEQUENCE {
                     -- Algorithm
                     algorithm    OBJECT IDENTIFIER,
                     -- Parameters
                     parameters   ANY
                 },
                 -- Public key
                 publicKey     BIT STRING
             },
            -- Extensions
            extensions     [3] EXPLICIT SEQUENCE {
                -- Any extensions used by the Keeta network
            },
         },
         -- Signature algorithm
         signatureAlgorithm SEQUENCE {
             -- Algorithm
             algorithm    OBJECT IDENTIFIER,
             -- Parameters
             parameters   ANY OPTIONAL
         },
         -- Signature
         signature      BIT STRING
    }
 */

/// Extension data in a certificate
class CertificateExtension {
  const CertificateExtension({required this.data, required this.critical});

  final ASN1Object data;
  final bool critical;
}

/// X.509v3 Certificate
class Certificate {
  /// Creates a Certificate from raw data
  factory Certificate.fromData({required final Uint8List data}) {
    final ASN1Parser parser = ASN1Parser(data);
    final ASN1Object asn1Object = parser.nextObject();

    if (asn1Object is! ASN1Sequence) {
      throw CustomException.invalidASN1Sequence;
    }

    final ASN1Sequence sequence = asn1Object;

    // Sequence contains the certificate, signature info, and signature
    if (sequence.elements.length != 3) {
      throw CustomException.invalidASN1SequenceLength;
    }

    /*
     The contents of the X.509 certificate signed area
     */
    final ASN1Object certificateContent = sequence.elements[0];
    if (certificateContent is! ASN1Sequence) {
      throw CustomException.invalidCertificateSequence;
    }

    if (certificateContent.elements.length != 8) {
      throw CustomException.invalidCertificateSequenceLength;
    }

    final ASN1Object versionElement = certificateContent.elements[0];
    final ASN1Object serialElement = certificateContent.elements[1];
    final ASN1Object signatureInfo = certificateContent.elements[2];
    final ASN1Object issuerWrapper = certificateContent.elements[3];
    final ASN1Object validityInfo = certificateContent.elements[4];
    final ASN1Object subjectWrapper = certificateContent.elements[5];
    // certificateContent.elements[6] // Subject Public Key: We don't use this
    final ASN1Object extensionsArea = certificateContent.elements[7];

    // Validate version (context-specific tag [0])
    if ((versionElement.tag & 0xC0) != 0x80) {
      throw CustomException.invalidVersion;
    }

    final Uint8List versionBytes = versionElement.valueBytes();
    if (versionBytes.length < 3) {
      throw CustomException.invalidVersion;
    }

    // Parse the INTEGER tag inside the context-specific tag
    if (versionBytes[0] != 0x02) {
      // 0x02 = INTEGER tag
      throw CustomException.invalidVersion;
    }

    final int versionLength = versionBytes[1];
    final Uint8List versionValue = versionBytes.sublist(2, 2 + versionLength);
    final BigInt version = versionValue.fold<BigInt>(
      BigInt.zero,
      (final BigInt acc, final int byte) => (acc << 8) + BigInt.from(byte),
    );

    if (version != certificateVersion) {
      throw CustomException.invalidVersion;
    }

    // Get TBS (To Be Signed) certificate data
    final Uint8List tbsCertificate = X509Certificate.signedArea(fromData: data);

    // Parse serial number
    if (serialElement is! ASN1Integer) {
      throw CustomException.invalidCertificateValue;
    }
    final BigInt serial = serialElement.valueAsBigInteger;

    // Signature information
    if (signatureInfo is! ASN1Sequence) {
      throw CustomException.invalidSignatureInfoSequence;
    }

    if (signatureInfo.elements.length != 1) {
      throw CustomException.invalidSignatureInfoSequenceLength;
    }

    final ASN1Object signatureInfoOidElement = signatureInfo.elements[0];
    if (signatureInfoOidElement is! ASN1ObjectIdentifier) {
      throw CustomException.invalidSignatureInfoOID;
    }

    final String? signatureInfoOidValue = signatureInfoOidElement.identifier;
    if (signatureInfoOidValue == null) {
      throw CustomException.invalidSignatureInfoOID;
    }

    OID signatureInfoOid;
    try {
      signatureInfoOid = OID.fromValue(signatureInfoOidValue);
    } catch (e) {
      throw CustomException.unknownSignatureInfoOID(signatureInfoOidValue);
    }

    // Issuer information
    if (issuerWrapper is! ASN1Sequence) {
      throw CustomException.invalidIssuerData;
    }

    final Map<Match<OID>, String> issuerContent = ASN1DistinguishedNames.find(
      inSequence: issuerWrapper,
    );
    final String? issuerKey = issuerContent[const Known<OID>(OID.commonName)];
    if (issuerKey == null) {
      throw CustomException.invalidIssuerData;
    }

    final Account issuer = AccountBuilder.createFromPublicKey(
      publicKey: issuerKey,
    );

    // Validity period
    if (validityInfo is! ASN1Sequence) {
      throw CustomException.invalidValidityData;
    }

    if (validityInfo.elements.length != 2) {
      throw CustomException.invalidValiditySequenceLength;
    }

    final ASN1Object validFromElement = validityInfo.elements[0];
    final ASN1Object validToElement = validityInfo.elements[1];

    if (validFromElement is! ASN1UtcTime &&
        validFromElement is! ASN1GeneralizedTime) {
      throw CustomException.invalidValidityData;
    }
    if (validToElement is! ASN1UtcTime &&
        validToElement is! ASN1GeneralizedTime) {
      throw CustomException.invalidValidityData;
    }

    final DateTime validFrom = _parseDateTime(validFromElement);
    final DateTime validTo = _parseDateTime(validToElement);

    // Votes must not have invalid validity periods
    if (!validTo.isAfter(validFrom)) {
      throw CustomException.invalidValidity;
    }

    final bool permanent = Certificate.isPermanent(validTo: validTo);

    // Subject
    if (subjectWrapper is! ASN1Sequence) {
      throw CustomException.invalidSubjectData;
    }

    final Map<Match<OID>, String> subjectContent = ASN1DistinguishedNames.find(
      inSequence: subjectWrapper,
    );
    final String? subjectSerial =
        subjectContent[const Known<OID>(OID.serialNumber)];
    if (subjectSerial == null) {
      throw CustomException.invalidSubjectData;
    }

    final BigInt? subjectSerialBigInt = BigInt.tryParse('0x$subjectSerial');
    if (subjectSerialBigInt == null || serial != subjectSerialBigInt) {
      throw CustomException.serialMismatch;
    }

    // Signature data
    final ASN1Object voteSignatureInfoWrapper = sequence.elements[1];
    if (voteSignatureInfoWrapper is! ASN1Sequence) {
      throw CustomException.invalidSignatureSequence;
    }

    if (voteSignatureInfoWrapper.elements.length != 1) {
      throw CustomException.invalidSignatureSequenceLength;
    }

    final ASN1Object voteSignatureInfoOidElement =
        voteSignatureInfoWrapper.elements[0];
    if (voteSignatureInfoOidElement is! ASN1ObjectIdentifier) {
      throw CustomException.invalidSignatureDataOID;
    }

    final String? voteSignatureInfoOidValue =
        voteSignatureInfoOidElement.identifier;
    if (voteSignatureInfoOidValue == null) {
      throw CustomException.invalidSignatureDataOID;
    }

    OID voteSignatureInfoOid;
    try {
      voteSignatureInfoOid = OID.fromValue(voteSignatureInfoOidValue);
    } catch (e) {
      throw CustomException.unknownSignatureDataOID(voteSignatureInfoOidValue);
    }

    // Ensure the certificate and the wrapper agree on the signature method
    if (voteSignatureInfoOid != signatureInfoOid) {
      throw CustomException.signatureInformationMismatch;
    }

    final Uint8List toVerify;

    switch (voteSignatureInfoOid) {
      case OID.ecdsaWithSHA3_256:
        if (issuer.keyAlgorithm != KeyAlgorithm.ecdsaSecp256k1) {
          throw CustomException.issuerSignatureSchemeMismatch;
        }
        toVerify = Hash.createData(fromData: tbsCertificate);

      case OID.ed25519:
        if (issuer.keyAlgorithm != KeyAlgorithm.ed25519) {
          throw CustomException.issuerSignatureSchemeMismatch;
        }
        toVerify = tbsCertificate;
      default:
        throw CustomException.unsupportedSignatureScheme;
    }

    // Get the signature
    final ASN1Object voteSignatureElement = sequence.elements[2];
    if (voteSignatureElement is! ASN1BitString) {
      throw CustomException.invalidSignatureDataBitString;
    }

    final Uint8List signature = voteSignatureElement.valueBytes();

    if (!issuer.verify(
      data: toVerify,
      signature: signature,
      options: const SigningOptions(raw: true, forCert: true),
    )) {
      throw CustomException.invalidSignatureData;
    }

    // Extensions
    if ((extensionsArea.tag & 0xC0) != 0x80) {
      throw CustomException.invalidExtensions;
    }

    final Uint8List extensionsBytes = extensionsArea.valueBytes();
    final ASN1Parser extensionsParser = ASN1Parser(extensionsBytes);
    final ASN1Object extensionsAsn1 = extensionsParser.nextObject();

    if (extensionsAsn1 is! ASN1Sequence) {
      throw CustomException.invalidExtensions;
    }

    final ASN1Sequence extensionsSequence = extensionsAsn1;

    final Map<OID, CertificateExtension> extensions =
        <OID, CertificateExtension>{};
    for (final ASN1Object extensionInfo in extensionsSequence.elements) {
      if (extensionInfo is! ASN1Sequence) {
        throw CustomException.invalidExtensionSequence;
      }

      final ASN1Sequence extensionSequence = extensionInfo;
      if (extensionSequence.elements.length != 2 &&
          extensionSequence.elements.length != 3) {
        throw CustomException.invalidExtensionSequence;
      }

      final ASN1Object oidElement = extensionSequence.elements[0];
      if (oidElement is! ASN1ObjectIdentifier) {
        throw CustomException.invalidExtensionOID;
      }

      final String? oidValue = oidElement.identifier;
      if (oidValue == null) {
        throw CustomException.invalidExtensionOID;
      }

      OID oid;
      try {
        oid = OID.fromValue(oidValue);
      } catch (e) {
        throw CustomException.invalidExtensionOID;
      }

      final bool critical;
      final int dataIndex;

      if (extensionSequence.elements.length == 2) {
        final ASN1Object criticalElement = extensionSequence.elements[1];
        if (criticalElement is! ASN1Boolean) {
          throw CustomException.invalidExtensionCriticalCheck;
        }
        critical = criticalElement.booleanValue;
        dataIndex = 2;
      } else {
        critical = true;
        dataIndex = 2;
      }

      if (dataIndex >= extensionSequence.elements.length) {
        throw CustomException.invalidHashDataExtension;
      }

      final ASN1Object extensionData = extensionSequence.elements[dataIndex];
      extensions[oid] = CertificateExtension(
        data: extensionData,
        critical: critical,
      );
    }

    // Construct certificate
    final String id = 'ID=${issuer.publicKeyString}/Serial=$serial';
    final String hashValue = Hash.create(fromBytes: data);

    return Certificate._(
      id: id,
      hash: hashValue,
      version: version,
      serial: serial,
      issuer: issuer,
      signature: signature,
      validityFrom: validFrom,
      validityTo: validTo,
      permanent: permanent,
      extensions: extensions,
      data: data,
    );
  }
  // v3

  /// Creates a Certificate from base64 encoded string
  factory Certificate.createFromBase64({required final String base64}) {
    final Uint8List data = base64Decode(base64);
    return Certificate.fromData(data: Uint8List.fromList(data));
  }
  const Certificate._({
    required this.id,
    required this.hash,
    required this.version,
    required this.issuer,
    required this.serial,
    required this.validityFrom,
    required this.validityTo,
    required this.signature,
    required this.permanent,
    required this.extensions,
    required this.data,
  });

  final String id;
  final String hash;
  final BigInt version;
  final Account issuer;
  final Serial serial;
  final DateTime validityFrom;
  final DateTime validityTo;
  final Uint8List signature;
  final bool permanent;
  final Map<OID, CertificateExtension> extensions;
  final Uint8List data;

  static final BigInt certificateVersion = BigInt.from(2);

  /// Checks if a certificate is permanent based on validity period
  static bool isPermanent({required final DateTime validTo}) {
    const Duration permanentVoteThreshold = Duration(days: 100 * 365);
    // If the vote is forever viable, it is a permanent vote
    return validTo.isAfter(DateTime.now().add(permanentVoteThreshold));
  }

  /// Returns the raw data of the certificate
  Uint8List toData() => data;

  /// Returns base64 encoded string of the certificate
  String toBase64String() => base64Encode(data);

  /// Helper to parse DateTime from ASN1 time elements
  static DateTime _parseDateTime(final ASN1Object element) {
    if (element is ASN1UtcTime) {
      return element.dateTimeValue;
    } else if (element is ASN1GeneralizedTime) {
      return element.dateTimeValue;
    } else {
      throw CustomException.invalidValidityData;
    }
  }
}
