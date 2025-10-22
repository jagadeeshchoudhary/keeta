import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/utils/oid.dart';
import 'package:meta/meta.dart';

/// Represents a match result that can be either known OID or an unknown string
sealed class Match<T> {
  const Match();
}

/// A known OID match
@immutable
class Known<T> extends Match<T> {
  const Known(this.value);
  final T value;

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Known<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Known($value)';
}

/// An unknown OID string
@immutable
class Unknown<T> extends Match<T> {
  const Unknown(this.oidString);
  final String oidString;

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Unknown<T> && other.oidString == oidString;
  }

  @override
  int get hashCode => oidString.hashCode;

  @override
  String toString() => 'Unknown($oidString)';
}

/// Utility class for working with ASN.1 Distinguished Names
class ASN1DistinguishedNames {
  ASN1DistinguishedNames({required this.oid, required this.representation});

  final String oid;
  final String representation;

  /// Finds and extracts distinguished name attributes from an ASN.1 sequence
  ///
  /// Returns a map where keys are OID matches (either known or unknown)
  /// and values are the UTF8 string representations
  static Map<Match<OID>, String> find({
    required final ASN1Sequence inSequence,
  }) {
    final Map<Match<OID>, String> result = <Match<OID>, String>{};

    for (final ASN1Object sub in inSequence.elements) {
      // Each element should be a SET containing a SEQUENCE
      if (sub is! ASN1Set) {
        continue;
      }

      final Set<ASN1Object> setElements = sub.elements;
      if (setElements.isEmpty) {
        continue;
      }

      // Get the first element of the SET, which should be a SEQUENCE
      final ASN1Object firstElement = setElements.first;
      if (firstElement is! ASN1Sequence) {
        continue;
      }

      final List<ASN1Object> content = firstElement.elements;
      if (content.length < 2) {
        continue;
      }

      // First element should be an OID
      final ASN1Object tag = content[0];
      if (tag is! ASN1ObjectIdentifier) {
        continue;
      }

      final String? oidValue = tag.identifier;
      if (oidValue == null) {
        continue;
      }

      // Second element should be a UTF8String (or similar string type)
      final dynamic valueElement = content[1];
      final String? value;

      if (valueElement is ASN1UTF8String) {
        value = valueElement.utf8StringValue;
      } else if (valueElement is ASN1PrintableString) {
        value = valueElement.stringValue;
      } else if (valueElement is ASN1IA5String) {
        value = valueElement.stringValue;
      } else if (valueElement is ASN1TeletextString) {
        value = valueElement.stringValue;
      } else {
        continue;
      }

      // Try to match to a known OID
      Match<OID> match;
      try {
        final OID oid = OID.fromValue(oidValue);
        match = Known<OID>(oid);
      } catch (e) {
        match = Unknown<OID>(oidValue);
      }

      result[match] = value;
    }

    return result;
  }

  /// Quotes a string if it contains special characters
  static String quote(final String string) {
    const String specialChars = ',+=\n<>#;\\';

    final bool needsQuoting = string
        .split('')
        .any((final String char) => specialChars.contains(char));

    return needsQuoting ? '"$string"' : string;
  }
}

/// Extension to allow direct OID access on Match-keyed maps
extension OidMatchMapExtension<Value> on Map<Match<OID>, Value> {
  Value? operator [](final Object? key) {
    if (key is OID) {
      // Convert OID to Known<OID> and lookup
      for (final MapEntry<Match<OID>, Value> entry in entries) {
        if (entry.key is Known<OID> && (entry.key as Known<OID>).value == key) {
          return entry.value;
        }
      }
      return null;
    }
    // Fallback to regular map lookup for Match<OID> keys
    return (this as Map<Object?, Value>)[key];
  }

  void operator []=(final Object? key, final Value value) {
    if (key is OID) {
      // Convert OID to Known<OID> and set
      this[Known<OID>(key)] = value;
    } else if (key is Match<OID>) {
      this[key] = value;
    }
  }
}
