import 'package:keeta/src/utils/oid.dart';

class CustomException implements Exception {
  const CustomException(this.message);
  const CustomException.invalidPublicKeyAlgo({required final String key})
    : message = 'Invalid Public Key Algorithm: $key';

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

  static const CustomException invalidAmount = CustomException(
    'Invalid amount',
  );

  static const CustomException invalidSequenceLength = CustomException(
    'Invalid sequence length',
  );

  static const CustomException invalidTo = CustomException('Invalid to');

  static const CustomException invalidToken = CustomException('Invalid token');
  static const CustomException invalidAdjustMethod = CustomException(
    'Invalid Method',
  );
  static const CustomException invalidIdentifier = CustomException(
    'Invalid Identifier',
  );

  static const CustomException invalidName = CustomException('Invalid Name');

  static const CustomException invalidDescription = CustomException(
    'Invalid Description',
  );

  static const CustomException metaData = CustomException('Invalid MetaData');
  static const CustomException invalidPermissionSequenceLength =
      CustomException('Invalid Permission Sequence Length');

  static const CustomException invalidPermissionFlags = CustomException(
    'Invalid Permission Flags',
  );

  static const CustomException unknownPermissionFlag = CustomException(
    'Unknown Permission Flag',
  );

  static const CustomException cantForwardtoSameAccount = CustomException(
    'Can not Forward To Same Account.',
  );

  static const CustomException invalidExactWhenForwarding = CustomException(
    'Invalid Exact When Forward',
  );

  static const CustomException invalidFrom = CustomException('Invalid From');

  static const CustomException invalidExact = CustomException('Invalid Exact');

  static const CustomException seedIndexNegative = CustomException(
    'seedIndexNegative',
  );
  static const CustomException seedIndexTooLarge = CustomException(
    'seedIndexTooLarge',
  );
  static const CustomException invalidPublicKeyPrefix = CustomException(
    'invalidPublicKeyPrefix',
  );
  static const CustomException invalidPublicKeyChecksum = CustomException(
    'invalidPublicKeyChecksum',
  );
  static const CustomException invalidInput = CustomException('Invalid Input');
  static const CustomException invalidLength = CustomException(
    'Invalid Length',
  );

  static const CustomException invalidBlocksTag = CustomException(
    'Invalid blocks tag',
  );
  static const CustomException invalidBlocksDataSequence = CustomException(
    'Invalid blocks data sequence',
  );
  static const CustomException invalidBlocksSequenceLength = CustomException(
    'Invalid blocks sequence length',
  );
  static const CustomException invalidBlocksOID = CustomException(
    'Invalid blocks OID',
  );
  static const CustomException unknownHashFunction = CustomException(
    'Unknown hash function',
  );
  static const CustomException unsupportedHashFunction = CustomException(
    'Unsupported hash function',
  );
  static const CustomException invalidBlocksSequence = CustomException(
    'Invalid blocks sequence',
  );
  static const CustomException invalidBlockHash = CustomException(
    'Invalid block hash',
  );

  static const CustomException multipleSetRepOperations = CustomException(
    'Multiple set representative operations found in block',
  );
  static const CustomException insufficientDataToSignBlock = CustomException(
    'insufficient data to sign block',
  );
  static const CustomException negativeNetworkId = CustomException(
    'negative network id',
  );
  static const CustomException negativeSubnetId = CustomException(
    'negative subnet id',
  );
  static const CustomException noPrivateKeyOrSignatureToSignBlock =
      CustomException('no private key or signature to sign block');
  static const CustomException invalidBalanceValue = CustomException(
    'invalid balance value',
  );
  static const CustomException insufficientBalanceToCoverNetworkFees =
      CustomException('insufficient balance to cover network fees');

  static var invalidContextSpecificTag;

  static var invalidQuote;

  static var invalidImplicitTag;

  static var invalidCertificateSequence;

  static var invalidCertificateSequenceLength;

  static var invalidX509Data;

  static var invalidCertificateValue;

  static var invalidSignatureInfoSequence;

  static var invalidSignatureInfoSequenceLength;

  static var invalidSignatureInfoOID;

  static var invalidIssuerData;

  static var invalidValidityData;

  static var invalidValiditySequenceLength;

  static var invalidValidity;

  static var invalidSubjectData;

  static var serialMismatch;

  static var invalidSignatureSequence;

  static var invalidSignatureSequenceLength;

  static var invalidSignatureDataOID;

  static var signatureInformationMismatch;

  static var issuerSignatureSchemeMismatch;

  static var unsupportedSignatureScheme;

  static var invalidSignatureDataBitString;

  static var invalidSignatureData;

  static var invalidExtensions;

  static var invalidExtensionSequence;

  static var invalidExtensionOID;

  static var invalidExtensionCriticalCheck;

  static var invalidHashDataExtension;

  static var invalidFeeDataExtension;

  static var permanentVoteCanNotHaveFees;

  static var missingVotes;

  static var invalidASN1BlockSequence;

  static var invalidASN1VotesSequence;

  static var invalidASN1VoteData;

  static var invalidASN1BlockData;

  static var blocksAndVotesCountNotMatching;

  static var inconsistentBlocksAndVoteBlocks;

  static var inconsistentVoteBlockHashesOrder;

  static var repVotedMoreThanOnce;

  static var inconsistentVotePermanence;

  static var invalidPermanentVote;

  static var missingFeeExtension;

  static var notPublished;

  static var blockAccountMismatch;

  static var blockHashMismatch;

  static var feesRequiredButFeeBuilderMissing;

  static var invalidIdempotentData;

  @override
  String toString() => message;

  static unknownSignatureInfoOID(String signatureInfoOidValue) {}

  static unknownSignatureDataOID(String voteSignatureInfoOidValue) {}

  static unknownCriticalExtension(OID oid) {}

  static clientRepresentativeNotFound(String publicKeyString) {}

  static noVotes(List<Object> errors) {}

  static blockContentDecodingError(String s) {}

  static noPendingBlock(List<Object> errors) {}

  static invalidSupplyValue(param0) {}
}
