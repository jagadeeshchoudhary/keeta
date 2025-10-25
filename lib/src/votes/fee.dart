import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/utils/custom_exception.dart';

/*
 FeeData ::= [0] EXPLICIT SEQUENCE {
     -- TRUE = QUOTE, FALSE = VOTE
     quote        BOOLEAN,
     -- Amount to modify the balance by
     amount      INTEGER,
     -- Pay To Account
     payTo       [0] IMPLICIT OCTET STRING OPTIONAL,
     -- Token Account
     token       [1] IMPLICIT OCTET STRING OPTIONAL
 }
 */

class Fee {
  const Fee({
    required this.quote,
    required this.amount,
    this.payTo,
    this.token,
  });

  /// Creates a Fee from raw data
  factory Fee.fromData({required final Uint8List data}) {
    final ASN1Parser parser = ASN1Parser(data);
    final List<ASN1Object> asn1Objects = <ASN1Object>[];

    while (parser.hasNext()) {
      asn1Objects.add(parser.nextObject());
    }

    return Fee.fromAsn1(asn1: asn1Objects);
  }

  /// Creates a Fee from ASN1 objects
  factory Fee.fromAsn1({required final List<ASN1Object> asn1}) {
    if (asn1.isEmpty) {
      throw CustomException.invalidContextSpecificTag;
    }

    final ASN1Object first = asn1.first;

    // Check if tag is context-specific with tag number 0
    // Context-specific class: 0x80, constructed: 0x20
    if ((first.tag & 0xC0) != 0x80 || (first.tag & 0x1F) != 0) {
      throw CustomException.invalidContextSpecificTag;
    }

    // Parse the inner sequence from the tagged value
    final Uint8List taggedValue = first.valueBytes();
    final ASN1Parser innerParser = ASN1Parser(taggedValue);
    final ASN1Object innerObject = innerParser.nextObject();

    if (innerObject is! ASN1Sequence) {
      throw CustomException.invalidASN1Sequence;
    }

    final ASN1Sequence sequence = innerObject;

    if (sequence.elements.length < 2 || sequence.elements.length > 4) {
      throw CustomException.invalidASN1SequenceLength;
    }

    // Parse quote (BOOLEAN)
    final ASN1Object quoteElement = sequence.elements[0];
    if (quoteElement is! ASN1Boolean) {
      throw CustomException.invalidQuote;
    }
    final bool quote = quoteElement.booleanValue;

    // Parse amount (INTEGER)
    final ASN1Object amountElement = sequence.elements[1];
    if (amountElement is! ASN1Integer) {
      throw CustomException.invalidAmount;
    }
    final BigInt amount = amountElement.valueAsBigInteger;

    // Parse optional payTo and token (implicit tags)
    Account? payTo;
    Account? token;

    for (int tagIndex = 2; tagIndex < sequence.elements.length; tagIndex++) {
      final ASN1Object element = sequence.elements[tagIndex];

      // Check for implicit context-specific tags
      if ((element.tag & 0xC0) == 0x80) {
        final int implicitTag = element.tag & 0x1F;

        switch (implicitTag) {
          case 0:
            payTo = Account.fromData(element.valueBytes());
          case 1:
            token = Account.fromData(element.valueBytes());
          default:
            throw CustomException.invalidImplicitTag;
        }
      }
    }

    return Fee(quote: quote, amount: amount, payTo: payTo, token: token);
  }

  final bool quote;
  final BigInt amount;
  final Account? payTo;
  final Account? token;

  @override
  String toString() =>
      'Fee(quote: $quote, amount: $amount, payTo: $payTo, token: $token)';
}
