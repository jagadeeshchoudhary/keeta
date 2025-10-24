import 'dart:async';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/account_feature/account_balance.dart';
import 'package:keeta/src/account_feature/account_info.dart';
import 'package:keeta/src/block_feature/block.dart';
import 'package:keeta/src/block_feature/block_builder.dart';
import 'package:keeta/src/networking/client_representative.dart';
import 'package:keeta/src/networking/generics/http_client.dart';
import 'package:keeta/src/networking/generics/request_error.dart';
import 'package:keeta/src/networking/keeta_endpoint.dart';
import 'package:keeta/src/networking/network_alias.dart';
import 'package:keeta/src/networking/network_config.dart';
import 'package:keeta/src/networking/publish_result.dart';
import 'package:keeta/src/networking/responses/account_state_response.dart';
import 'package:keeta/src/networking/responses/block_response.dart';
import 'package:keeta/src/networking/responses/certificate_content_response.dart';
import 'package:keeta/src/networking/responses/client_response.dart';
import 'package:keeta/src/networking/responses/history_response.dart';
import 'package:keeta/src/networking/responses/keeta_error_response.dart';
import 'package:keeta/src/networking/responses/publish_response.dart';
import 'package:keeta/src/networking/responses/vote_quote_response.dart';
import 'package:keeta/src/networking/responses/vote_response.dart';
import 'package:keeta/src/operations/send_operation.dart';
import 'package:keeta/src/utils/custom_exception.dart';
import 'package:keeta/src/utils/ledger_side.dart';
import 'package:keeta/src/votes/vote.dart';
import 'package:keeta/src/votes/vote_quote.dart';
import 'package:keeta/src/votes/vote_staple.dart';

/// Vote type for requesting votes
sealed class VoteType {
  const VoteType();

  bool get isPermanent => this is PermanentVoteType;
}

/// Temporary vote type
class TemporaryVoteType extends VoteType {
  const TemporaryVoteType({this.quotes});

  final List<VoteQuote>? quotes;
}

/// Permanent vote type
class PermanentVoteType extends VoteType {
  const PermanentVoteType({required this.temporaryVotes});

  final List<Vote> temporaryVotes;
}

/// Keeta API client for interacting with the Keeta network
class KeetaApi extends HTTPClient {
  KeetaApi({
    required final List<ClientRepresentative> reps,
    required this.networkId,
    required this.baseToken,
    final ClientRepresentative? preferredRep,
  }) : assert(reps.isNotEmpty, 'At least one representative is required'),
       reps = List<ClientRepresentative>.from(reps),
       preferredRep = preferredRep ?? reps.preferred ?? reps[0];

  /// Creates a KeetaApi instance from a network alias
  factory KeetaApi.fromNetwork({required final NetworkAlias network}) {
    final NetworkConfig config = NetworkConfig.create(forNetwork: network);
    return KeetaApi.fromConfig(config: config);
  }

  /// Creates a KeetaApi instance from a network config
  factory KeetaApi.fromConfig({required final NetworkConfig config}) =>
      KeetaApi(
        reps: config.reps,
        networkId: config.networkID,
        baseToken: config.baseToken,
      );

  ClientRepresentative preferredRep;
  List<ClientRepresentative> reps;
  final BigInt networkId;
  final Account baseToken;

  /// Gets vote quotes for the given blocks
  Future<List<VoteQuote>> voteQuotes({
    required final List<Block> forBlocks,
  }) async {
    final Set<String> repBaseUrls = reps
        .map((final ClientRepresentative rep) => rep.apiUrl)
        .toSet();
    final List<Endpoint> requests = KeetaEndpoint.voteQuote(
      forBlocks: forBlocks,
      repBaseUrls: repBaseUrls,
    );

    final List<VoteQuoteResponse> responses = await Future.wait(
      requests.map((final Endpoint request) async {
        final VoteQuoteResponse response =
            await sendRequestDecoded<VoteQuoteResponse>(to: request);
        return response;
      }),
    );

    return responses
        .map(
          (final VoteQuoteResponse response) =>
              VoteQuote.createFromBase64(base64: response.quote.binary),
        )
        .toList();
  }

