enum BlockPurpose {
  generic(0),
  fee(1);

  const BlockPurpose(this.rawValue);
  final int rawValue;

  BigInt get value => BigInt.from(rawValue);

  static BlockPurpose? fromRawValue(final int value) {
    try {
      return BlockPurpose.values.firstWhere(
        (final BlockPurpose p) => p.rawValue == value,
      );
    } catch (_) {
      return null;
    }
  }
}
