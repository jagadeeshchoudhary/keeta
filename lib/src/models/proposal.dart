import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/account_feature/account_builder.dart';

class Proposal {
  const Proposal({required this.amount, required this.token});

  factory Proposal.fromAccount({
    required final double amount,
    required final Account token,
  }) => Proposal(amount: BigInt.from(amount), token: token);

  factory Proposal.fromTokenPubkey({
    required final double amount,
    required final String token,
  }) => Proposal(
    amount: BigInt.from(amount),
    token: AccountBuilder.createFromPublicKey(publicKey: token),
  );
  final BigInt amount;
  final Account token;
}
