import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/account_feature/key_algorithm.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/utils/utils.dart';

class CreateIdentifierOperation {
  CreateIdentifierOperation({required this.identifier});
  factory CreateIdentifierOperation.fromSequence(
    final List<ASN1Object> sequence,
  ) {
    if (sequence.length != 1) {
      throw CustomException.invalidSequenceLength;
    } else if (sequence[0] is! ASN1OctetString) {
      throw CustomException.invalidIdentifier;
    }
    final Uint8List identifierData = (sequence[0] as ASN1OctetString).octets;
    final Account identifier = Account.fromData(identifierData);

    if (identifier.keyAlgorithm == KeyAlgorithm.ecdsaSecp256k1 ||
        identifier.keyAlgorithm == KeyAlgorithm.ed25519) {
      throw CustomException.invalidIdentifierAlgorithm;
    }

    return CreateIdentifierOperation(identifier: identifier.publicKeyAndType);
  }
  final BlockOperationType blockOperationType =
      BlockOperationType.createIdentifier;
  final Uint8List identifier;
}
