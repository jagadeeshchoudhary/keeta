// import Foundation
// import BigInt

// public struct Transaction {
//     public let amount: BigInt
//     public let from: Account
//     public let to: Account
//     public let token: Account
//     public let isNetworkFee: Bool
//     public let created: Date
//     public let memo: String?
// }

import 'package:keeta/src/account_feature/account.dart';

class Transaction {
  const Transaction({
    required this.amount,
    required this.from,
    required this.to,
    required this.created,
    required this.isNetworkFee,
    this.memo,
  });

  final BigInt amount;
  final Account from;
  final Account to;
  final bool isNetworkFee;
  final DateTime created;
  final String? memo;
}