  /// Gets votes for the given blocks
  Future<List<Vote>> votes({
    required final List<Block> forBlocks,
    required final VoteType type,
  }) async {
    final Map<String, String> repsInfo = <String, String>{
      for (final ClientRepresentative rep in reps) rep.address: rep.apiUrl,
    };

    final List<Endpoint> requests;

    switch (type) {
      case TemporaryVoteType(:final List<VoteQuote>? quotes):
        final Map<String, VoteQuote> quotesInfo = <String, VoteQuote>{
          if (quotes != null)
            for (final VoteQuote quote in quotes)
              quote.issuer.publicKeyString: quote,
        };
        requests = KeetaEndpoint.temporaryVotes(
          forBlocks: forBlocks,
          quotes: quotesInfo,
          fromReps: repsInfo,
        );

      case PermanentVoteType(:final List<Vote> temporaryVotes):
        final Set<String> repUrls = <String>{};
        for (final Vote vote in temporaryVotes) {
          final ClientRepresentative rep = reps.firstWhere(
            (final ClientRepresentative r) =>
                r.address == vote.issuer.publicKeyString,
            orElse: () => throw CustomException.clientRepresentativeNotFound(
              vote.issuer.publicKeyString,
            ),
          );
          repUrls.add(rep.apiUrl);
        }
        requests = KeetaEndpoint.permanentVotes(
          forBlocks: forBlocks,
          temporaryVotes: temporaryVotes,
          fromRepUrls: repUrls,
        );
    }

    // Request votes
    final List<Object> errors = <Object>[];
    final List<Vote> votes = <Vote>[];

    for (final Endpoint request in requests) {
      try {
        final VoteResponse result =
            await sendRequest<VoteResponse, KeetaErrorResponse>(
              to: request,
              errorDecoder: KeetaErrorResponse.fromJson,
            );
        votes.add(Vote.createFromBase64(base64: result.vote.binary));
      } catch (error) {
        if (type.isPermanent) {
          // A permanent vote is required for each temporary vote
          rethrow;
        } else {
          if (error is KeetaError<KeetaErrorResponse>) {
            if (error.error.code == ErrorCode.successorVoteExists) {
              // Rep has a vote for a previous block
              rethrow;
            }
          }

          // Silently skip reps that can't provide a temporary vote
          errors.add(error);
        }
      }
    }

    if (votes.isEmpty) {
      throw CustomException.noVotes(errors);
    }

    return votes;
  }

  /// Publishes a vote staple to the network
  Future<void> publishVoteStaple({
    required final VoteStaple voteStaple,
    final bool toAll = false,
  }) async {
    final List<ClientRepresentative> repsToPublish = toAll
        ? reps
        : <ClientRepresentative>[preferredRep];
    final List<Endpoint> requests = KeetaEndpoint.publishVoteStaple(
      voteStaple: voteStaple,
      toRepUrls: repsToPublish
          .map((final ClientRepresentative rep) => rep.apiUrl)
          .toSet(),
    );

    bool succeeded = false;
    Error? latestError;

    for (final Endpoint request in requests) {
      try {
        final PublishResponse response =
            await sendRequest<PublishResponse, KeetaErrorResponse>(
              to: request,
              errorDecoder: KeetaErrorResponse.fromJson,
            );
        if (!succeeded && response.publish) {
          succeeded = true;
        }
      } catch (error) {
        latestError = error as Error;
      }
    }

    if (succeeded) {
      return;
    }

    if (latestError != null) {
      throw latestError;
    } else {
      throw CustomException.notPublished;
    }
  }

