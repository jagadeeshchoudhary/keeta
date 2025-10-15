import 'dart:convert';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/block_feature/block_purpose.dart';
import 'package:keeta/src/block_feature/block_signature.dart';
import 'package:keeta/src/block_feature/block_version.dart';
import 'package:keeta/src/block_feature/raw_block_data.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/operations/block_operation_builder.dart';
import 'package:keeta/src/utils/utils.dart';

class Block {
  const Block({
    required this.rawData,
    required this.opening,
    required this.hash,
    required this.signature,
  });

  factory Block.fromData(final Uint8List data) {
    final ASN1Parser asn1Parser = ASN1Parser(data);
    final ASN1Object asn1 = asn1Parser.nextObject();

    late List<ASN1Object> sequence;
    late BlockVersion version;

    if (asn1 is ASN1Sequence) {
      sequence = asn1.elements;

      final int rawVersion = (sequence[0] as ASN1Integer).intValue;
      final BlockVersion? versionValue = BlockVersion.fromRawValue(rawVersion);
      if (versionValue != BlockVersion.v1) {
        throw CustomException.invalidVersion;
      }
      version = versionValue ?? BlockVersion.v1;
    } else {
      // Handle tagged value for v2+
      final ASN1Object tagged = asn1;
      final int tagNumber = tagged.tag;

      // Parse the content
      final ASN1Parser contentParser = ASN1Parser(tagged.encodedBytes);
      final ASN1Object contentSeq = contentParser.nextObject();

      if (contentSeq is! ASN1Sequence) {
        throw CustomException.invalidASN1Sequence;
      }
      sequence = contentSeq.elements;

      final BlockVersion? versionValue = BlockVersion.fromRawValue(tagNumber);
      if (versionValue == null || !(versionValue > BlockVersion.v1)) {
        throw CustomException.invalidVersion;
      }
      version = versionValue;
    }

    if (sequence.length != 8 && sequence.length != 9) {
      throw CustomException.invalidASN1SequenceLength;
    }

    late RawBlockData rawBlock;
    late BlockSignature signature;
    late bool opening;

    switch (version) {
      case BlockVersion.v1:
        final (RawBlockData, BlockSignature, bool) result = _blockDataV1(
          sequence,
        );
        rawBlock = result.$1;
        signature = result.$2;
        opening = result.$3;
      case BlockVersion.v2:
        final (RawBlockData, BlockSignature, bool) result = _blockDataV2(
          sequence,
        );
        rawBlock = result.$1;
        signature = result.$2;
        opening = result.$3;
    }

    return Block(
      rawData: rawBlock,
      opening: opening,
      hash: rawBlock.hash(),
      signature: signature,
    );
  }

  factory Block.fromRawBlock({
    required final RawBlockData rawBlock,
    required final bool opening,
    final BlockSignature? signature,
  }) {
    final String hash = rawBlock.hash();
    final Uint8List hashBytes = hash.toBytes();

    BlockSignature verifiedSignature;
    if (signature != null) {
      if (signature is SingleSignature) {
        final bool verified = rawBlock.signer.verify(
          data: hashBytes,
          signature: signature.signature,
        );
        if (!verified) {
          throw CustomException.invalidSignature;
        }
        verifiedSignature = signature;
      } else {
        throw Exception('Multi-signatures not implemented');
      }
    } else {
      final Uint8List signatureBytes = rawBlock.signer.sign(data: hashBytes);
      verifiedSignature = SingleSignature(signatureBytes);
    }

    return Block(
      rawData: rawBlock,
      opening: opening,
      hash: hash,
      signature: verifiedSignature,
    );
  }

  final RawBlockData rawData;
  final bool opening;
  final String hash;
  final BlockSignature signature;

  static String accountOpeningHash(final Account account) {
    final Uint8List publicKeyBytes = account.keyPair.publicKey.toBytes();
    return Hash.create(fromBytes: publicKeyBytes);
  }

  List<ASN1Object> toAsn1() {
    final List<ASN1Object> rawASN1 = rawData.toASN1Values();

    if (signature is SingleSignature) {
      final Uint8List sig = (signature as SingleSignature).signature;
      return <ASN1Object>[...rawASN1, ASN1OctetString(sig)];
    } else if (signature is MultiSignature) {
      final List<Uint8List> sigs = (signature as MultiSignature).signatures;
      return <ASN1Object>[...rawASN1, ...sigs.map(ASN1OctetString.new)];
    }
    throw Exception('Unknown signature type');
  }

  Uint8List toData() {
    switch (rawData.version) {
      case BlockVersion.v1:
        final ASN1Sequence seq = ASN1Sequence();
        seq.elements.addAll(toAsn1());
        return seq.encodedBytes;
      case BlockVersion.v2:
        final TaggedValue tag = TaggedValue.contextSpecific(
          tag: rawData.version.tag,
          asn1Objects: toAsn1(),
        );
        return tag.toData();
    }
  }

