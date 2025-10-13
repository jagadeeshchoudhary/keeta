class CustomException implements Exception {
  const CustomException(this.message);

  const CustomException.invalidPublicKeyLength(final int length)
    : message = 'Invalid public key length: $length';

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
  static const CustomException invalidIdentifierAccount = CustomException(
    'Invalid identifier account',
  );
  static const CustomException invalidIdentifierAlgorithm = CustomException(
    'Invalid identifier algorithm',
  );
  static const CustomException invalidDataLength = CustomException(
    'Invalid data length',
  );

  @override
  String toString() => message;
}