  /// Gets the pending block for an account
  Future<Block?> pendingBlock({required final Account forAccount}) async {
    final List<Endpoint> requests = KeetaEndpoint.pendingBlock(
      forAccount: forAccount,
      fromRepUrls: reps
          .map((final ClientRepresentative rep) => rep.apiUrl)
          .toSet(),
    );

    final List<Object> errors = <Object>[];
    final Map<String, int> hashCounts = <String, int>{};
    final Map<String, Block> blocksWithHashes = <String, Block>{};

    for (final Endpoint request in requests) {
      try {
        final PendingBlockResponse response =
            await sendRequest<PendingBlockResponse, KeetaErrorResponse>(
              to: request,
              errorDecoder: KeetaErrorResponse.fromJson,
            );

        if (forAccount.publicKeyString != response.account) {
          throw CustomException.blockAccountMismatch;
        }

        final BlockContentResponse? blockData = response.block;
        if (blockData == null) {
          continue;
        }

        final Block block = Block.createFromBase64(base64: blockData.binary);

        if (block.hash != blockData.hash) {
          throw CustomException.blockHashMismatch;
        }

        hashCounts[blockData.hash] = (hashCounts[blockData.hash] ?? 0) + 1;
        blocksWithHashes[blockData.hash] = block;
      } catch (error) {
        errors.add(error);
      }
    }

    if (blocksWithHashes.isEmpty) {
      if (errors.isEmpty) {
        return null; // No pending block
      } else {
        throw CustomException.noPendingBlock(errors);
      }
    }

    // Return the block that is repeated on the most reps
    final String mostCommonHash = hashCounts.entries
        .reduce(
          (final MapEntry<String, int> a, final MapEntry<String, int> b) =>
              a.value > b.value ? a : b,
        )
        .key;

    return blocksWithHashes[mostCommonHash];
  }

  /// Recovers votes for an account's pending block
  Future<List<Vote>> recoverVotesForAccount({
    required final Account account,
  }) async {
    final String repUrl = preferredRep.apiUrl;
    final Endpoint pendingBlockRequest = KeetaEndpoint.pendingBlockSingle(
      forAccount: account,
      baseUrl: repUrl,
    );
    final PendingBlockResponse pendingBlockResponse =
        await sendRequest<PendingBlockResponse, KeetaErrorResponse>(
          to: pendingBlockRequest,
          errorDecoder: KeetaErrorResponse.fromJson,
        );

    if (account.publicKeyString != pendingBlockResponse.account) {
      throw CustomException.blockAccountMismatch;
    }

    final BlockContentResponse? block = pendingBlockResponse.block;
    if (block == null) {
      return <Vote>[]; // No pending block to recover
    }

    return recoverVotesForBlockHash(blockHash: block.hash);
  }

  /// Recovers votes for a specific block hash
  Future<List<Vote>> recoverVotesForBlockHash({
    required final String blockHash,
  }) async {
    final List<Endpoint> requests = KeetaEndpoint.voteForBlock(
      blockHash: blockHash,
      side: LedgerSide.side,
      repBaseUrls: reps
          .map((final ClientRepresentative rep) => rep.apiUrl)
          .toSet(),
    );

    final List<Vote> results = <Vote>[];

    await Future.wait(
      requests.map((final Endpoint request) async {
        try {
          final BlockVoteResponse result =
              await sendRequest<BlockVoteResponse, KeetaErrorResponse>(
                to: request,
                errorDecoder: KeetaErrorResponse.fromJson,
              );
          if (result.votes != null) {
            for (final CertificateContentResponse voteData in result.votes!) {
              results.add(Vote.createFromBase64(base64: voteData.binary));
            }
          }
        } catch (_) {
          // Skip failed requests
        }
      }),
    );

    return results;
  }

  /// Publishes blocks with a fee account
  Future<PublishResult> publishBlocks({
    required final List<Block> blocks,
    required final Account feeAccount,
  }) => publishBlocksWithBuilder(
    blocks: blocks,
    feeBlockBuilder: (final VoteStaple voteStaple) =>
        BlockBuilder.feeBlockForApi(
          voteStaple: voteStaple,
          account: feeAccount,
          api: this,
        ),
  );

