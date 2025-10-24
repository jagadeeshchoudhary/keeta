import 'dart:convert';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/block_feature/block_hash.dart';
import 'package:keeta/src/certificate/certificate.dart';
import 'package:keeta/src/utils/custom_exception.dart';
import 'package:keeta/src/utils/oid.dart';
import 'package:keeta/src/votes/fee.dart';

class VoteQuote {
  /// Creates a VoteQuote from base64 encoded string
  factory VoteQuote.createFromBase64({required final String base64}) {
    final Uint8List data = base64Decode(base64);
    return VoteQuote.fromData(data: Uint8List.fromList(data));
  }

  /// Creates a VoteQuote from raw data
  factory VoteQuote.fromData({required final Uint8List data}) {
    final Certificate certificate = Certificate.fromData(data: data);

    if (certificate.permanent) {
      throw CustomException.invalidPermanentVote;
    }

    // Parse extensions
    final List<String> blocks = <String>[];
    Fee? fee;

    for (final MapEntry<OID, CertificateExtension> entry
        in certificate.extensions.entries) {
      final OID oid = entry.key;
      final CertificateExtension extension = entry.value;

      switch (oid) {
        case OID.hashData:
          if (extension.data is! ASN1OctetString) {
            throw CustomException.invalidHashDataExtension;
          }

          final Uint8List blocksData = (extension.data as ASN1OctetString)
              .valueBytes();
          final ASN1Parser parser = ASN1Parser(blocksData);
          final List<ASN1Object> blocksAsn1 = <ASN1Object>[];

          while (parser.hasNext()) {
            blocksAsn1.add(parser.nextObject());
          }

          blocks.addAll(BlockHash.parse(blocksAsn1));

        case OID.fees:
          if (extension.data is! ASN1OctetString) {
            throw CustomException.invalidFeeDataExtension;
          }

          final Uint8List feeData = (extension.data as ASN1OctetString)
              .valueBytes();
          final ASN1Parser parser = ASN1Parser(feeData);
          final List<ASN1Object> feesAsn1 = <ASN1Object>[];

          while (parser.hasNext()) {
            feesAsn1.add(parser.nextObject());
          }

          fee = Fee.fromAsn1(asn1: feesAsn1);

        default:
          if (extension.critical) {
            throw CustomException.unknownCriticalExtension(oid);
          }
      }
    }

    if (fee == null) {
      throw CustomException.missingFeeExtension;
    }

    return VoteQuote._(
      certificate: certificate,
      blocks: blocks,
      fee: fee,
      data: data,
    );
  }
  const VoteQuote._({
    required this.certificate,
    required this.blocks,
    required this.fee,
    required this.data,
  });

  final Certificate certificate;
  final List<String> blocks; // Block hashes
  final Fee fee;
  final Uint8List data;

  // Convenience getters
  String get id => certificate.id;
  String get hash => certificate.hash;
  Account get issuer => certificate.issuer;
  Serial get serial => certificate.serial;
  DateTime get validityFrom => certificate.validityFrom;
  DateTime get validityTo => certificate.validityTo;
  bool get permanent => certificate.permanent;
  Uint8List get signature => certificate.signature;

  /// Returns base64 encoded string of the vote quote
  String toBase64String() => base64Encode(data);
}
