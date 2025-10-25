import 'package:keeta/src/utils/oid.dart';

class CustomException implements Exception {
  const CustomException(this.message);
  const CustomException.invalidPublicKeyAlgo({required final String key})
    : message = 'Invalid Public Key Algorithm: $key';

  const CustomException.invalidPublicKeyLength(final int length)
    : message = 'Invalid public key length: $length';

  const CustomException.unknownSignatureInfoOID(
    final String signatureInfoOidValue,
  ) : message = 'Unknown Signature Info OID: $signatureInfoOidValue';

  const CustomException.unknownSignatureDataOID(
    final String voteSignatureInfoOidValue,
  ) : message = 'Unknown Signature Data OID: $voteSignatureInfoOidValue';

  const CustomException.unknownCriticalExtension(final OID oid)
    : message = 'Unknown Critical Extension: $oid';

  const CustomException.clientRepresentativeNotFound(
    final String publicKeyString,
  ) : message =
          'Client Representative Not Found for public key: $publicKeyString';

  const CustomException.noVotes(final List<Object> errors)
    : message = 'No Votes: $errors';

  const CustomException.blockContentDecodingError(final String s)
    : message = 'Block Content Decoding Error: $s';

  const CustomException.noPendingBlock(final List<Object> errors)
    : message = 'No Pending Block: $errors';

  const CustomException.invalidSupplyValue(final String? param0)
    : message = 'Invalid Supply Value: $param0';

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

  static CustomException invalidContextSpecificTag = const CustomException(
    'Invalid context specific tag',
  );

  static CustomException invalidQuote = const CustomException('Invalid quote');

  static CustomException invalidImplicitTag = const CustomException(
    'Invalid implicit tag',
  );

  static CustomException invalidCertificateSequence = const CustomException(
    'Invalid certificate sequence',
  );

  static CustomException invalidCertificateSequenceLength =
      const CustomException('Invalid certificate sequence length');

  static CustomException invalidX509Data = const CustomException(
    'Invalid X509 data',
  );

  static CustomException invalidCertificateValue = const CustomException(
    'Invalid certificate value',
  );

  static CustomException invalidSignatureInfoSequence = const CustomException(
    'Invalid signature info sequence',
  );

  static CustomException invalidSignatureInfoSequenceLength =
      const CustomException('Invalid signature info sequence length');

  static CustomException invalidSignatureInfoOID = const CustomException(
    'Invalid signature info OID',
  );

  static CustomException invalidIssuerData = const CustomException(
    'Invalid issuer data',
  );

  static CustomException invalidValidityData = const CustomException(
    'Invalid validity data',
  );

  static CustomException invalidValiditySequenceLength = const CustomException(
    'Invalid validity sequence length',
  );

  static CustomException invalidValidity = const CustomException(
    'Invalid validity',
  );

  static CustomException invalidSubjectData = const CustomException(
    'Invalid subject data',
  );

  static CustomException serialMismatch = const CustomException(
    'Serial mismatch',
  );

  static CustomException invalidSignatureSequence = const CustomException(
    'Invalid signature sequence',
  );

  static CustomException invalidSignatureSequenceLength = const CustomException(
    'Invalid signature sequence length',
  );

  static CustomException invalidSignatureDataOID = const CustomException(
    'Invalid signature data OID',
  );

  static CustomException signatureInformationMismatch = const CustomException(
    'Signature information mismatch',
  );

  static CustomException issuerSignatureSchemeMismatch = const CustomException(
    'Issuer signature scheme mismatch',
  );

  static CustomException unsupportedSignatureScheme = const CustomException(
    'Unsupported signature scheme',
  );

  static CustomException invalidSignatureDataBitString = const CustomException(
    'Invalid signature data bit string',
  );

  static CustomException invalidSignatureData = const CustomException(
    'Invalid signature data',
  );

  static CustomException invalidExtensions = const CustomException(
    'Invalid extensions',
  );

  static CustomException invalidExtensionSequence = const CustomException(
    'Invalid extension sequence',
  );

  static CustomException invalidExtensionOID = const CustomException(
    'Invalid extension OID',
  );

  static CustomException invalidExtensionCriticalCheck = const CustomException(
    'Invalid extension critical check',
  );

  static CustomException invalidHashDataExtension = const CustomException(
    'Invalid hash data extension',
  );

  static CustomException invalidFeeDataExtension = const CustomException(
    'Invalid fee data extension',
  );

  static CustomException permanentVoteCanNotHaveFees = const CustomException(
    'Permanent vote can not have fees',
  );

  static CustomException missingVotes = const CustomException('Missing votes');

  static CustomException invalidASN1BlockSequence = const CustomException(
    'Invalid ASN.1 block sequence',
  );

  static CustomException invalidASN1VotesSequence = const CustomException(
    'Invalid ASN.1 votes sequence',
  );

  static CustomException invalidASN1VoteData = const CustomException(
    'Invalid ASN.1 vote data',
  );

  static CustomException invalidASN1BlockData = const CustomException(
    'Invalid ASN.1 block data',
  );

  static CustomException blocksAndVotesCountNotMatching = const CustomException(
    'Blocks and votes count not matching',
  );

  static CustomException inconsistentBlocksAndVoteBlocks =
      const CustomException('Inconsistent blocks and vote blocks');

  static CustomException inconsistentVoteBlockHashesOrder =
      const CustomException('Inconsistent vote block hashes order');

  static CustomException repVotedMoreThanOnce = const CustomException(
    'Representative voted more than once',
  );

  static CustomException inconsistentVotePermanence = const CustomException(
    'Inconsistent vote permanence',
  );

  static CustomException invalidPermanentVote = const CustomException(
    'Invalid permanent vote',
  );

  static CustomException missingFeeExtension = const CustomException(
    'Missing fee extension',
  );

  static CustomException notPublished = const CustomException('Not published');

  static CustomException blockAccountMismatch = const CustomException(
    'Block account mismatch',
  );

  static CustomException blockHashMismatch = const CustomException(
    'Block hash mismatch',
  );

  static CustomException feesRequiredButFeeBuilderMissing =
      const CustomException('Fees required but FeeBuilder missing');

  static CustomException invalidIdempotentData = const CustomException(
    'Invalid idempotent data',
  );

  static CustomException invalidString = const CustomException(
    'Invalid string',
  );

  static CustomException cantForwardToFromAccount = const CustomException(
    'Cannot forward to the from account',
  );

  static CustomException invalidForward = const CustomException(
    'Invalid forward',
  );

  static CustomException missingAccount = const CustomException(
    'Missing account',
  );

  static CustomException invalidTokenAccount = const CustomException(
    'Invalid token account',
  );

  static CustomException feeAccountMissing = const CustomException(
    'Fee account missing',
  );

  static CustomException noTokenAccount = const CustomException(
    'No token account',
  );

  static CustomException noTokenSupply = const CustomException(
    'No token supply',
  );

  @override
  String toString() => message;
}