  /// Publishes blocks with optional quotes and fee block builder
  Future<PublishResult> publishBlocksWithBuilder({
    required final List<Block> blocks,
    final List<VoteQuote>? quotes,
    final Future<Block> Function(VoteStaple)? feeBlockBuilder,
  }) async {
    final List<Vote> temporaryVotes = await votes(
      forBlocks: blocks,
      type: TemporaryVoteType(quotes: quotes),
    );

    return publishBlocksWithTemporaryVotes(
      blocks: blocks,
      temporaryVotes: temporaryVotes,
      feeBlockBuilder: feeBlockBuilder,
    );
  }

  /// Publishes blocks with temporary votes and fee block builder
  Future<PublishResult> publishBlocksWithTemporaryVotes({
    required final List<Block> blocks,
    required final List<Vote> temporaryVotes,
    final Future<Block> Function(VoteStaple)? feeBlockBuilder,
  }) async {
    final List<Block> blocksToPublish;
    final List<PaidFee> fees;
    final String? feeBlockHash;

    if (temporaryVotes.requiresFees) {
      if (feeBlockBuilder == null) {
        throw CustomException.feesRequiredButFeeBuilderMissing;
      }

      final VoteStaple tempStaple = VoteStaple.create(
        votes: temporaryVotes,
        blocks: blocks,
      );
      final Block feeBlock = await feeBlockBuilder(tempStaple);

      blocksToPublish = <Block>[...blocks, feeBlock];
      fees = feeBlock.rawData.operations
          .whereType<SendOperation>()
          .map(
            (final SendOperation op) => PaidFee(
              amount: op.amount,
              to: Account.publicKeyStringFromBytes(op.toAccount),
              token: Account.publicKeyStringFromBytes(op.token),
            ),
          )
          .toList();
      feeBlockHash = feeBlock.hash;
    } else {
      blocksToPublish = blocks;
      fees = <PaidFee>[];
      feeBlockHash = null;
    }

    final List<Vote> permanentVotes = await votes(
      forBlocks: blocksToPublish,
      type: PermanentVoteType(temporaryVotes: temporaryVotes),
    );

    final VoteStaple voteStaple = VoteStaple.create(
      votes: permanentVotes,
      blocks: blocksToPublish,
    );
    await publishVoteStaple(voteStaple: voteStaple);

    return PublishResult(
      staple: voteStaple,
      fees: fees,
      feeBlockHash: feeBlockHash,
    );
  }

  /// Gets a block by hash
  Future<Block> blockByHash({
    required final String hash,
    final LedgerSide? side,
  }) async {
    final String repUrl = preferredRep.apiUrl;
    final Endpoint endpoint = KeetaEndpoint.blockByHash(
      hash: hash,
      side: side,
      baseUrl: repUrl,
    );
    final BlockResponse response =
        await sendRequest<BlockResponse, KeetaErrorResponse>(
          to: endpoint,
          errorDecoder: KeetaErrorResponse.fromJson,
        );
    final Block block = Block.createFromBase64(base64: response.block.binary);

    if (response.blockhash != null && response.blockhash != block.hash) {
      throw CustomException.blockHashMismatch;
    }

    return block;
  }

  /// Gets a block by account and idempotent key
  Future<Block> blockByIdempotent({
    required final Account forAccount,
    required final String idempotent,
    final LedgerSide side = LedgerSide.main,
  }) async {
    final String repUrl = preferredRep.apiUrl;
    final Endpoint endpoint = KeetaEndpoint.blockByIdempotent(
      forAccount: forAccount,
      idempotent: idempotent,
      side: side,
      baseUrl: repUrl,
    );
    final BlockResponse response =
        await sendRequest<BlockResponse, KeetaErrorResponse>(
          to: endpoint,
          errorDecoder: KeetaErrorResponse.fromJson,
        );
    final Block block = Block.createFromBase64(base64: response.block.binary);

    if (response.blockhash != null && response.blockhash != block.hash) {
      throw CustomException.blockHashMismatch;
    }

    return block;
  }

