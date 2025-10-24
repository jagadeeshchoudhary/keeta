import 'package:keeta/src/account_feature/account.dart';

class NetworkSendTransaction {
  const NetworkSendTransaction({
    required this.id,
    required this.blockHash,
    required this.amount,
    required this.from,
    required this.to,
    required this.token,
    required this.isIncoming,
    required this.isNetworkFee,
    required this.created,
    this.memo,
  });

  final String id;
  final String blockHash;
  final BigInt amount;
  final Account from;
  final Account to;
  final Account token;
  final bool isIncoming;
  final bool isNetworkFee;
  final DateTime created;
  final String? memo;
}
