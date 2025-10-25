import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/account_feature/account_balance.dart';
import 'package:keeta/src/account_feature/account_builder.dart';
import 'package:keeta/src/account_feature/account_feature.dart';
import 'package:keeta/src/block_feature/block.dart';
import 'package:keeta/src/block_feature/block_builder.dart';
import 'package:keeta/src/block_feature/block_purpose.dart';
import 'package:keeta/src/block_feature/block_version.dart';
import 'package:keeta/src/block_feature/permission.dart';
import 'package:keeta/src/models/network_send_transaction.dart';
import 'package:keeta/src/models/options.dart';
import 'package:keeta/src/models/proposal.dart';
import 'package:keeta/src/networking/keeta_api.dart';
import 'package:keeta/src/networking/network_alias.dart';
import 'package:keeta/src/networking/network_config.dart';
import 'package:keeta/src/networking/publish_result.dart';
import 'package:keeta/src/operations/admin_supply_adjust_method.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/operations/create_identifier_operation.dart';
import 'package:keeta/src/operations/receive_operation.dart';
import 'package:keeta/src/operations/send_operation.dart';
import 'package:keeta/src/operations/set_info_operation.dart';
import 'package:keeta/src/operations/token_admin_supply_operation.dart';
import 'package:keeta/src/utils/utils.dart';
import 'package:keeta/src/votes/vote.dart';
import 'package:keeta/src/votes/vote_staple.dart';
import 'package:uuid/uuid.dart';

class KeetaClient {
  factory KeetaClient.withConfig({
    required final NetworkConfig config,
    final BlockVersion version = BlockVersion.v2,
    final Account? account,
    final Account? feeAccount,
  }) {
    final KeetaApi api = KeetaApi.fromConfig(config: config);
    return KeetaClient._(
      api: api,
      config: config,
      version: version,
      account: account,
      feeAccount: feeAccount,
    );
  }

  factory KeetaClient.withNetworkAndFeeAccount({
    required final NetworkAlias network,
    final BlockVersion version = BlockVersion.v2,
    final Account? account,
    final Account? feeAccount,
  }) {
    final NetworkConfig config = NetworkConfig.create(forNetwork: network);
    return KeetaClient.withConfig(
      config: config,
      version: version,
      account: account,
      feeAccount: feeAccount,
    );
  }

  factory KeetaClient.withNetwork({
    required final NetworkAlias network,
    required final Account account,
    final BlockVersion version = BlockVersion.v2,
    final bool usedToPayFees = true,
  }) => KeetaClient.withNetworkAndFeeAccount(
    network: network,
    version: version,
    account: account,
    feeAccount: usedToPayFees ? account : null,
  );

  KeetaClient._({
    required this.api,
    required this.config,
    required this.version,
    this.account,
    this.feeAccount,
  });
  final KeetaApi api;
  final NetworkConfig config;
  final BlockVersion version;
  final Account? account;
  Account? feeAccount;

  // MARK: Send

  Future<PublishResult> send({
    required final BigInt amount,
    required final String to,
    final Options? options,
  }) {
    final Account toAccount = AccountBuilder.createFromPublicKey(publicKey: to);
    return sendToAccount(amount: amount, to: toAccount, options: options);
  }

  Future<PublishResult> sendToAccount({
    required final BigInt amount,
    required final Account to,
    final Options? options,
  }) {
    if (account == null) {
      throw CustomException.missingAccount;
    }
    return sendFromAccount(
      amount: amount,
      from: account!,
      to: to,
      options: options,
    );
  }

  Future<PublishResult> sendToken({
    required final BigInt amount,
    required final String to,
    required final String token,
    final Options? options,
  }) {
    if (account == null) {
      throw CustomException.missingAccount;
    }
    final Account tokenAccount = AccountBuilder.createFromPublicKey(
      publicKey: token,
    );
    final Account toAccount = AccountBuilder.createFromPublicKey(publicKey: to);
    return sendFromAccountWithToken(
      amount: amount,
      from: account!,
      to: toAccount,
      token: tokenAccount,
      options: options,
    );
  }

