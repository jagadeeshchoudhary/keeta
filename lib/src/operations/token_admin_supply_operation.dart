import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/utils/utils.dart';

enum AdminSupplyAdjustMethod {
  add(0),
  subtract(1),
  set(2);

  const AdminSupplyAdjustMethod(this.rawValue);
  final int rawValue;
  static AdminSupplyAdjustMethod fromRawValue(final int value) =>
      AdminSupplyAdjustMethod.values.firstWhere(
        (final AdminSupplyAdjustMethod e) => e.rawValue == value,
        orElse: () => throw ArgumentError('Invalid key algorithm: $value'),
      );
}

class TokenAdminSupplyOperation extends BlockOperation {
  TokenAdminSupplyOperation({required this.amount, required this.method});
  factory TokenAdminSupplyOperation.fromSequence(
    final List<ASN1Object> sequence,
  ) {
    if (sequence.length != 2) {
      throw CustomException.invalidSequenceLength;
    } else if (sequence[0] is! ASN1Integer) {
      throw CustomException.invalidAmount;
    } else if (sequence[1] is! ASN1Integer &&
        AdminSupplyAdjustMethod.fromRawValue(
              (sequence[1] as ASN1Integer).intValue,
            )
            is! int) {
      throw CustomException.invalidAdjustMethod;
    }
    final BigInt amount = (sequence[0] as ASN1Integer).valueAsBigInteger;

    return TokenAdminSupplyOperation(
      amount: amount,
      method: AdminSupplyAdjustMethod.fromRawValue(
        (sequence[1] as ASN1Integer).intValue,
      ),
    );
  }
  final BlockOperationType blockOperationType =
      BlockOperationType.tokenAdminSupply;
  final BigInt amount;
  final AdminSupplyAdjustMethod method;

  @override
  BlockOperationType get operationType => blockOperationType;

  @override
  List<ASN1Object> asn1Values() {
    final List<ASN1Object> values = <ASN1Object>[
      ASN1Integer(amount),
      ASN1Integer(BigInt.from(method.rawValue)),
    ];
    return values;
  }
}
