class TokenInfo {
  TokenInfo({
    required this.address,
    required this.name,
    required this.supply,
    required this.decimalPlaces,
    this.description,
  });

  factory TokenInfo.fromJson(final Map<String, dynamic> json) => TokenInfo(
    address: json['address'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    supply: (json['supply'] as num).toDouble(),
    decimalPlaces: json['decimalPlaces'] as int,
  );
  final String name;
  final String address;
  final String? description;
  final double supply;
  final int decimalPlaces;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'address': address,
    'name': name,
    'description': description,
    'supply': supply,
    'decimalPlaces': decimalPlaces,
  };
}
