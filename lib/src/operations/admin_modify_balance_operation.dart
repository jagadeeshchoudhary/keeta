import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/operations/admin_supply_adjust_method.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/utils/utils.dart';

class TokenAdminModifyBalanceOperation extends BlockOperation {
  TokenAdminModifyBalanceOperation({
    required this.token,
    required this.amount,
    required this.method,
  });

  factory TokenAdminModifyBalanceOperation.fromSequence(
    final List<ASN1Object> sequence,
  ) {
    if (sequence.length != 3) {
      throw CustomException.invalidSequenceLength;
    } else if (sequence[0] is! ASN1OctetString) {
      throw CustomException.invalidTo;
    } else if (sequence[1] is! ASN1Integer) {
      throw CustomException.invalidAmount;
    } else if (sequence[2] is! ASN1OctetString &&
        AdminSupplyAdjustMethod.fromRawValue(
              (sequence[2] as ASN1Integer).intValue,
            )
            is! int) {
      throw CustomException.invalidAdjustMethod;
    }
    final Uint8List tokenData = (sequence[0] as ASN1OctetString).octets;
    final Account token = Account.fromData(tokenData);
    final BigInt amount = (sequence[1] as ASN1Integer).valueAsBigInteger;

    return TokenAdminModifyBalanceOperation(
      amount: amount,
      token: token.publicKeyAndType,
      method: AdminSupplyAdjustMethod.fromRawValue(
        (sequence[1] as ASN1Integer).intValue,
      ),
    );
  }

  final BlockOperationType blockOperationType =
      BlockOperationType.tokenAdminModifyBalance;
  final Uint8List token;
  final BigInt amount;
  final AdminSupplyAdjustMethod method;

  @override
  BlockOperationType get operationType => blockOperationType;

  @override
  List<ASN1Object> asn1Values() {
    final List<ASN1Object> values = <ASN1Object>[
      ASN1OctetString(token),
      ASN1Integer(amount),
      ASN1Integer(BigInt.from(method.rawValue)),
    ];

    return values;
  }
}
