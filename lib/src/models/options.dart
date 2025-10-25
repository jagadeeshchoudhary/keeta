import 'package:keeta/src/account_feature/account.dart';

class Options {
  const Options({this.idempotency, this.signer, this.feeAccount, this.memo});
  final String? idempotency;
  final Account? signer;
  final Account? feeAccount;
  final String? memo;
}