  Future<PublishResult> sendToAccountWithToken({
    required final BigInt amount,
    required final Account to,
    required final String token,
    final Options? options,
  }) {
    if (account == null) {
      throw CustomException.missingAccount;
    }
    final Account tokenAccount = AccountBuilder.createFromPublicKey(
      publicKey: token,
    );
    return sendFromAccountWithToken(
      amount: amount,
      from: account!,
      to: to,
      token: tokenAccount,
      options: options,
    );
  }

  Future<PublishResult> sendWithTokenAccount({
    required final BigInt amount,
    required final Account to,
    required final Account token,
    final Options? options,
  }) {
    if (account == null) {
      throw CustomException.missingAccount;
    }
    return sendFromAccountWithToken(
      amount: amount,
      from: account!,
      to: to,
      token: token,
      options: options,
    );
  }

  Future<PublishResult> sendFromAccount({
    required final BigInt amount,
    required final Account from,
    required final Account to,
    final Options? options,
  }) => sendFromAccountWithToken(
    amount: amount,
    from: from,
    to: to,
    token: config.baseToken,
    options: options,
  );

  Future<PublishResult> sendFromAccountWithTokenString({
    required final BigInt amount,
    required final Account from,
    required final String to,
    required final String token,
    final Options? options,
  }) {
    final Account toAccount = AccountBuilder.createFromPublicKey(publicKey: to);
    final Account tokenAccount = AccountBuilder.createFromPublicKey(
      publicKey: token,
    );
    return sendFromAccountWithToken(
      amount: amount,
      from: from,
      to: toAccount,
      token: tokenAccount,
      options: options,
    );
  }

  Future<PublishResult> sendFromAccountWithToken({
    required final BigInt amount,
    required final Account from,
    required final Account to,
    required final Account token,
    final Options? options,
  }) async {
    if (token.keyAlgorithm != KeyAlgorithm.token) {
      throw CustomException.invalidTokenAccount;
    }

    final AccountBalance balance = await api.balance(forAccount: from);
    final SendOperation send = SendOperation(
      amount: amount,
      toAccount: to.publicKeyAndType,
      token: token.publicKeyAndType,
      external: options?.memo,
    );

    final Block sendBlock = blockBuilder()
        .start(from: balance.currentHeadBlock, network: config.networkID)
        .addAccount(from)
        .addOperation(send)
        .addIdempotent(options?.idempotency)
        .addSigner(options?.signer)
        .seal();

    final PublishResult result = await api.publishBlocksWithBuilder(
      blocks: <Block>[sendBlock],
      feeBlockBuilder: (final VoteStaple staple) {
        final Account accountToPayFees;
        final Account? optionsFeeAccount = options?.feeAccount ?? feeAccount;

        if (optionsFeeAccount != null &&
            optionsFeeAccount.publicKeyString != from.publicKeyString) {
          accountToPayFees = optionsFeeAccount;
        } else {
          final Map<String, BigInt> fees = staple.totalFees(
            baseToken: config.baseToken,
          );

          if (!balance.canCover(fees: fees)) {
            throw CustomException.insufficientBalanceToCoverNetworkFees;
          }

          accountToPayFees = from;
        }
        return BlockBuilder.feeBlockAsyncWithConfig(
          voteStaple: staple,
          account: accountToPayFees,
          network: config,
        );
      },
    );

    return result;
  }

  // MARK: Balance

  Future<AccountBalance> balance() {
    if (account == null) {
      throw CustomException.missingAccount;
    }
    return balanceOf(account!);
  }

  Future<AccountBalance> balanceOfString(final String accountPubKey) {
    final Account acc = AccountBuilder.createFromPublicKey(
      publicKey: accountPubKey,
    );
    return balanceOf(acc);
  }

  Future<AccountBalance> balanceOf(final Account account) =>
      api.balance(forAccount: account);

  // MARK: Transactions

