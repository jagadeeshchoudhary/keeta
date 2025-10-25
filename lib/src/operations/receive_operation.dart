import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/account_feature/account_builder.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/utils/custom_exception.dart';

/*
 -- RECEIVE operation
         receive [7] SEQUENCE {
             -- Amount to receive
             amount      INTEGER,
             -- Token to receive
             token       OCTET STRING,
             -- Sender from which to receive
             from        OCTET STRING,
             -- Whether the received amount must match
             -- exactly (true) or just be greater than or
             -- equal to the amount (false)
             exact       BOOLEAN,
             -- Forward the received amount to another
             -- account (optional)
             forward     OCTET STRING OPTIONAL
         }
 */
class ReceiveOperation extends BlockOperation {
  ReceiveOperation({
    required this.amount,
    required this.exact,
    required this.token,
    required this.from,
    this.forward,
  }) {
    // Cannot forward to the from account
    if (forward != null && _bytesEqual(forward!, from)) {
      throw CustomException.cantForwardToFromAccount;
    }

    // Exact must be true when forwarding a receive
    if (forward != null && !exact) {
      throw CustomException.invalidExactWhenForwarding;
    }
  }

  /// Creates a ReceiveOperation from public key strings
  factory ReceiveOperation.fromPublicKeys({
    required final BigInt amount,
    required final String tokenPubKey,
    required final String fromPubKey,
    required final bool exact,
    final String? forwardPubKey,
  }) {
    final Account token = AccountBuilder.createFromPublicKey(
      publicKey: tokenPubKey,
    );
    final Account from = AccountBuilder.createFromPublicKey(
      publicKey: fromPubKey,
    );
    final Account? forward = forwardPubKey != null
        ? AccountBuilder.createFromPublicKey(publicKey: forwardPubKey)
        : null;

    return ReceiveOperation.fromAccounts(
      amount: amount,
      token: token,
      from: from,
      exact: exact,
      forward: forward,
    );
  }

  /// Creates a ReceiveOperation from Account objects
  factory ReceiveOperation.fromAccounts({
    required final BigInt amount,
    required final Account token,
    required final Account from,
    required final bool exact,
    final Account? forward,
  }) => ReceiveOperation(
    amount: amount,
    token: token.publicKeyAndType,
    from: from.publicKeyAndType,
    exact: exact,
    forward: forward?.publicKeyAndType,
  );

  /// Creates a ReceiveOperation from ASN.1 sequence
  factory ReceiveOperation.fromSequence(final List<ASN1Object> sequence) {
    if (sequence.length < 4 || sequence.length > 5) {
      throw CustomException.invalidSequenceLength;
    }

    if (sequence[0] is! ASN1Integer) {
      throw CustomException.invalidAmount;
    }

    if (sequence[1] is! ASN1OctetString) {
      throw CustomException.invalidToken;
    }

    if (sequence[2] is! ASN1OctetString) {
      throw CustomException.invalidFrom;
    }

    if (sequence[3] is! ASN1Boolean) {
      throw CustomException.invalidExact;
    }

    final BigInt amount = (sequence[0] as ASN1Integer).valueAsBigInteger;

    final Uint8List tokenData = (sequence[1] as ASN1OctetString).valueBytes();
    final Account token = Account.fromData(tokenData);

    final Uint8List fromData = (sequence[2] as ASN1OctetString).valueBytes();
    final Account from = Account.fromData(fromData);

    final bool exact = (sequence[3] as ASN1Boolean).booleanValue;

    final Account? forward;
    if (sequence.length == 5) {
      if (sequence[4] is! ASN1OctetString) {
        throw CustomException.invalidForward;
      }
      final Uint8List forwardData = (sequence[4] as ASN1OctetString)
          .valueBytes();
      forward = Account.fromData(forwardData);
    } else {
      forward = null;
    }

    return ReceiveOperation.fromAccounts(
      amount: amount,
      token: token,
      from: from,
      exact: exact,
      forward: forward,
    );
  }

  final BlockOperationType blockOperationType = BlockOperationType.receive;
  final BigInt amount;
  final bool exact;
  final Uint8List token;
  final Uint8List from;
  final Uint8List? forward;

  @override
  BlockOperationType get operationType => blockOperationType;

  @override
  List<ASN1Object> asn1Values() {
    final List<ASN1Object> values = <ASN1Object>[
      ASN1Integer(amount),
      ASN1OctetString(token),
      ASN1OctetString(from),
      ASN1Boolean(exact),
    ];

    if (forward != null) {
      values.add(ASN1OctetString(forward));
    }

    return values;
  }

  /// Helper method to compare byte arrays
  static bool _bytesEqual(final Uint8List a, final Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
