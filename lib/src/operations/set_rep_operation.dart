import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/utils/custom_exception.dart';

class SetRepOperation extends BlockOperation {
  SetRepOperation({required this.toAccount});

  factory SetRepOperation.fromSequence(final List<ASN1Object> sequence) {
    if (sequence.length != 1) {
      throw CustomException.invalidSequenceLength;
    } else if (sequence[0] is! ASN1OctetString) {
      throw CustomException.invalidTo;
    }
    final Uint8List toData = (sequence[0] as ASN1OctetString).octets;
    final Account to = Account.fromData(toData);

    return SetRepOperation(toAccount: to.publicKeyAndType);
  }

  final BlockOperationType blockOperationType = BlockOperationType.setRep;
  final Uint8List toAccount;
  @override
  BlockOperationType get operationType => blockOperationType;

  @override
  List<ASN1Object> asn1Values() {
    final List<ASN1Object> values = <ASN1Object>[ASN1OctetString(toAccount)];
    return values;
  }
}