  Future<List<NetworkSendTransaction>> transactions({
    final int limit = 100,
    final String? startBlockHash,
  }) {
    if (account == null) {
      throw CustomException.missingAccount;
    }
    return transactionsFor(
      account!,
      limit: limit,
      startBlockHash: startBlockHash,
    );
  }

  Future<List<NetworkSendTransaction>> transactionsForString(
    final String accountPubKey, {
    final int limit = 100,
    final String? startBlockHash,
  }) {
    final Account acc = AccountBuilder.createFromPublicKey(
      publicKey: accountPubKey,
    );
    return transactionsFor(acc, limit: limit, startBlockHash: startBlockHash);
  }

  Future<List<NetworkSendTransaction>> transactionsFor(
    final Account account, {
    final int limit = 100,
    final String? startBlockHash,
  }) async {
    final List<VoteStaple> history = await api.history(
      ofAccount: account,
      limit: limit,
      startBlockHash: startBlockHash,
    );

    final List<NetworkSendTransaction> transactions =
        <NetworkSendTransaction>[];

    for (final VoteStaple staple in history) {
      for (final Block block in staple.blocks) {
        for (final BlockOperation operation in block.rawData.operations) {
          switch (operation.operationType) {
            case BlockOperationType.send:
              final SendOperation send = operation.to(
                SendOperation.fromSequence,
              );
              final Account toAccount = Account.fromPublicKeyAndType(
                send.toAccount,
              );
              final bool isIncoming =
                  toAccount.publicKeyString == account.publicKeyString;

              // ignore send operations that aren't affecting account's chain
              if (!isIncoming &&
                  block.rawData.account.publicKeyString !=
                      account.publicKeyString) {
                continue;
              }

              transactions.add(
                NetworkSendTransaction(
                  id: const Uuid().v4(),
                  blockHash: block.hash,
                  amount: send.amount,
                  from: isIncoming ? block.rawData.account : account,
                  to: isIncoming ? account : toAccount,
                  token: Account.fromPublicKeyAndType(send.token),
                  isIncoming: isIncoming,
                  isNetworkFee: block.rawData.purpose == BlockPurpose.fee,
                  created: block.rawData.created,
                  memo: send.external,
                ),
              );

            case BlockOperationType.receive:
              final ReceiveOperation receive = operation.to(
                ReceiveOperation.fromSequence,
              );
              final Account fromAccount = Account.fromPublicKeyAndType(
                receive.from,
              );
              final bool isIncoming =
                  fromAccount.publicKeyString == account.publicKeyString;

              // ignore receive operations that aren't affecting account's chain
              if (!isIncoming &&
                  block.rawData.account.publicKeyString !=
                      account.publicKeyString) {
                continue;
              }

              transactions.add(
                NetworkSendTransaction(
                  id: const Uuid().v4(),
                  blockHash: block.hash,
                  amount: receive.amount,
                  from: isIncoming ? block.rawData.account : fromAccount,
                  to: isIncoming ? fromAccount : block.rawData.account,
                  token: Account.fromPublicKeyAndType(receive.token),
                  isIncoming: isIncoming,
                  isNetworkFee: false,
                  created: block.rawData.created,
                ),
              );
            default:
              break;
          }
        }
      }
    }

    transactions.sort(
      (final NetworkSendTransaction a, final NetworkSendTransaction b) =>
          b.created.compareTo(a.created),
    );
    return transactions;
  }

  // MARK: Swap

  Future<void> swap({
    required final Account otherAccount,
    required final Proposal offer,
    required final Proposal ask,
    final Account? feeAccount,
  }) async {
    if (account == null) {
      throw CustomException.missingAccount;
    }
    await swapAccounts(
      account: account!,
      offer: offer,
      ask: ask,
      from: otherAccount,
      feeAccount: feeAccount,
    );
  }

