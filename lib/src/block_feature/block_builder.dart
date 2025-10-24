import 'dart:async';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/account_feature/account_balance.dart';
import 'package:keeta/src/block_feature/block.dart';
import 'package:keeta/src/block_feature/block_purpose.dart';
import 'package:keeta/src/block_feature/block_signature.dart';
import 'package:keeta/src/block_feature/block_version.dart';
import 'package:keeta/src/block_feature/raw_block_data.dart';
import 'package:keeta/src/networking/keeta_api.dart';
import 'package:keeta/src/networking/network_alias.dart';
import 'package:keeta/src/networking/network_config.dart';
import 'package:keeta/src/operations/bloc_operation.dart';
import 'package:keeta/src/operations/bloc_operation_type.dart';
import 'package:keeta/src/operations/send_operation.dart';
import 'package:keeta/src/utils/custom_exception.dart';
import 'package:keeta/src/votes/fee.dart';
import 'package:keeta/src/votes/vote.dart';
import 'package:keeta/src/votes/vote_staple.dart';
import 'package:uuid/uuid.dart';

class BlockBuilder {
  BlockBuilder({final BlockVersion? version, final BlockPurpose? purpose})
    : version = version ?? BlockVersion.latest,
      purpose = purpose ?? BlockPurpose.generic;

  BlockVersion version;
  BlockPurpose purpose;
  String? idempotent;
  String? previous;
  BigInt? network;
  BigInt? subnet;
  Account? account;
  Account? signer;
  final List<BlockOperation> operations = <BlockOperation>[];

  // ----------------------
  // Static factory methods
  // ----------------------

  /// Creates a fee block using NetworkAlias with async balance fetching
  static Future<Block> feeBlockAsync({
    required final VoteStaple voteStaple,
    required final Account account,
    required final NetworkAlias network,
  }) {
    final NetworkConfig config = NetworkConfig.create(forNetwork: network);
    return feeBlockForApi(
      voteStaple: voteStaple,
      account: account,
      api: KeetaApi.fromConfig(config: config),
    );
  }

  /// Creates a fee block using NetworkConfig with async balance fetching
  static Future<Block> feeBlockAsyncWithConfig({
    required final VoteStaple voteStaple,
    required final Account account,
    required final NetworkConfig network,
  }) => feeBlockForApi(
    voteStaple: voteStaple,
    account: account,
    api: KeetaApi.fromConfig(config: network),
  );

  /// Creates a fee block with provided previous hash (synchronous)
  static Block feeBlockWithPrevious({
    required final VoteStaple voteStaple,
    required final Account account,
    required final NetworkAlias network,
    final String? previous,
  }) {
    final NetworkConfig config = NetworkConfig.create(forNetwork: network);
    return feeBlockSync(
      voteStaple: voteStaple,
      account: account,
      networkId: config.networkID,
      baseToken: config.baseToken,
      previous: previous,
    );
  }

  /// Creates a fee block with provided previous hash 
  /// using NetworkConfig (synchronous)
  static Block feeBlockWithPreviousAndConfig({
    required final VoteStaple voteStaple,
    required final Account account,
    required final NetworkConfig network,
    final String? previous,
  }) => feeBlockSync(
    voteStaple: voteStaple,
    account: account,
    networkId: network.networkID,
    baseToken: network.baseToken,
    previous: previous,
  );

  /// Creates a fee block using KeetaApi (fetches balance if needed)
  static Future<Block> feeBlockForApi({
    required final VoteStaple voteStaple,
    required final Account account,
    required final KeetaApi api,
  }) async {
    String? previous;

    // Check if account's block exists in the staple
    final Block? existingBlock = voteStaple.blocks
        .where(
          (final Block b) =>
              b.rawData.account.publicKeyString == account.publicKeyString,
        )
        .lastOrNull;

    if (existingBlock != null) {
      // Latest block hash of account is available within staple
      previous = existingBlock.hash;
    } else {
      // Fetch latest block hash from account chain
      final AccountBalance balance = await api.balance(forAccount: account);

      final Map<String, BigInt> fees = voteStaple.totalFees(
        baseToken: api.baseToken,
      );

      if (!balance.canCover(fees: fees)) {
        throw CustomException.insufficientBalanceToCoverNetworkFees;
      }

      previous = balance.currentHeadBlock;
    }

    return feeBlockSync(
      voteStaple: voteStaple,
      account: account,
      networkId: api.networkId,
      baseToken: api.baseToken,
      previous: previous,
    );
  }

