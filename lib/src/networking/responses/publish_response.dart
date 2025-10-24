class PublishResponse {
  const PublishResponse({required this.publish});

  factory PublishResponse.fromJson(final Map<String, dynamic> json) =>
      PublishResponse(publish: json['publish'] as bool);

  final bool publish;

  Map<String, dynamic> toJson() => <String, dynamic>{'publish': publish};
}
