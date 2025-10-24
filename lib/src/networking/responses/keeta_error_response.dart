class KeetaErrorResponse {
  const KeetaErrorResponse({
    required this.error,
    required this.code,
    required this.type,
    required this.message,
  });

  factory KeetaErrorResponse.fromJson(final Map<String, dynamic> json) =>
      KeetaErrorResponse(
        error: json['error'] as bool,
        code: ErrorCodeExtension.fromString(json['code'] as String),
        type: ErrorTypeExtension.fromString(json['type'] as String),
        message: json['message'] as String,
      );

  final bool error;
  final ErrorCode code;
  final ErrorType type;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'error': error,
    'code': code.stringValue,
    'type': type.stringValue,
    'message': message,
  };
}

enum ErrorType { ledger, block }

extension ErrorTypeExtension on ErrorType {
  String get stringValue {
    switch (this) {
      case ErrorType.ledger:
        return 'LEDGER';
      case ErrorType.block:
        return 'BLOCK';
    }
  }

  static ErrorType fromString(final String value) {
    switch (value) {
      case 'LEDGER':
        return ErrorType.ledger;
      case 'BLOCK':
        return ErrorType.block;
      default:
        throw ArgumentError('Unknown ErrorType: $value');
    }
  }
}

enum ErrorCode {
  successorVoteExists,
  ledgerInvalidChain,
  ledgerReceiveNotMet,
  ledgerInvalidBalance,
  ledgerInvalidPermissions,
  ledgerPreviousAlreadyUsed,
  ledgerNotEmpty,
  ledgerOther,
  ledgerInsufficientVotingWeight,
  ledgerIdempotentKeyAlreadyExists,
  blockOnlyTokenOperation,
  blockNoTokenOperation,
  blockFieldInvalid,
  blockInvalidIdentifier,
  missingRequiredFeeBlock,
}

extension ErrorCodeExtension on ErrorCode {
  String get stringValue {
    switch (this) {
      case ErrorCode.successorVoteExists:
        return 'LEDGER_SUCCESSOR_VOTE_EXISTS';
      case ErrorCode.ledgerInvalidChain:
        return 'LEDGER_INVALID_CHAIN';
      case ErrorCode.ledgerReceiveNotMet:
        return 'LEDGER_RECEIVE_NOT_MET';
      case ErrorCode.ledgerInvalidBalance:
        return 'LEDGER_INVALID_BALANCE';
      case ErrorCode.ledgerInvalidPermissions:
        return 'LEDGER_INVALID_PERMISSIONS';
      case ErrorCode.ledgerPreviousAlreadyUsed:
        return 'LEDGER_PREVIOUS_ALREADY_USED';
      case ErrorCode.ledgerNotEmpty:
        return 'LEDGER_NOT_EMPTY';
      case ErrorCode.ledgerOther:
        return 'LEDGER_OTHER';
      case ErrorCode.ledgerInsufficientVotingWeight:
        return 'LEDGER_INSUFFICIENT_VOTING_WEIGHT';
      case ErrorCode.ledgerIdempotentKeyAlreadyExists:
        return 'LEDGER_IDEMPOTENT_KEY_EXISTS';
      case ErrorCode.blockOnlyTokenOperation:
        return 'BLOCK_ONLY_TOKEN_OP';
      case ErrorCode.blockNoTokenOperation:
        return 'BLOCK_NO_TOKEN_OP';
      case ErrorCode.blockFieldInvalid:
        return 'BLOCK_GENERAL_FIELD_INVALID';
      case ErrorCode.blockInvalidIdentifier:
        return 'BLOCK_IDENTIFIER_INVALID';
      case ErrorCode.missingRequiredFeeBlock:
        return 'LEDGER_MISSING_REQUIRED_FEE_BLOCK';
    }
  }

  static ErrorCode fromString(final String value) {
    switch (value) {
      case 'LEDGER_SUCCESSOR_VOTE_EXISTS':
        return ErrorCode.successorVoteExists;
      case 'LEDGER_INVALID_CHAIN':
        return ErrorCode.ledgerInvalidChain;
      case 'LEDGER_RECEIVE_NOT_MET':
        return ErrorCode.ledgerReceiveNotMet;
      case 'LEDGER_INVALID_BALANCE':
        return ErrorCode.ledgerInvalidBalance;
      case 'LEDGER_INVALID_PERMISSIONS':
        return ErrorCode.ledgerInvalidPermissions;
      case 'LEDGER_PREVIOUS_ALREADY_USED':
        return ErrorCode.ledgerPreviousAlreadyUsed;
      case 'LEDGER_NOT_EMPTY':
        return ErrorCode.ledgerNotEmpty;
      case 'LEDGER_OTHER':
        return ErrorCode.ledgerOther;
      case 'LEDGER_INSUFFICIENT_VOTING_WEIGHT':
        return ErrorCode.ledgerInsufficientVotingWeight;
      case 'LEDGER_IDEMPOTENT_KEY_EXISTS':
        return ErrorCode.ledgerIdempotentKeyAlreadyExists;
      case 'BLOCK_ONLY_TOKEN_OP':
        return ErrorCode.blockOnlyTokenOperation;
      case 'BLOCK_NO_TOKEN_OP':
        return ErrorCode.blockNoTokenOperation;
      case 'BLOCK_GENERAL_FIELD_INVALID':
        return ErrorCode.blockFieldInvalid;
      case 'BLOCK_IDENTIFIER_INVALID':
        return ErrorCode.blockInvalidIdentifier;
      case 'LEDGER_MISSING_REQUIRED_FEE_BLOCK':
        return ErrorCode.missingRequiredFeeBlock;
      default:
        throw ArgumentError('Unknown ErrorCode: $value');
    }
  }
}
