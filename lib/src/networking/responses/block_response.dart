import 'package:keeta/src/utils/custom_exception.dart';

class BlockResponse {
  const BlockResponse({required this.block, this.blockhash});

  factory BlockResponse.fromJson(final Map<String, dynamic> json) =>
      BlockResponse(
        blockhash: json['blockhash'] as String?,
        block: BlockContentResponse.fromJson(
          json['block'] as Map<String, dynamic>,
        ),
      );

  final String? blockhash;
  final BlockContentResponse block;
}

class PendingBlockResponse {
  const PendingBlockResponse({required this.account, this.block});

  factory PendingBlockResponse.fromJson(final Map<String, dynamic> json) {
    final Map<String, dynamic>? blockJson =
        json['block'] as Map<String, dynamic>?;
    return PendingBlockResponse(
      account: json['account'] as String,
      block: blockJson != null
          ? BlockContentResponse.fromJson(blockJson)
          : null,
    );
  }

  final String account;
  final BlockContentResponse? block;
}

sealed class BlockContentResponse {
  factory BlockContentResponse.fromJson(final Map<String, dynamic> json) {
    // Try latest version first (V2)
    try {
      return BlockContentResponseV2.fromJson(json);
    } catch (_) {
      // Try V1
      try {
        return BlockContentResponseV1.fromJson(json);
      } catch (_) {
        throw const CustomException.blockContentDecodingError(
          'Data did not match BlockContentResponseV1 or BlockContentResponseV2',
        );
      }
    }
  }
  const BlockContentResponse._();

  String get hash;
  String? get idempotent;
  String get binary;
}

class BlockContentResponseV2 extends BlockContentResponse {
  const BlockContentResponseV2({
    required this.hash,
    required this.signer,
    required this.signatures,
    required this.binary,
    this.idempotent,
  }) : super._();

  factory BlockContentResponseV2.fromJson(final Map<String, dynamic> json) {
    final List<dynamic> signaturesJson = json['signatures'] as List<dynamic>;
    return BlockContentResponseV2(
      hash: json[r'$hash'] as String,
      idempotent: json['idempotent'] as String?,
      signer: json['signer'] as String,
      signatures: signaturesJson
          .map((final dynamic item) => item as String)
          .toList(),
      binary: json[r'$binary'] as String,
    );
  }

  @override
  final String hash;
  @override
  final String? idempotent;
  final String signer;
  final List<String> signatures;
  @override
  final String binary;
}

class BlockContentResponseV1 extends BlockContentResponse {
  const BlockContentResponseV1({
    required this.hash,
    required this.signer,
    required this.signature,
    required this.binary,
    this.idempotent,
  }) : super._();

  factory BlockContentResponseV1.fromJson(final Map<String, dynamic> json) =>
      BlockContentResponseV1(
        hash: json[r'$hash'] as String,
        idempotent: json['idempotent'] as String?,
        signer: json['signer'] as String,
        signature: json['signature'] as String,
        binary: json[r'$binary'] as String,
      );

  @override
  final String hash;
  @override
  final String? idempotent;
  final String signer;
  final String signature;
  @override
  final String binary;
}
