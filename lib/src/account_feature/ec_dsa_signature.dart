import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';

class ECDSASignature {

  const ECDSASignature({required this.r, required this.s});

  /// Parse DER-encoded ECDSA signature ([r, s])
  factory ECDSASignature.fromDER(final Uint8List derBytes) {
    final ASN1Parser parser = ASN1Parser(derBytes);
    final ASN1Sequence sequence = parser.nextObject() as ASN1Sequence;

    final ASN1Integer rInt = sequence.elements[0] as ASN1Integer;
    final ASN1Integer sInt = sequence.elements[1] as ASN1Integer;

    return ECDSASignature(
      r: _normalizeBytes(rInt.valueBytes()),
      s: _normalizeBytes(sInt.valueBytes()),
    );
  }
  final Uint8List r;
  final Uint8List s;

  /// Normalizes to exactly 32 bytes (padding or truncating)
  static Uint8List _normalizeBytes(final Uint8List bytes) {
    if (bytes.length > 32) {
      return Uint8List.fromList(bytes.sublist(bytes.length - 32));
    } else if (bytes.length < 32) {
      final Uint8List padding = Uint8List(32 - bytes.length);
      return Uint8List.fromList(<int>[...padding, ...bytes]);
    }
    return bytes;
  }

  /// Combine into 64-byte compact representation
  Uint8List toCompact() => Uint8List.fromList(<int>[...r, ...s]);
}