  String base64String() => base64Encode(toData());

  // Helper methods

  static (RawBlockData, BlockSignature, bool) _blockDataV1(
    final List<ASN1Object> sequence,
  ) {
    final BigInt network = (sequence[1] as ASN1Integer).valueAsBigInteger;

    final BigInt? subnet = sequence[2] is ASN1Integer
        ? (sequence[2] as ASN1Integer).valueAsBigInteger
        : null;

    final ASN1Object anyTime = sequence[3];
    if (anyTime is! ASN1UtcTime && anyTime is! ASN1GeneralizedTime) {
      throw CustomException.invalidDate;
    }
    final DateTime dateTime = anyTime is ASN1UtcTime
        ? anyTime.dateTimeValue
        : (anyTime as ASN1GeneralizedTime).dateTimeValue;

    final Uint8List signerData = (sequence[4] as ASN1OctetString).octets;
    final Account signer = Account.fromData(signerData);

    Account account;
    if (sequence[5] is ASN1OctetString) {
      final Uint8List accountData = (sequence[5] as ASN1OctetString).octets;
      account = Account.fromData(accountData);

      if (account == signer) {
        throw CustomException.redundantAccount;
      }
    } else {
      account = signer;
    }

    final Uint8List previousHashData = (sequence[6] as ASN1OctetString).octets;
    final String previousHash = previousHashData.toHexString();

    final List<ASN1Object> operationsSequence =
        (sequence[7] as ASN1Sequence).elements;
    final List<BlockOperation> operations = operationsSequence
        .map(BlockOperationBuilder.create)
        .toList();

    final Uint8List signatureBytes = (sequence[8] as ASN1OctetString).octets;

    final bool opening = previousHash == account.publicKeyString;

    final RawBlockData rawBlock = RawBlockData(
      version: BlockVersion.v1,
      purpose: BlockPurpose.generic,
      previous: previousHash,
      network: network,
      subnet: subnet,
      signer: signer,
      account: account,
      operations: operations,
      created: dateTime.toUtc(),
    );

    return (rawBlock, SingleSignature(signatureBytes), opening);
  }

  static (RawBlockData, BlockSignature, bool) _blockDataV2(
    final List<ASN1Object> sequence,
  ) {
    final BigInt network = (sequence[0] as ASN1Integer).valueAsBigInteger;

    final BigInt? subnet = sequence[1] is ASN1Integer
        ? (sequence[1] as ASN1Integer).valueAsBigInteger
        : null;

    final int offset = subnet != null ? 0 : 1;

    final ASN1Object anyTime = sequence[2 - offset];
    if (anyTime is! ASN1UtcTime && anyTime is! ASN1GeneralizedTime) {
      throw CustomException.invalidDate;
    }
    final DateTime dateTime = anyTime is ASN1UtcTime
        ? anyTime.dateTimeValue
        : (anyTime as ASN1GeneralizedTime).dateTimeValue;

    final int purposeRaw = (sequence[3 - offset] as ASN1Integer).intValue;
    final BlockPurpose? purpose = BlockPurpose.fromRawValue(purposeRaw);
    if (purpose == null) {
      throw CustomException.invalidPurpose;
    }

    final Uint8List accountData =
        (sequence[4 - offset] as ASN1OctetString).octets;
    final Account account = Account.fromData(accountData);

    final ASN1Object signerContainer = sequence[5 - offset];
    Account signer;
    if (signerContainer is ASN1Null) {
      signer = account;
    } else if (signerContainer is ASN1OctetString) {
      final Uint8List signerData = signerContainer.octets;
      signer = Account.fromData(signerData);
    } else {
      throw Exception('Multi-signatures not implemented');
    }

    final Uint8List previousHashData =
        (sequence[6 - offset] as ASN1OctetString).octets;
    final String previousHash = previousHashData.toHexString();

    final List<ASN1Object> operationsSequence =
        (sequence[7 - offset] as ASN1Sequence).elements;
    final List<BlockOperation> operations = operationsSequence
        .map(BlockOperationBuilder.create)
        .toList();

    final ASN1Object signatureContainer = sequence[8 - offset];
    BlockSignature signature;
    if (signatureContainer is ASN1OctetString) {
      signature = SingleSignature(signatureContainer.octets);
    } else {
      throw CustomException.invalidSignature;
    }

    final bool opening = previousHash == account.publicKeyString;

    final RawBlockData rawBlock = RawBlockData(
      version: BlockVersion.v2,
      purpose: purpose,
      previous: previousHash,
      network: network,
      subnet: subnet,
      signer: signer,
      account: account,
      operations: operations,
      created: dateTime.toUtc(),
    );

    return (rawBlock, signature, opening);
  }
}
