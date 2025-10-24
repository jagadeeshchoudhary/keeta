import 'dart:convert';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/block_feature/block.dart';
import 'package:keeta/src/utils/compression.dart';
import 'package:keeta/src/utils/custom_exception.dart';
import 'package:keeta/src/votes/fee.dart';
import 'package:keeta/src/votes/vote.dart';

class VoteStaple {
  const VoteStaple({
    required this.blocks,
    required this.votes,
    required this.data,
  });

  final List<Block> blocks;
  final List<Vote> votes;
  final Uint8List data;

  /// Creates a VoteStaple from votes and blocks
  static VoteStaple create({
    required final List<Vote> votes,
    required final List<Block> blocks,
  }) {
    if (votes.isEmpty) {
      throw CustomException.missingVotes;
    }

    // Create block hash ordering map from first vote's block list
    final Map<String, int> blockHashOrdering = <String, int>{};
    for (int i = 0; i < votes[0].blocks.length; i++) {
      blockHashOrdering[votes[0].blocks[i]] = i;
    }

    // Sort blocks by the ordering in the first vote
    final List<Block> blocksOrdered = List<Block>.from(blocks)
      ..sort((final Block a, final Block b) {
        final int aIndex = blockHashOrdering[a.hash] ?? 0;
        final int bIndex = blockHashOrdering[b.hash] ?? 0;
        return aIndex.compareTo(bIndex);
      });

    // Sort votes by their hash (as BigInt comparison)
    final List<Vote> votesOrdered = List<Vote>.from(votes)
      ..sort((final Vote a, final Vote b) {
        final BigInt aHash = BigInt.tryParse('0x${a.hash}') ?? BigInt.zero;
        final BigInt bHash = BigInt.tryParse('0x${b.hash}') ?? BigInt.zero;
        return aHash.compareTo(bHash);
      });

    // Build ASN.1 structure: SEQUENCE of [blocks_sequence, votes_sequence]
    final ASN1Sequence blocksSequence = ASN1Sequence();
    for (final Block block in blocksOrdered) {
      blocksSequence.add(ASN1OctetString(block.toData()));
    }

    final ASN1Sequence votesSequence = ASN1Sequence();
    for (final Vote vote in votesOrdered) {
      votesSequence.add(ASN1OctetString(vote.toData()));
    }

    final ASN1Sequence mainSequence = ASN1Sequence()
      ..add(blocksSequence)
      ..add(votesSequence);

    final Uint8List data = mainSequence.encodedBytes;
    return createFromData(data: Uint8List.fromList(data), compressed: false);
  }

  /// Creates a VoteStaple from base64 encoded string
  static VoteStaple createFromBase64(final String base64) {
    final Uint8List data = base64Decode(base64);
    return createFromData(data: Uint8List.fromList(data), compressed: true);
  }

  /// Creates a VoteStaple from raw data
  // ignore: prefer_constructors_over_static_methods
  static VoteStaple createFromData({
    required final Uint8List data,
    required final bool compressed,
  }) {
    final Uint8List decompressed = compressed ? decompress(data) : data;

    final ASN1Parser parser = ASN1Parser(decompressed);
    final ASN1Object asn1Object = parser.nextObject();

    if (asn1Object is! ASN1Sequence) {
      throw CustomException.invalidASN1Sequence;
    }

    final ASN1Sequence sequence = asn1Object;

    if (sequence.elements.length != 2) {
      throw CustomException.invalidASN1SequenceLength;
    }

    final ASN1Object blocksSequence = sequence.elements[0];
    final ASN1Object votesSequence = sequence.elements[1];

    if (blocksSequence is! ASN1Sequence) {
      throw CustomException.invalidASN1BlockSequence;
    }

    if (votesSequence is! ASN1Sequence) {
      throw CustomException.invalidASN1VotesSequence;
    }

    // Parse votes
    final List<Vote> votes = <Vote>[];
    for (final ASN1Object voteAsn1 in votesSequence.elements) {
      if (voteAsn1 is! ASN1OctetString) {
        throw CustomException.invalidASN1VoteData;
      }
      votes.add(Vote.fromData(data: voteAsn1.valueBytes()));
    }

    // Parse blocks (unordered)
    final List<Block> unorderedBlocks = <Block>[];
    for (final ASN1Object blockAsn1 in blocksSequence.elements) {
      if (blockAsn1 is! ASN1OctetString) {
        throw CustomException.invalidASN1BlockData;
      }
      unorderedBlocks.add(Block.fromData(data: blockAsn1.valueBytes()));
    }

    final Map<String, Block> blockHashes = <String, Block>{
      for (final Block block in unorderedBlocks) block.hash: block,
    };

    // Ensure there is at least one vote for each block
    final Set<String> allVotedBlockHashes = <String>{};
    for (final Vote vote in votes) {
      allVotedBlockHashes.addAll(vote.blocks);
    }

    if (allVotedBlockHashes.length != unorderedBlocks.length) {
      throw CustomException.blocksAndVotesCountNotMatching;
    }

    // Order blocks by the vote ordering (first vote's block list)
    final List<Block> orderedBlocks = <Block>[];
    for (final String blockHash in votes[0].blocks) {
      final Block? block = blockHashes[blockHash.toUpperCase()];
      if (block != null) {
        orderedBlocks.add(block);
      }
    }

    if (unorderedBlocks.length != orderedBlocks.length) {
      throw CustomException.inconsistentBlocksAndVoteBlocks;
    }

    // Ensure blocks are sorted the same way in all votes
    final List<String> orderedBlockHashes = orderedBlocks
        .map((final Block b) => b.hash.toLowerCase())
        .toList();

    for (final Vote vote in votes) {
      if (!_listEquals(orderedBlockHashes, vote.blocks)) {
        throw CustomException.inconsistentVoteBlockHashesOrder;
      }
    }

    // Ensure no representative has more than 1 vote in the bundle
    // and that every vote has the same level of permanence
    final Set<String> seenReps = <String>{};
    bool? votesPermanence;

    for (final Vote vote in votes) {
      if (!seenReps.add(vote.issuer.publicKeyString)) {
        throw CustomException.repVotedMoreThanOnce;
      }

      if (votesPermanence == null) {
        votesPermanence = vote.permanent;
      } else if (votesPermanence != vote.permanent) {
        throw CustomException.inconsistentVotePermanence;
      }
    }

    return VoteStaple(blocks: orderedBlocks, votes: votes, data: decompressed);
  }

  /// Returns base64 encoded string of the staple data
  String toBase64String() => base64Encode(data);

  /// Total amount of each token in fees
  Map<String, BigInt> totalFees({required final Account baseToken}) {
    final Map<String, BigInt> result = <String, BigInt>{};

    for (final Vote vote in votes) {
      final Fee? fee = vote.fee;
      if (fee != null) {
        final String token = (fee.token ?? baseToken).publicKeyString;
        result[token] = (result[token] ?? BigInt.zero) + fee.amount;
      }
    }

    return result;
  }

  /// Total fees across all votes (sum of all amounts)
  BigInt get totalFeesSum => votes.fold(
    BigInt.zero,
    (final BigInt sum, final Vote vote) =>
        sum + (vote.fee?.amount ?? BigInt.zero),
  );

  /// Helper method to compare two lists for equality
  static bool _listEquals<T>(final List<T> a, final List<T> b) {
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
