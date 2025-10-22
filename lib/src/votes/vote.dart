import 'dart:convert';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/block_feature/block_hash.dart';
import 'package:keeta/src/certificate/certificate.dart';
import 'package:keeta/src/utils/custom_exception.dart';
import 'package:keeta/src/utils/oid.dart';
import 'package:keeta/src/votes/fee.dart';

/*
 -- Votes are X.509v3 Certificates with additional information 
 stored within the extensions
 
 -- Extensions
 extensions     [3] EXPLICIT SEQUENCE {
     -- Block hashes being voted for, as an extension
     hashDataExtension SEQUENCE {
         -- Hash Data
         extensionID OBJECT IDENTIFIER ( hashData ),
         -- Critical
         critical    BOOLEAN ( TRUE ),
         -- Data
         dataWrapper OCTET STRING (CONTAINING [0] EXPLICIT SEQUENCE {
             -- Hash Algorithm
             hashAlgorithm OBJECT IDENTIFIER,
             -- Block hashes
             hashes       SEQUENCE OF OCTET STRING
         })
     }
 }
 */

class Vote {
  /// Creates a Vote from base64 encoded string
  factory Vote.createFromBase64({required final String base64}) {
    final Uint8List data = base64Decode(base64);
    return Vote.fromData(data: Uint8List.fromList(data));
  }

  /// Creates a Vote from raw data
  factory Vote.fromData({required final Uint8List data}) {
    final Certificate certificate = Certificate.fromData(data: data);

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

    if (fee != null && certificate.permanent) {
      throw CustomException.permanentVoteCanNotHaveFees;
    }

    return Vote._(
      certificate: certificate,
      blocks: blocks,
      fee: fee,
      data: data,
    );
  }
  const Vote._({
    required this.certificate,
    required this.blocks,
    required this.fee,
    required this.data,
  });

  final Certificate certificate;
  final List<String> blocks; // Block hashes
  final Fee? fee;
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

  /// Returns the raw data of the vote
  Uint8List toData() => data;

  /// Returns base64 encoded string of the vote
  String toBase64String() => base64Encode(data);
}

/// Extension methods for List of votes
extension VoteListExtensions on List<Vote> {
  /// Returns all fees from votes that have fees
  List<Fee> get fees => where(
    (final Vote vote) => vote.fee != null,
  ).map((final Vote vote) => vote.fee!).toList();

  /// Returns true if any vote requires fees
  bool get requiresFees => any((final Vote vote) => vote.fee != null);
}
