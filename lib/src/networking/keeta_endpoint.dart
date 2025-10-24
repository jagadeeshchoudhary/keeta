import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/block_feature/block.dart';
import 'package:keeta/src/networking/generics/http_client.dart';
import 'package:keeta/src/networking/generics/request_error.dart';
import 'package:keeta/src/utils/ledger_side.dart';
import 'package:keeta/src/votes/vote.dart';
import 'package:keeta/src/votes/vote_quote.dart';
import 'package:keeta/src/votes/vote_staple.dart';

/// Request method types
enum RequestMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE');

  const RequestMethod(this.value);
  final String value;
}

/// Keeta API endpoint builder
class KeetaEndpoint {
  KeetaEndpoint({
    required final String url,
    required final RequestMethod method,
    final Map<String, String>? header,
    this.query = const <String, String>{},
    this.body,
  }) : urlString = url,
       method = method.value,
       header = header ?? _defaultHeader;

  static const Map<String, String> _defaultHeader = <String, String>{
    'content-type': 'application/json',
  };

  final String urlString;
  final String method;
  final Map<String, String>? header;
  final Map<String, String> query;
  final Map<String, dynamic>? body;

  Uri get url {
    final Uri uri = Uri.parse(urlString);
    if (uri.hasScheme && uri.hasAuthority) {
      return uri;
    }
    throw const InvalidURLError<void>();
  }

  /// Creates endpoint for requesting temporary votes
  static List<Endpoint> temporaryVotes({
    required final List<Block> forBlocks,
    required final Map<String, String> fromReps,
    final Map<String, VoteQuote> quotes = const <String, VoteQuote>{},
  }) => fromReps.entries.map((final MapEntry<String, String> entry) {
    final String pubKey = entry.key;
    final String url = entry.value;
    final Map<String, dynamic> body = _voteRequestToJson(
      blocks: forBlocks,
      quote: quotes[pubKey],
    );
    return Endpoint(
      url: Uri.parse('$url/vote'),
      method: RequestMethod.post.value,
      body: body,
    );
  }).toList();

  /// Creates endpoint for requesting permanent votes
  static List<Endpoint> permanentVotes({
    required final List<Block> forBlocks,
    required final List<Vote> temporaryVotes,
    required final Set<String> fromRepUrls,
  }) {
    final Map<String, dynamic> body = _voteRequestToJson(
      blocks: forBlocks,
      votes: temporaryVotes,
    );
    return fromRepUrls
        .map(
          (final String baseUrl) => Endpoint(
            url: Uri.parse('$baseUrl/vote'),
            method: RequestMethod.post.value,
            body: body,
          ),
        )
        .toList();
  }

  /// Creates endpoint for getting votes for a block hash
  static List<Endpoint> voteForBlock({
    required final String blockHash,
    required final LedgerSide side,
    required final Set<String> repBaseUrls,
  }) => repBaseUrls
      .map(
        (final String baseUrl) => Endpoint(
          url: Uri.parse('$baseUrl/vote/$blockHash'),
          method: RequestMethod.get.value,
          query: <String, String>{'side': side.rawValue},
        ),
      )
      .toList();

  /// Creates endpoint for requesting vote quotes
  static List<Endpoint> voteQuote({
    required final List<Block> forBlocks,
    required final Set<String> repBaseUrls,
  }) {
    final Map<String, List<String>> body = <String, List<String>>{
      'blocks': forBlocks
          .map((final Block block) => block.base64String())
          .toList(),
    };
    return repBaseUrls
        .map(
          (final String baseUrl) => Endpoint(
            url: Uri.parse('$baseUrl/vote/quote'),
            method: RequestMethod.post.value,
            body: body,
          ),
        )
        .toList();
  }

  /// Creates endpoint for getting pending block (single rep)
  static Endpoint pendingBlockSingle({
    required final Account forAccount,
    required final String baseUrl,
  }) => Endpoint(
    url: Uri.parse(
      '$baseUrl/node/ledger/account/${forAccount.publicKeyString}/pending',
    ),
    method: RequestMethod.get.value,
  );

  /// Creates endpoints for getting pending block (multiple reps)
  static List<Endpoint> pendingBlock({
    required final Account forAccount,
    required final Set<String> fromRepUrls,
  }) => fromRepUrls
      .map(
        (final String baseUrl) =>
            pendingBlockSingle(forAccount: forAccount, baseUrl: baseUrl),
      )
      .toList();

  /// Creates endpoints for publishing vote staple
  static List<Endpoint> publishVoteStaple({
    required final VoteStaple voteStaple,
    required final Set<String> toRepUrls,
  }) {
    final Map<String, String> body = <String, String>{
      'votesAndBlocks': voteStaple.toBase64String(),
    };
    return toRepUrls
        .map(
          (final String baseUrl) => Endpoint(
            url: Uri.parse('$baseUrl/node/publish'),
            method: RequestMethod.post.value,
            body: body,
          ),
        )
        .toList();
  }

  /// Creates endpoint for getting representatives
  static Endpoint representatives({required final String baseUrl}) => Endpoint(
    url: Uri.parse('$baseUrl/node/ledger/representatives'),
    method: RequestMethod.get.value,
  );

  /// Creates endpoint for getting account info
  static Endpoint accountInfo({
    required final Account ofAccount,
    required final String baseUrl,
  }) => Endpoint(
    url: Uri.parse('$baseUrl/node/ledger/account/${ofAccount.publicKeyString}'),
    method: RequestMethod.get.value,
  );

  /// Creates endpoint for getting block by hash
  static Endpoint blockByHash({
    required final String hash,
    required final String baseUrl,
    final LedgerSide? side,
  }) {
    final String path = '/node/ledger/block/$hash';
    return Endpoint(
      url: Uri.parse(baseUrl + path),
      method: RequestMethod.get.value,
      query: side != null
          ? <String, String>{'side': side.rawValue}
          : <String, String>{},
    );
  }

  /// Creates endpoint for getting block by idempotent key
  static Endpoint blockByIdempotent({
    required final Account forAccount,
    required final String idempotent,
    required final LedgerSide side,
    required final String baseUrl,
  }) {
    final String path =
        '/node/ledger/account/${forAccount.publicKeyString}/idempotent/$idempotent';
    return Endpoint(
      url: Uri.parse(baseUrl + path),
      method: RequestMethod.get.value,
      query: <String, String>{'side': side.rawValue},
    );
  }

  /// Creates endpoint for getting account history
  static Endpoint history({
    required final Account forAccount,
    required final int limit,
    required final String baseUrl,
    final String? startBlockHash,
  }) {
    String path = '/node/ledger/account/${forAccount.publicKeyString}/history';

    if (startBlockHash != null) {
      path += '/start/$startBlockHash';
    }

    return Endpoint(
      url: Uri.parse(baseUrl + path),
      method: RequestMethod.get.value,
      query: <String, String>{'limit': '$limit'},
    );
  }

  /// Helper method to convert VoteRequest to JSON
  static Map<String, dynamic> _voteRequestToJson({
    required final List<Block> blocks,
    final VoteQuote? quote,
    final List<Vote>? votes,
  }) {
    final Map<String, dynamic> json = <String, dynamic>{
      'blocks': blocks
          .map((final Block block) => block.base64String())
          .toList(),
    };

    if (quote != null) {
      json['quote'] = quote.toBase64String();
    }

    if (votes != null) {
      json['votes'] = votes
          .map((final Vote vote) => vote.toBase64String())
          .toList();
    }

    return json;
  }
}
