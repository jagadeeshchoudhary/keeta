class RepresentativesResponse {
  RepresentativesResponse({required this.representatives});

  factory RepresentativesResponse.fromJson(final Map<String, dynamic> json) =>
      RepresentativesResponse(
        representatives: (json['representatives'] as List<dynamic>)
            .map((final dynamic r) => RepresentativeResponse.fromJson(r))
            .toList(),
      );
  final List<RepresentativeResponse> representatives;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'representatives': representatives
        .map((final RepresentativeResponse r) => r.toJson())
        .toList(),
  };
}

class RepresentativeResponse {
  RepresentativeResponse({
    required this.representative,
    required this.weight,
    required this.endpoints,
  });

  factory RepresentativeResponse.fromJson(final Map<String, dynamic> json) =>
      RepresentativeResponse(
        representative: json['representative'] as String,
        weight: json['weight'] as String,
        endpoints: Endpoints.fromJson(json['endpoints']),
      );
  final String representative;
  final String weight;
  final Endpoints endpoints;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'representative': representative,
    'weight': weight,
    'endpoints': endpoints.toJson(),
  };
}

class Endpoints {
  Endpoints({required this.api, required this.p2p});

  factory Endpoints.fromJson(final Map<String, dynamic> json) =>
      Endpoints(api: json['api'] as String, p2p: json['p2p'] as String);
  final String api;
  final String p2p;

  Map<String, dynamic> toJson() => <String, dynamic>{'api': api, 'p2p': p2p};
}
