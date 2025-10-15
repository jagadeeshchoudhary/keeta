class AccountBalance {
  const AccountBalance({
    required this.account,
    required this.balances,
    this.currentHeadBlock,
  });
  final String account;
  final Map<String, BigInt> balances;
  final String? currentHeadBlock;

  bool canCover(final Map<String, BigInt> fees) {
    for (final MapEntry<String, BigInt> entry in fees.entries) {
      final String token = entry.key;
      final BigInt feeAmount = entry.value;
      final BigInt balance = balances[token] ?? BigInt.zero;
      if (balance < feeAmount) {
        return false;
      }
    }
    return true;
  }
}
