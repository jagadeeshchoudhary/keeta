import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/utils/custom_exception.dart';

class ReceiveOperation extends BlockOperation {
  ReceiveOperation({
    required this.amount,
    required this.exact,
    required this.token,
    required this.from,
    this.forward,
  }) {
    if (forward == from) {
      throw CustomException.cantForwardtoSameAccount;
    } else if (forward != null && !exact) {
      throw CustomException.invalidExactWhenForwarding;
    }
  }

  factory ReceiveOperation.fromSequence(final List<ASN1Object> sequence) {
    if (sequence.length != 4 && sequence.length != 5) {
      throw CustomException.invalidSequenceLength;
    } else if (sequence[0] is! ASN1Integer) {
      throw CustomException.invalidAmount;
    } else if (sequence[1] is! ASN1OctetString) {
      throw CustomException.invalidToken;
    } else if (sequence[2] is! ASN1OctetString) {
      throw CustomException.invalidFrom;
    } else if (sequence.length == 4 && sequence[3] is! ASN1Boolean) {
      throw CustomException.invalidExact;
    }
    final BigInt amount = (sequence[0] as ASN1Integer).valueAsBigInteger;
    final Uint8List tokenData = (sequence[1] as ASN1OctetString).octets;
    final Account token = Account.fromData(tokenData);
    final Uint8List fromData = (sequence[2] as ASN1OctetString).octets;
    final Account from = Account.fromData(fromData);
    final bool exact = (sequence[3] as ASN1Boolean).booleanValue;
    Account? forward;
    if (sequence.length == 5) {
      final Uint8List forwardData = (sequence[4] as ASN1OctetString).octets;
      forward = Account.fromData(fromData);
    } else {
      forward = null;
    }

    return ReceiveOperation(
      amount: amount,
      token: token.publicKeyAndType,
      from: from.publicKeyAndType,
      exact: exact,
      forward: forward?.publicKeyAndType,
    );
  }

  final BlockOperationType blockOperationType = BlockOperationType.receive;
  final BigInt amount;
  final bool exact;
  final Uint8List token;
  final Uint8List from;
  final Uint8List? forward;

  @override
  BlockOperationType get operationType => blockOperationType;

  @override
  List<ASN1Object> asn1Values() {
    final List<ASN1Object> values = <ASN1Object>[
      ASN1Integer(amount),
      ASN1OctetString(token),
      ASN1OctetString(from),
      ASN1Boolean(exact),
    ];
    if (forward != null) {
      values.add(ASN1OctetString(forward));
    }
    return values;
  }
}