  Future<PublishResult> swapAccounts({
    required final Account account,
    required final Proposal offer,
    required final Proposal ask,
    required final Account from,
    final Account? feeAccount,
  }) async {
    final Account? fee = feeAccount ?? this.feeAccount;
    if (fee == null) {
      throw CustomException.feeAccountMissing;
    }

    final SendOperation send = SendOperation(
      amount: offer.amount,
      toAccount: from.publicKeyAndType,
      token: offer.token.publicKeyAndType,
    );
    final ReceiveOperation receive = ReceiveOperation(
      amount: ask.amount,
      token: ask.token.publicKeyAndType,
      from: from.publicKeyAndType,
      exact: true,
    );

    final String? accountHeadblock = (await api.balance(
      forAccount: account,
    )).currentHeadBlock;

    final Block accountSendReceiveBlock = blockBuilder()
        .start(from: accountHeadblock, network: config.networkID)
        .addAccount(account)
        .addOperations(<BlockOperation>[receive, send])
        .seal();

    final String? otherAccountHeadblock = (await api.balance(
      forAccount: from,
    )).currentHeadBlock;
    final SendOperation otherAccountTokenSend = SendOperation(
      amount: ask.amount,
      toAccount: account.publicKeyAndType,
      token: ask.token.publicKeyAndType,
    );
    final Block otherAccountTokenSendBlock = blockBuilder()
        .start(from: otherAccountHeadblock, network: config.networkID)
        .addAccount(from)
        .addOperation(otherAccountTokenSend)
        .seal();

    final List<Block> blocks = <Block>[
      otherAccountTokenSendBlock,
      accountSendReceiveBlock,
    ];
    return api.publishBlocksWithBuilder(
      blocks: blocks,
      feeBlockBuilder: (final VoteStaple staple) =>
          BlockBuilder.feeBlockAsyncWithConfig(
            voteStaple: staple,
            account: fee,
            network: config,
          ),
    );
  }

  // MARK: Token Management

  Future<Account> createTokenWithDouble({
    required final String name,
    required final double supply,
    final int decimals = 9,
    final String description = '',
    final Account? feeAccount,
  }) => createToken(
    name: name,
    supply: BigInt.from(supply),
    decimals: decimals,
    description: description,
    feeAccount: feeAccount,
  );

  Future<Account> createToken({
    required final String name,
    required final BigInt supply,
    final int decimals = 9,
    final String description = '',
    final Account? feeAccount,
  }) {
    if (account == null) {
      throw CustomException.missingAccount;
    }
    return createTokenFor(
      account: account!,
      name: name,
      supply: supply,
      decimals: decimals,
      description: description,
      feeAccount: feeAccount,
    );
  }

  Future<Account> createTokenFor({
    required final Account account,
    required final String name,
    required final BigInt supply,
    final int decimals = 9,
    final String description = '',
    final Account? feeAccount,
  }) async {
    final String? accountHeadblock = (await api.balance(
      forAccount: account,
    )).currentHeadBlock;
    final Account token = account.generateIdentifier(
      previous: accountHeadblock,
    );

    final CreateIdentifierOperation create = CreateIdentifierOperation(
      identifier: token.publicKeyAndType,
    );
    final Block tokenCreationBlock = blockBuilder()
        .start(from: accountHeadblock, network: config.networkID)
        .addAccount(account)
        .addOperation(create)
        .seal();

    final TokenAdminSupplyOperation mint = TokenAdminSupplyOperation(
      amount: supply,
      method: AdminSupplyAdjustMethod.add,
    );

    // Token Meta Data
    final SetInfoOperation info = SetInfoOperation(
      name: name,
      description: description,
      metaData: MetaData(decimalPlaces: decimals).btoa(),
      defaultPermission: const Permission(baseFlag: BaseFlag.access),
    );

    final Block tokenMintBlock = blockBuilder()
        .start(network: config.networkID)
        .addAccount(token)
        .addOperations(<BlockOperation>[mint, info])
        .addSigner(account)
        .seal();

    await api.publishBlocksWithBuilder(
      blocks: <Block>[tokenCreationBlock, tokenMintBlock],
      feeBlockBuilder: (final VoteStaple staple) => BlockBuilder.feeBlockForApi(
        voteStaple: staple,
        account: feeAccount ?? account,
        api: api,
      ),
    );

    return token;
  }

