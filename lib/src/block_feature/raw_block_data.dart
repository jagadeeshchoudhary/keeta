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

  /// Encodes the block data into a list of ASN.1 objects.
  /// Throws an exception if encoding fails.
  List<ASN1Object> toASN1Values() {
    // In Swift, previous.toBytes() likely decodes a hex string.
    // The `convert` package is used here for that.
    final Uint8List previousBytes = previous.toBytes();

    final ASN1Integer? asn1Subnet = (subnet != null)
        ? ASN1Integer(subnet!)
        : null;

    final List<ASN1Object> asn1Operations = operations
        .map((final BlockOperation op) => op.tagged())
        .toList();

    final Uint8List signerBytes = signer.publicKeyAndType;
    final Uint8List accountBytes = account.publicKeyAndType;

    switch (version) {
      case BlockVersion.v1:
        return <ASN1Object>[
          ASN1Integer(version.value),
          ASN1Integer(network),
          asn1Subnet ?? ASN1Null(),
          ASN1GeneralizedTime(created.toUtc()),
          ASN1OctetString(signerBytes),
          (account != signer) ? ASN1OctetString(accountBytes) : ASN1Null(),
          ASN1OctetString(previousBytes),
          ASN1Sequence()..elements.addAll(asn1Operations),
        ];
      case BlockVersion.v2:
        return <ASN1Object>[
          ASN1Integer(network),
          if (asn1Subnet != null) asn1Subnet,
          ASN1GeneralizedTime(created.toUtc()),
          ASN1Integer(purpose.value),
          ASN1OctetString(accountBytes),
          (signer != account) ? ASN1OctetString(signerBytes) : ASN1Null(),
          ASN1OctetString(previousBytes),
          ASN1Sequence()..elements.addAll(asn1Operations),
        ];
    }
  }

  /// Serializes the ASN.1 values into a byte list (Uint8List).
  /// This corresponds to  sequence of values, which is the V1 hashing method.
  Uint8List toBytes() {
    final List<ASN1Object> values = toASN1Values();
    // In ASN.1, a list of values is typically encoded as a SEQUENCE.
    final ASN1Sequence sequence = ASN1Sequence()..elements.addAll(values);
    return sequence.encodedBytes;
  }

  /// Computes the hash of the block data according to its version.
  /// Returns the hash as a hex-encoded string.
  String hash() {
    switch (version) {
      case BlockVersion.v1:
        return Hash.create(fromBytes: toBytes(), length: 32);

      case BlockVersion.v2:
        final List<ASN1Object> values = toASN1Values();
        final TaggedValue tagged = TaggedValue.contextSpecific(
          tag: version.tag,
          asn1Objects: values,
        );
        return tagged.hash();
    }
  }
}
