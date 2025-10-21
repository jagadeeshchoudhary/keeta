import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/utils/oid.dart';
import 'package:keeta/src/utils/utils.dart';

mixin BlockHash {
  static List<String> parse(final List<ASN1Object> blocksAsn1) {
    if (blocksAsn1.isEmpty) {
      throw CustomException.invalidBlocksTag;
    }

    final ASN1Object first = blocksAsn1.first;

    // Check if tag is context-specific (0x80 class)
    // Tag format: bits 7-6 for class, bit 5 for constructed
    if ((first.tag & 0xC0) != 0x80) {
      throw CustomException.invalidBlocksTag;
    }

    // Decode the inner ASN.1 sequence from the tagged value data
    final Uint8List taggedValue = first.valueBytes();
    final ASN1Parser parser = ASN1Parser(taggedValue);
    final ASN1Object nextObj = parser.nextObject();

    if (nextObj is! ASN1Sequence) {
      throw CustomException.invalidBlocksDataSequence;
    }

    final ASN1Sequence blocksDataSequence = nextObj;

    if (blocksDataSequence.elements.length != 2) {
      throw CustomException.invalidBlocksSequenceLength;
    }

    // First element: OID for hash algorithm
    final ASN1Object oidObj = blocksDataSequence.elements[0];
    if (oidObj is! ASN1ObjectIdentifier) {
      throw CustomException.invalidBlocksOID;
    }

    final String? oidValue = oidObj.identifier;
    if (oidValue == null) {
      throw CustomException.invalidBlocksOID;
    }

    OID hashAlgoOID;
    try {
      hashAlgoOID = OID.fromValue(oidValue);
    } catch (e) {
      throw CustomException.unknownHashFunction;
    }

    // Assuming you want SHA3-256 based on your OID enum
    // Adjust this to match your Hash.oid equivalent
    if (hashAlgoOID != OID.sha3_256) {
      throw CustomException.unsupportedHashFunction;
    }

    // Second element: sequence of block hashes
    final ASN1Object blocksSequence = blocksDataSequence.elements[1];
    if (blocksSequence is! ASN1Sequence) {
      throw CustomException.invalidBlocksSequence;
    }

    return blocksSequence.elements.map((final ASN1Object obj) {
      if (obj is ASN1OctetString) {
        return obj
            .valueBytes()
            .map((final int b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
      } else {
        throw CustomException.invalidBlockHash;
      }
    }).toList();
  }
}