  /// Gets the balance for an account
  Future<AccountBalance> balance({
    required final Account forAccount,
    final bool replaceReps = false,
  }) async {
    await updateRepresentatives(replace: replaceReps);

    final String repUrl = preferredRep.apiUrl;
    final AccountStateResponse result =
        await sendRequest<AccountStateResponse, KeetaErrorResponse>(
          to: KeetaEndpoint.accountInfo(ofAccount: forAccount, baseUrl: repUrl),
          errorDecoder: KeetaErrorResponse.fromJson,
        );

    final Map<String, BigInt> rawBalances = <String, BigInt>{};
    for (final AccountBalanceResponse balanceData in result.balances) {
      final BigInt? balance = BigInt.tryParse('0x${balanceData.balance}');
      if (balance == null) {
        throw CustomException.invalidBalanceValue;
      }
      rawBalances[balanceData.token] = balance;
    }

    return AccountBalance(
      account: result.account,
      rawBalances: rawBalances,
      currentHeadBlock: result.currentHeadBlock,
    );
  }

  /// Updates the list of representatives
  Future<List<ClientRepresentative>> updateRepresentatives({
    final bool replace = true,
  }) async {
    final Endpoint endpoint = KeetaEndpoint.representatives(
      baseUrl: preferredRep.apiUrl,
    );
    final RepresentativesResponse response =
        await sendRequest<RepresentativesResponse, KeetaErrorResponse>(
          to: endpoint,
          errorDecoder: KeetaErrorResponse.fromJson,
        );

    ClientRepresentative repFromResponse(final RepresentativeResponse rep) =>
        ClientRepresentative(
          address: rep.representative,
          apiUrl: rep.endpoints.api,
          socketUrl: rep.endpoints.p2p,
          weight: BigInt.tryParse('0x${rep.weight}'),
        );

    if (reps.isEmpty || replace) {
      reps = response.representatives.map(repFromResponse).toList();
    } else {
      // Only update known reps
      for (int i = 0; i < reps.length; i++) {
        final ClientRepresentative knownRep = reps[i];

        final RepresentativeResponse? update = response.representatives
            .where(
              (final RepresentativeResponse rep) =>
                  rep.representative.toLowerCase() ==
                  knownRep.address.toLowerCase(),
            )
            .firstOrNull; // ✅ returns null if no match

        if (update != null) {
          reps[i] = repFromResponse(update);
        }
      }
    }

    final ClientRepresentative? preferred = reps.preferred;
    if (preferred != null) {
      preferredRep = preferred;
    }

    return reps;
  }

  /// Gets account info
  Future<AccountInfo> accountInfo({required final Account forAccount}) async {
    final String repUrl = preferredRep.apiUrl;
    final AccountStateResponse result =
        await sendRequest<AccountStateResponse, KeetaErrorResponse>(
          to: KeetaEndpoint.accountInfo(ofAccount: forAccount, baseUrl: repUrl),
          errorDecoder: KeetaErrorResponse.fromJson,
        );

    final BigInt? supply;
    if (result.info.supply != null) {
      final BigInt? infoSupply = BigInt.tryParse('0x${result.info.supply}');
      if (infoSupply == null) {
        throw CustomException.invalidSupplyValue(result.info.supply);
      }
      supply = infoSupply;
    } else {
      supply = null;
    }

    return AccountInfo(
      name: result.info.name,
      description: result.info.description,
      metadata: result.info.metadata,
      supply: supply,
    );
  }

  /// Gets the history for an account
  Future<List<VoteStaple>> history({
    required final Account ofAccount,
    final int limit = 50,
    final String? startBlockHash,
  }) async {
    final String repUrl = preferredRep.apiUrl;
    final Endpoint request = KeetaEndpoint.history(
      forAccount: ofAccount,
      limit: limit,
      startBlockHash: startBlockHash,
      baseUrl: repUrl,
    );
    final HistoryResponse response =
        await sendRequest<HistoryResponse, KeetaErrorResponse>(
          to: request,
          errorDecoder: KeetaErrorResponse.fromJson,
        );

    return response.history
        .map(
          (final HistoryContentResponse item) =>
              VoteStaple.createFromBase64(item.voteStaple.binary),
        )
        .toList();
  }
}
