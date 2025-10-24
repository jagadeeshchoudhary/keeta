class CertificateContentResponse {
  const CertificateContentResponse({
    required this.id,
    required this.issuer,
    required this.serial,
    required this.blocks,
    required this.validityFrom,
    required this.validityTo,
    required this.signature,
    required this.binary,
  });

  factory CertificateContentResponse.fromJson(
    final Map<String, dynamic> json,
  ) => CertificateContentResponse(
    id: json[r'$uid'] as String,
    issuer: json['issuer'] as String,
    serial: json['serial'] as String,
    blocks: (json['blocks'] as List<dynamic>).cast<String>(),
    validityFrom: json['validityFrom'] as String,
    validityTo: json['validityTo'] as String,
    signature: json['signature'] as String,
    binary: json[r'$binary'] as String,
  );

  final String id;
  final String issuer;
  final String serial;
  final List<String> blocks;
  final String validityFrom;
  final String validityTo;
  final String signature;
  final String binary;
}
