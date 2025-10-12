class MetaData {
  MetaData({required this.decimalPlaces});

  factory MetaData.fromJson(final Map<String, dynamic> json) =>
      MetaData(decimalPlaces: json['decimalPlaces'] as int);
  final int decimalPlaces;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'decimalPlaces': decimalPlaces,
  };
}
