class CustomException implements Exception {
  const CustomException(this.message);
  final String message;

  static const CustomException signingNotSupported = CustomException(
    'Signing not supported',
  );
  static const CustomException verifyingNotSupported = CustomException(
    'Verifying not supported',
  );
  static const CustomException noPrivateKey = CustomException(
    'No private key available',
  );
  static const CustomException invalidDERSignature = CustomException(
    'Invalid DER signature length',
  );

  @override
  String toString() => message;
}
