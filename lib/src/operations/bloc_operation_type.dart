/// ------------------- BlockOperationType -------------------
enum BlockOperationType {
  send,
  setRep,
  setInfo,
  createIdentifier,
  tokenAdminSupply,
  tokenAdminModifyBalance,
  receive,
}

extension BlockOperationTypeX on BlockOperationType {
  int get rawValue {
    switch (this) {
      case BlockOperationType.send:
        return 0;
      case BlockOperationType.setRep:
        return 1;
      case BlockOperationType.setInfo:
        return 2;
      case BlockOperationType.createIdentifier:
        return 4;
      case BlockOperationType.tokenAdminSupply:
        return 5;
      case BlockOperationType.tokenAdminModifyBalance:
        return 6;
      case BlockOperationType.receive:
        return 7;
    }
  }
}
