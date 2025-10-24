import 'package:keeta/src/votes/vote_staple.dart';

class PublishResult {
  PublishResult({required this.staple, required this.fees, this.feeBlockHash});
  final VoteStaple staple;
  final List<PaidFee> fees;
  final String? feeBlockHash;

  /// Computes total fee amounts per token.
  Map<String, BigInt> get feeAmounts {
    final Map<String, BigInt> result = <String, BigInt>{};
    for (final PaidFee fee in fees) {
      result[fee.token] = (result[fee.token] ?? BigInt.zero) + fee.amount;
    }
    return result;
  }
}

class PaidFee {
  const PaidFee({required this.amount, required this.to, required this.token});
  final BigInt amount;
  final String to;
  final String token;
}
