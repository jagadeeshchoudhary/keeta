import 'package:asn1lib/asn1lib.dart';

enum BaseFlag {
  access(0x0001),
  owner(0x0002),
  admin(0x0004),
  updateInfo(0x0008),
  sendOnBehalf(0x0010),
  storageCreate(0x0100),
  tokenAdminCreate(0x0020),
  tokenAdminSupply(0x0040),
  tokenAdminModifySupply(0x0080),
  storageCanHold(0x0200),
  storageDeposit(0x0400),
  permissionDelegateAdd(0x0800),
  permissionDelegateRemove(0x1000);

  const BaseFlag(this.value);
  final int value;

  BigInt get bigIntValue => BigInt.from(value);

  static BaseFlag? fromRawValue(final int value) {
    try {
      return BaseFlag.values.firstWhere((final BaseFlag p) => p.value == value);
    } catch (_) {
      return null;
    }
  }
}

class Permission {
  const Permission({required this.baseFlag});
  final BaseFlag? baseFlag;

  List<ASN1Object> asn1Values() => <ASN1Object>[
    ASN1Integer(baseFlag!.bigIntValue),
    ASN1Integer(BigInt.zero),
  ];
}
