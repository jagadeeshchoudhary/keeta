class HistoryResponse {
  const HistoryResponse({required this.history});

  factory HistoryResponse.fromJson(final Map<String, dynamic> json) =>
      HistoryResponse(
        history: (json['history'] as List<dynamic>)
            .map((final dynamic e) => HistoryContentResponse.fromJson(e))
            .toList(),
      );
  final List<HistoryContentResponse> history;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'history': history
        .map((final HistoryContentResponse e) => e.toJson())
        .toList(),
  };
}

class HistoryContentResponse {
  const HistoryContentResponse({
    required this.id,
    required this.timestamp,
    required this.voteStaple,
  });

  factory HistoryContentResponse.fromJson(final Map<String, dynamic> json) =>
      HistoryContentResponse(
        id: json[r'$id'] as String,
        timestamp: json[r'$timestamp'] as String,
        voteStaple: VoteStapleContentResponse.fromJson(
          json['voteStaple'] as Map<String, dynamic>,
        ),
      );
  final String id;
  final String timestamp;
  final VoteStapleContentResponse voteStaple;

  Map<String, dynamic> toJson() => <String, dynamic>{
    r'$id': id,
    r'$timestamp': timestamp,
    'voteStaple': voteStaple.toJson(),
  };
}

class VoteStapleContentResponse {
  const VoteStapleContentResponse({required this.binary});

  factory VoteStapleContentResponse.fromJson(final Map<String, dynamic> json) =>
      VoteStapleContentResponse(binary: json[r'$binary'] as String);
  final String binary;

  Map<String, dynamic> toJson() => <String, dynamic>{r'$binary': binary};
}
