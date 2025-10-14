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