  Future<TokenInfo> tokenInfo() {
    if (account == null) {
      throw CustomException.missingAccount;
    }
    return tokenInfoFor(account!);
  }

  Future<TokenInfo> tokenInfoForString(final String pubKeyAccount) {
    final Account acc = AccountBuilder.createFromPublicKey(
      publicKey: pubKeyAccount,
    );
    return tokenInfoFor(acc);
  }

  Future<TokenInfo> tokenInfoFor(final Account account) async {
    if (account.keyAlgorithm != KeyAlgorithm.token) {
      throw CustomException.noTokenAccount;
    }

    final AccountInfo accountInfo = await api.accountInfo(forAccount: account);

    // Tokens without supply or decimal places meta data are considered invalid
    final MetaData metaData = MetaData.create(btoa: accountInfo.metadata);

    final BigInt? supply = accountInfo.supply;
    if (supply == null) {
      throw CustomException.noTokenSupply;
    }

    return TokenInfo(
      address: account.publicKeyString,
      name: accountInfo.name,
      description: accountInfo.description.isEmpty
          ? null
          : accountInfo.description,
      supply: supply.toDouble(),
      decimalPlaces: metaData.decimalPlaces,
    );
  }

  // MARK: Account

  Future<RecoverResult?> recoverAccount({
    final bool publish = true,
    final Account? feeAccount,
  }) {
    if (account == null) {
      throw CustomException.missingAccount;
    }
    return recoverAccountFor(
      account!,
      publish: publish,
      feeAccount: feeAccount,
    );
  }

  Future<RecoverResult?> recoverAccountFor(
    final Account account, {
    final bool publish = true,
    final Account? feeAccount,
  }) async {
    final Block? pendingBlock = await api.pendingBlock(forAccount: account);
    if (pendingBlock == null) {
      return null;
    }

    final List<Vote> recoveredTemporaryVotes = await api
        .recoverVotesForBlockHash(blockHash: pendingBlock.hash);

    final Account fee = feeAccount ?? this.feeAccount ?? account;

    if (publish) {
      final PublishResult result = await api.publishBlocksWithTemporaryVotes(
        blocks: <Block>[pendingBlock],
        temporaryVotes: recoveredTemporaryVotes,
        feeBlockBuilder: (final VoteStaple staple) =>
            BlockBuilder.feeBlockAsyncWithConfig(
              voteStaple: staple,
              account: fee,
              network: config,
            ),
      );
      return RecoverResult.published(result);
    } else {
      final List<Block> blocksToPublish;
      if (recoveredTemporaryVotes.requiresFees) {
        final VoteStaple recoveredStaple = VoteStaple.create(
          votes: recoveredTemporaryVotes,
          blocks: <Block>[pendingBlock],
        );
        final Block feeBlock = await BlockBuilder.feeBlockAsyncWithConfig(
          voteStaple: recoveredStaple,
          account: fee,
          network: config,
        );
        blocksToPublish = <Block>[pendingBlock, feeBlock];
      } else {
        blocksToPublish = <Block>[pendingBlock];
      }
      return RecoverResult.readyToPublish(
        blocksToPublish,
        temporaryVotes: recoveredTemporaryVotes,
      );
    }
  }

  // MARK: Helper

  BlockBuilder blockBuilder() => BlockBuilder(version: version);
}

sealed class RecoverResult {
  const RecoverResult();

  factory RecoverResult.published(final PublishResult result) =
      RecoverResultPublished;
  factory RecoverResult.readyToPublish(
    final List<Block> blocks, {
    required final List<Vote> temporaryVotes,
  }) = RecoverResultReadyToPublish;
}

class RecoverResultPublished extends RecoverResult {
  const RecoverResultPublished(this.result);
  final PublishResult result;
}

class RecoverResultReadyToPublish extends RecoverResult {
  const RecoverResultReadyToPublish(
    this.blocks, {
    required this.temporaryVotes,
  });
  final List<Block> blocks;
  final List<Vote> temporaryVotes;
}