  /// Creates a fee block synchronously with all required parameters
  static Block feeBlockSync({
    required final VoteStaple voteStaple,
    required final Account account,
    required final BigInt networkId,
    required final Account baseToken,
    final String? previous,
  }) {
    if (!account.canSign) {
      throw CustomException.insufficientDataToSignBlock;
    }

    // Pay each vote issuer (aka rep) their respective fee
    final List<SendOperation> operations = <SendOperation>[];
    for (final Vote vote in voteStaple.votes) {
      final Fee? fee = vote.fee;
      if (fee != null) {
        final SendOperation send = SendOperation(
          amount: fee.amount,
          toAccount:
              fee.payTo?.publicKeyAndType ?? vote.issuer.publicKeyAndType,
          token: fee.token?.publicKeyAndType ?? baseToken.publicKeyAndType,
        );
        operations.add(send);
      }
    }

    return BlockBuilder(purpose: BlockPurpose.fee)
        .start(from: previous, network: networkId)
        .addAccount(account)
        .addOperations(operations)
        .seal();
  }

  /// Generates an idempotent key (UUID v4 uppercase)
  static String idempotentKey() {
    final String uuid = const Uuid().v4();
    return uuid.toUpperCase();
  }

  // ----------------------
  // Builder methods
  // ----------------------

  /// Starts building a block with network and optional subnet
  BlockBuilder start({
    required final BigInt network,
    final String? from,
    final BigInt? subnet,
  }) {
    previous = from?.toUpperCase();
    this.network = network;
    this.subnet = subnet;
    return this;
  }

  /// Adds the account for the block
  BlockBuilder addAccount(final Account account) {
    this.account = account;
    return this;
  }

  /// Adds an idempotent key
  BlockBuilder addIdempotent(final String? idempotent) {
    this.idempotent = idempotent;
    return this;
  }

  /// Adds a signer account (if different from account)
  BlockBuilder addSigner(final Account? signer) {
    this.signer = signer;
    return this;
  }

  /// Adds multiple operations
  BlockBuilder addOperations(final List<BlockOperation> ops) {
    ops.forEach(addOperation);
    return this;
  }

  /// Adds a single operation
  BlockBuilder addOperation(final BlockOperation operation) {
    if (operation.operationType == BlockOperationType.setRep &&
        operations.any(
          (final BlockOperation o) =>
              o.operationType == BlockOperationType.setRep,
        )) {
      throw CustomException.multipleSetRepOperations;
    }
    operations.add(operation);
    return this;
  }

  // ----------------------
  // Finalization
  // ----------------------

  /// Seals the block with optional signature and creation timestamp
  Block seal({final BlockSignature? signature, final DateTime? created}) {
    final Account? signerAccount = signer ?? account;

    if (network == null || signerAccount == null || operations.isEmpty) {
      throw CustomException.insufficientDataToSignBlock;
    }

    if (network! < BigInt.zero) {
      throw CustomException.negativeNetworkId;
    }

    if (subnet != null && subnet! < BigInt.zero) {
      throw CustomException.negativeSubnetId;
    }

    // Ensure block can be signed if no signature was provided
    if (signature == null && !signerAccount.canSign) {
      throw CustomException.noPrivateKeyOrSignatureToSignBlock;
    }

    final Account acc = account ?? signerAccount;

    final String previousHash;
    if (previous != null) {
      previousHash = previous!;
    } else {
      previousHash = Block.accountOpeningHash(account: acc);
    }

    final RawBlockData rawBlock = RawBlockData(
      version: version,
      purpose: purpose,
      idempotent: idempotent,
      previous: previousHash,
      network: network!,
      subnet: subnet,
      signer: signerAccount,
      account: acc,
      operations: operations,
      created: created ?? DateTime.now(),
    );

    return Block.fromRawBlock(
      rawBlock: rawBlock,
      opening: previous == null,
      signature: signature,
    );
  }
}
