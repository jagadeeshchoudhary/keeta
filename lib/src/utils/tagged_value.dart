import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/utils/hash.dart';

/// This class helps in creating and handling context-specific tagged objects.
class TaggedValue {
  const TaggedValue({required this.tag, required this.data});
  factory TaggedValue.contextSpecific({
    required final int tag,
    required final List<ASN1Object> asn1Objects,
  }) {
    final ASN1Sequence sequence = ASN1Sequence()..elements.addAll(asn1Objects);
    final Uint8List data = sequence.encodedBytes;

    return TaggedValue(tag: contextSpecificBase + tag, data: data);
  }

  final int tag;
  final Uint8List data;

  static const int contextSpecificBase = 0xA0;

  /// Checks if the tag class is context-specific.
  bool get isContextSpecific => tag == contextSpecificTag;

  /// Returns the simple tag number (e.g., 0, 1, 2) if it's context-specific.
  int? get contextSpecificTag =>
      tag >= contextSpecificBase ? tag - contextSpecificBase : null;

  /// Returns the simple tag number, masking out the class and type bits.
  /// Corresponds to `tag & 0b0001_1111`.
  int get implicitTag => tag & 0x1F;

  /// Returns the underlying `ASN1TaggedObject` from `asn1lib`.
  ASN1Object get asn1 {
    final ASN1Object taggedObject = ASN1Object.fromBytes(
      Uint8List.fromList(<int>[tag, data.length, ...data]),
    );
    return taggedObject;
  }

  /// Returns the full DER-encoded representation of the tagged value.
  Uint8List toData() {
    final List<int> result = <int>[tag];

    // Encode length
    if (data.length < 128) {
      result.add(data.length);
    } else {
      // Long form length encoding
      final List<int> lengthBytes = _encodeLengthBytes(data.length);
      result
        ..add(0x80 | lengthBytes.length)
        ..addAll(lengthBytes);
    }

    result.addAll(data);
    return Uint8List.fromList(result);
  }

  /// Helper to encode length in DER long form
  List<int> _encodeLengthBytes(final int length) {
    final List<int> bytes = <int>[];
    int tempLength = length;
    while (length > 0) {
      bytes.insert(0, length & 0xFF);
      tempLength = tempLength >> 8;
    }
    return bytes;
  }

  /// Computes the hash of the DER-encoded tagged value.
  String hash() => Hash.create(fromBytes: toData(), length: 32);
}
