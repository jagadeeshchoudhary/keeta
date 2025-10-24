class AccountBalance {
  const AccountBalance({
    required this.account,
    required this.rawBalances,
    this.currentHeadBlock,
  });
  final String account;
  final Map<String, BigInt> rawBalances;
  final String? currentHeadBlock;

  bool canCover({required final Map<String, BigInt> fees}) {
    for (final MapEntry<String, BigInt> entry in fees.entries) {
      final String token = entry.key;
      final BigInt feeAmount = entry.value;
      final BigInt balance = rawBalances[token] ?? BigInt.zero;
      if (balance < feeAmount) {
        return false;
      }
    }
    return true;
  }

  Map<String, double> balances(final int? Function(String token) decimal) {
    final Map<String, double> result = <String, double>{};
    for (final MapEntry<String, BigInt> entry in rawBalances.entries) {
      final String token = entry.key;
      final BigInt rawAmount = entry.value;
      final int? decimals = decimal(token);
      if (decimals != null) {
        result[token] = rawAmount.fromRaw(decimals);
      }
    }
    return result;
  }
}

extension BigIntFromRaw on BigInt {
  /// Converts a raw BigInt to a double using the given number of decimals.
  double fromRaw(final int decimals) {
    final BigInt divisor = BigInt.from(10).pow(decimals);
    return toDouble() / divisor.toDouble();
  }
}
