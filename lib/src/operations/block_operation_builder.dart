import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/operations/admin_modify_balance_operation.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/operations/create_identifier_operation.dart';
import 'package:keeta/src/operations/receive_operation.dart';
import 'package:keeta/src/operations/send_operation.dart';
import 'package:keeta/src/operations/set_info_operation.dart';
import 'package:keeta/src/operations/set_rep_operation.dart';
import 'package:keeta/src/operations/token_admin_supply_operation.dart';
import 'package:keeta/src/utils/custom_exception.dart';

mixin BlockOperationBuilder {
  static BlockOperation create(final ASN1Object asn1) {
    // Expect the ASN1OctetString that wraps the tagged operation
    if (asn1 is! ASN1OctetString) {
      throw CustomException.invalidTag;
    }

    // Extract the inner encoded data
    final Uint8List taggedData = asn1.octets;
    final ASN1Parser taggedParser = ASN1Parser(taggedData);
    final ASN1Object taggedObject = taggedParser.nextObject();

    // Get the tag (operation type)
    final int operationTypeRaw = taggedObject.tag;

    final BlockOperationType? type = _blockOperationTypeFromRawValue(
      operationTypeRaw,
    );
    if (type == null) {
      throw CustomException.invalidOperationType;
    }

    // Parse the content bytes (may contain a sequence)
    ASN1Object? inner;
    try {
      final ASN1Parser parser = ASN1Parser(taggedObject.encodedBytes);
      inner = parser.nextObject();
    } catch (_) {
      throw CustomException.invalidSequence;
    }

    // Ensure it's a valid sequence
    if (inner is! ASN1Sequence || inner.elements.isEmpty) {
      throw CustomException.invalidSequence;
    }

    final List<ASN1Object> sequence = inner.elements;

    // Construct the correct operation
    switch (type) {
      case BlockOperationType.send:
        return SendOperation.fromSequence(sequence);
      case BlockOperationType.setRep:
        return SetRepOperation.fromSequence(sequence);
      case BlockOperationType.tokenAdminSupply:
        return TokenAdminSupplyOperation.fromSequence(sequence);
      case BlockOperationType.createIdentifier:
        return CreateIdentifierOperation.fromSequence(sequence);
      case BlockOperationType.tokenAdminModifyBalance:
        return TokenAdminModifyBalanceOperation.fromSequence(sequence);
      case BlockOperationType.setInfo:
        return SetInfoOperation.fromSequence(sequence);
      case BlockOperationType.receive:
        return ReceiveOperation.fromSequence(sequence);
    }
  }

  static BlockOperationType? _blockOperationTypeFromRawValue(final int value) {
    if (value < 0 || value >= BlockOperationType.values.length) {
      return null;
    } else {
      return BlockOperationType.values[value];
    }
  }
}
