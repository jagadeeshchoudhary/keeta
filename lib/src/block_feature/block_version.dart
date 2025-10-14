import 'package:keeta/src/utils/utils.dart';

enum BlockVersion {
  v1(0),
  v2(1);

  const BlockVersion(this.rawValue);
  final int rawValue;

  BigInt get value => BigInt.from(rawValue);
  int get tag => rawValue;

  static List<BlockVersion> get all => BlockVersion.values;
  static BlockVersion get latest => all.last;

  bool operator >(final BlockVersion other) => rawValue > other.rawValue;

  static BlockVersion? fromRawValue(final int value) =>
      BlockVersion.values.firstWhere(
        (final BlockVersion v) => v.rawValue == value,
        orElse: () => throw CustomException.invalidVersion,
      );
}
