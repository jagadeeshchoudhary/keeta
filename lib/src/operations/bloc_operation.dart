import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/utils/utils.dart';

/// ------------------- BlockOperation -------------------
abstract class BlockOperation {
  const BlockOperation();

  /// Constructs an instance from ASN.1 sequence
  factory BlockOperation.fromSequence(final List<ASN1Object> _) {
    // This factory constructor needs to be implemented by concrete classes
    // to handle the different BlockOperationType.
    throw UnimplementedError('Not  implemented.');
  }
  BlockOperationType get operationType;

  /// Returns ASN.1 encoded values for the operation
  List<ASN1Object> asn1Values();

  T to<T extends BlockOperation>(
    final T Function(List<ASN1Object>) fromSequence,
  ) {
    final List<ASN1Object> values = asn1Values();
    // Call T.fromSequence. Each subclass must implement it
    return fromSequence(values);
  }

  /// Returns a context-specific tagged ASN1Object
  ASN1Object tagged() {
    final List<ASN1Object> values = asn1Values();
    final TaggedValue tagged = TaggedValue.contextSpecific(
      tag: operationType.rawValue,
      asn1Objects: values,
    );
    return ASN1OctetString(tagged.toData());
  }
}
