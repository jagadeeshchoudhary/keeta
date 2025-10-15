import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/block_feature/permission.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/utils/custom_exception.dart';

class SetInfoOperation extends BlockOperation {
  SetInfoOperation({
    required this.name,
    this.description = '',
    this.metaData = '',
    this.defaultPermission,
  });

  factory SetInfoOperation.fromSequence(final List<ASN1Object> sequence) {
    if (sequence.length != 3 && sequence.length != 4) {
      throw CustomException.invalidSequenceLength;
    } else if (sequence[0] is! ASN1UTF8String) {
      throw CustomException.invalidName;
    } else if (sequence[1] is! ASN1UTF8String) {
      throw CustomException.invalidDescription;
    } else if (sequence[2] is! ASN1UTF8String) {
      throw CustomException.metaData;
    } else if (sequence.length == 4 && sequence[3] is! ASN1Sequence) {
      throw CustomException.invalidSequence;
    }
    final String name = (sequence[0] as ASN1UTF8String).utf8StringValue;
    final String description = (sequence[1] as ASN1UTF8String).utf8StringValue;
    final String metaData = (sequence[2] as ASN1UTF8String).utf8StringValue;
    Permission? permission;
    if (sequence.length == 4) {
      final List<ASN1Object> permissionSeq =
          (sequence[3] as ASN1Sequence).elements;
      if (permissionSeq.length != 2) {
        throw CustomException.invalidPermissionSequenceLength;
      } else if (permissionSeq[0] is! ASN1Integer) {
        throw CustomException.invalidPermissionFlags;
      }

      final int baseFlagValue = (permissionSeq[0] as ASN1Integer).intValue;
      final BaseFlag? baseFlag = BaseFlag.fromRawValue(baseFlagValue);

      if (baseFlag == null) {
        throw CustomException.unknownPermissionFlag;
      } else {
        permission = Permission(baseFlag: baseFlag);
      }
    }

    return SetInfoOperation(
      name: name,
      description: description,
      metaData: metaData,
      defaultPermission: permission,
    );
  }

  final BlockOperationType blockOperationType = BlockOperationType.setInfo;
  final String name;
  final String description;
  final String metaData;
  final Permission? defaultPermission;

  @override
  BlockOperationType get operationType => blockOperationType;

  @override
  List<ASN1Object> asn1Values() {
    final List<ASN1Object> values = <ASN1Object>[
      ASN1UTF8String(name),
      ASN1UTF8String(description),
      ASN1UTF8String(metaData),
    ];
    if (defaultPermission != null) {
      values.add(
        ASN1Sequence()..elements.addAll(defaultPermission!.asn1Values()),
      );
    }
    return values;
  }
}
