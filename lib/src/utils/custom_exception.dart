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

  static const CustomException invalidSignature = CustomException(
    'Invalid Signature',
  );
  static const CustomException invalidVersion = CustomException(
    'Invalid Version',
  );
  static const CustomException invalidASN1Sequence = CustomException(
    'Invalid ASN.1 sequence',
  );
  static const CustomException invalidASN1Schema = CustomException(
    'Invalid ASN.1 schema',
  );
  static const CustomException invalidASN1SequenceLength = CustomException(
    'Invalid ASN.1 sequence length',
  );
  static const CustomException invalidNetwork = CustomException(
    'Invalid Network',
  );
  static const CustomException invalidDate = CustomException('Invalid Date');
  static const CustomException invalidSigner = CustomException(
    'Invalid Signer',
  );
  static const CustomException redundantAccount = CustomException(
    'Redundant Account',
  );
  static const CustomException invalidHash = CustomException('Invalid Hash');
  static const CustomException invalidOperationsSequence = CustomException(
    'Invalid Operations Sequence',
  );
  static const CustomException invalidPurpose = CustomException(
    'Invalid Purpose',
  );

  static const CustomException invalidSequence = CustomException(
    'Invalid sequence',
  );
  static const CustomException invalidTag = CustomException('Invalid tag');
  static const CustomException invalidOperationType = CustomException(
    'Invalid operation type',
  );

  @override
  String toString() => message;
}
