import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/utils/custom_exception.dart';

class SendOperation extends BlockOperation {
  SendOperation({
    required this.amount,
    required this.toAccount,
    required this.token,
    this.external,
  }) {
    if (amount <= BigInt.zero) {
      throw CustomException.invalidAmount;
    }
  }

  factory SendOperation.fromSequence(final List<ASN1Object> sequence) {
    if (sequence.length != 3 || sequence.length != 4) {
      throw CustomException.invalidSequenceLength;
    } else if (sequence[0] is! ASN1OctetString) {
      throw CustomException.invalidTo;
    } else if (sequence[1] is! ASN1Integer) {
      throw CustomException.invalidAmount;
    } else if (sequence[2] is! ASN1OctetString) {
      throw CustomException.invalidToken;
    }
    final Uint8List toData = (sequence[0] as ASN1OctetString).octets;
    final Account to = Account.fromData(toData);
    final BigInt amount = (sequence[1] as ASN1Integer).valueAsBigInteger;
    final Uint8List tokenData = (sequence[2] as ASN1OctetString).octets;
    final Account token = Account.fromData(tokenData);
    final String? external =
        sequence.length == 4 && sequence[3] is ASN1UTF8String
        ? (sequence[3] as ASN1UTF8String).utf8StringValue
        : null;

    return SendOperation(
      amount: amount,
      toAccount: to.publicKeyAndType,
      token: token.publicKeyAndType,
      external: external,
    );
  }
  
  final BlockOperationType blockOperationType = BlockOperationType.send;
  final BigInt amount;
  final Uint8List toAccount;
  final Uint8List token;
  final String? external;

  @override
  BlockOperationType get operationType => blockOperationType;

  @override
  List<ASN1Object> asn1Values() {
    final List<ASN1Object> values = <ASN1Object>[
      ASN1OctetString(toAccount),
      ASN1Integer(amount),
      ASN1OctetString(token),
    ];
    if (external != null) {
      values.add(ASN1UTF8String(external!));
    }
    return values;
  }
}
