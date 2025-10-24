import 'package:keeta/src/networking/responses/certificate_content_response.dart';

class BlockVoteResponse {
  const BlockVoteResponse({required this.blockhash, this.votes});

  factory BlockVoteResponse.fromJson(final Map<String, dynamic> json) {
    final List<dynamic>? votesJson = json['votes'] as List<dynamic>?;
    return BlockVoteResponse(
      blockhash: json['blockhash'] as String,
      votes: votesJson
          ?.map(
            (final dynamic item) => CertificateContentResponse.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final String blockhash;
  final List<CertificateContentResponse>? votes;
}

class VoteResponse {
  const VoteResponse({required this.vote});

  factory VoteResponse.fromJson(final Map<String, dynamic> json) =>
      VoteResponse(
        vote: CertificateContentResponse.fromJson(
          json['vote'] as Map<String, dynamic>,
        ),
      );

  final CertificateContentResponse vote;
}
