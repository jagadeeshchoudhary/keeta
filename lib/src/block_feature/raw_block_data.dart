import 'dart:convert';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/block_feature/block_purpose.dart';
import 'package:keeta/src/block_feature/block_version.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/utils/utils.dart';
import 'package:meta/meta.dart';

@immutable
class RawBlockData {
  const RawBlockData({
    required this.version,
    required this.purpose,
    required this.previous,
    required this.network,
    required this.signer,
    required this.account,
    required this.operations,
    required this.created,
    this.subnet,
    this.idempotent,
  });

  final BlockVersion version;
  final BlockPurpose purpose;
  final String previous;
  final BigInt network;
  final BigInt? subnet;
  final Account signer;
  final Account account;
  final List<BlockOperation> operations;
  final DateTime created;
  final String? idempotent;

  /// Converts the block data to bytes
  Uint8List toBytes() {
    final List<ASN1Object> values = asn1Values();
    final ASN1Sequence sequence = ASN1Sequence()..elements.addAll(values);
    final Uint8List encoded = sequence.encodedBytes;
    return encoded;
  }

  /// Computes the hash of the block data according to its version
  String hash() {
    switch (version) {
      case BlockVersion.v1:
        return Hash.create(fromBytes: toBytes(), length: 32);
      case BlockVersion.v2:
        final List<ASN1Object> values = asn1Values();
        return TaggedValue.contextSpecific(
          tag: version.tag,
          asn1Objects: values,
        ).hash();
    }
  }

  /// Encodes the block data into a list of ASN.1 objects
  List<ASN1Object> asn1Values() {
    Uint8List? idempotentData;
    if (idempotent != null) {
      // Try base64 decode first, then UTF-8
      try {
        idempotentData = base64Decode(idempotent!);
      } catch (_) {
        idempotentData = utf8.encode(idempotent!);
      }
    } else {
      idempotentData = null;
    }

    final Uint8List previousBytes = previous.toBytes();
    final ASN1Integer? asn1Subnet = subnet != null
        ? ASN1Integer(subnet!)
        : null;
    final ASN1OctetString? idempotentAsn1 = idempotentData != null
        ? ASN1OctetString(idempotentData)
        : null;

    final List<ASN1Object> operationsAsn1 = operations
        .map((final BlockOperation op) => op.tagged())
        .toList();

    final Uint8List signerBytes = signer.publicKeyAndType;
    final Uint8List accountBytes = account.publicKeyAndType;

    switch (version) {
      case BlockVersion.v1:
        final List<ASN1Object?> values = <ASN1Object?>[
          ASN1Integer(version.value),
          ASN1Integer(network),
          asn1Subnet ?? ASN1Null(),
          idempotentAsn1,
          ASN1GeneralizedTime(created.toUtc()),
          ASN1OctetString(signerBytes),
          !_bytesEqual(accountBytes, signerBytes)
              ? ASN1OctetString(accountBytes)
              : ASN1Null(),
          ASN1OctetString(previousBytes),
          ASN1Sequence()..elements.addAll(operationsAsn1),
        ];
        return values.whereType<ASN1Object>().toList();

      case BlockVersion.v2:
        final List<ASN1Object?> values = <ASN1Object?>[
          ASN1Integer(network),
          asn1Subnet,
          idempotentAsn1,
          ASN1GeneralizedTime(created.toUtc()),
          ASN1Integer(purpose.value),
          ASN1OctetString(accountBytes),
          !_bytesEqual(signerBytes, accountBytes)
              ? ASN1OctetString(signerBytes)
              : ASN1Null(),
          ASN1OctetString(previousBytes),
          ASN1Sequence()..elements.addAll(operationsAsn1),
        ];
        return values.whereType<ASN1Object>().toList();
    }
  }

  /// Helper method to compare byte arrays
  static bool _bytesEqual(final Uint8List a, final Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
