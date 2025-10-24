import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/account_feature/account_builder.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/utils/custom_exception.dart';

/*
 -- SEND operation
         send [0] SEQUENCE {
             -- Destination account to send to
             to          OCTET STRING,
             -- Amount of the token to send
             amount      INTEGER,
             -- Token ID to send
             token       OCTET STRING,
             -- External reference field (optional)
             external    UTF8String OPTIONAL
         }
 */
class SendOperation extends BlockOperation {
  SendOperation({
    required this.amount,
    required this.toAccount,
    required this.token,
    this.external,
  }) {
    if (amount <= BigInt.zero) {
      throw CustomException.invalidAmount;
    }
  }

  /// Creates a SendOperation from public key strings
  factory SendOperation.fromPublicKeys({
    required final BigInt amount,
    required final String toAccountPubKey,
    required final String tokenPubKey,
    final String? external,
  }) {
    final Account account = AccountBuilder.createFromPublicKey(
      publicKey: toAccountPubKey,
    );
    final Account token = AccountBuilder.createFromPublicKey(
      publicKey: tokenPubKey,
    );

    return SendOperation.fromAccounts(
      amount: amount,
      toAccount: account,
      token: token,
      external: external,
    );
  }

  /// Creates a SendOperation from Account objects
  factory SendOperation.fromAccounts({
    required final BigInt amount,
    required final Account toAccount,
    required final Account token,
    final String? external,
  }) => SendOperation(
    amount: amount,
    toAccount: toAccount.publicKeyAndType,
    token: token.publicKeyAndType,
    external: external,
  );

  /// Creates a SendOperation from ASN.1 sequence
  factory SendOperation.fromSequence(final List<ASN1Object> sequence) {
    if (sequence.length < 3 || sequence.length > 4) {
      throw CustomException.invalidSequenceLength;
    }

    if (sequence[0] is! ASN1OctetString) {
      throw CustomException.invalidTo;
    }

    if (sequence[1] is! ASN1Integer) {
      throw CustomException.invalidAmount;
    }

    if (sequence[2] is! ASN1OctetString) {
      throw CustomException.invalidToken;
    }

    final Uint8List toData = (sequence[0] as ASN1OctetString).valueBytes();
    final Account to = Account.fromData(toData);

    final BigInt amount = (sequence[1] as ASN1Integer).valueAsBigInteger;

    final Uint8List tokenData = (sequence[2] as ASN1OctetString).valueBytes();
    final Account token = Account.fromData(tokenData);

    final String? external;
    if (sequence.length == 4) {
      if (sequence[3] is ASN1UTF8String) {
        external = (sequence[3] as ASN1UTF8String).utf8StringValue;
      } else {
        external = null;
      }
    } else {
      external = null;
    }

    return SendOperation.fromAccounts(
      amount: amount,
      toAccount: to,
      token: token,
      external: external,
    );
  }

  final BlockOperationType blockOperationType = BlockOperationType.send;
  final BigInt amount;
  final Uint8List toAccount;
  final Uint8List token;
  final String? external;

  @override
  BlockOperationType get operationType => blockOperationType;

  @override
  List<ASN1Object> asn1Values() {
    final List<ASN1Object> values = <ASN1Object>[
      ASN1OctetString(to),
      ASN1Integer(amount),
      ASN1OctetString(token),
    ];

    if (external != null) {
      values.add(ASN1UTF8String(external!));
    }

    return values;
  }
}
