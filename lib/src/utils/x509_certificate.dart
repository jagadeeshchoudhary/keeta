import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/utils/custom_exception.dart';

/// Utility class for working with X.509 certificates
class X509Certificate {
  X509Certificate._();

  /// Extracts the signed area (TBS - To Be Signed) from an X.509 certificate
  ///
  /// The X.509 certificate structure is:
  /// SEQUENCE {
  ///   tbsCertificate (the data to be signed) <- This is what we extract
  ///   signatureAlgorithm
  ///   signatureValue
  /// }
  static Uint8List signedArea({required final Uint8List fromData}) {
    final ASN1Parser parser = ASN1Parser(fromData);

    // Parse the root sequence
    final ASN1Object rootNode = parser.nextObject();

    if (rootNode is! ASN1Sequence) {
      throw CustomException.invalidX509Data;
    }

    final ASN1Sequence sequence = rootNode;

    if (sequence.elements.isEmpty) {
      throw CustomException.invalidX509Data;
    }

    // The first element is the TBS (To Be Signed) certificate
    final ASN1Object tbsCertificate = sequence.elements[0];

    // Serialize just the TBS certificate part back to DER format
    final Uint8List encodedBytes = tbsCertificate.encodedBytes;

    return Uint8List.fromList(encodedBytes);
  }
}
