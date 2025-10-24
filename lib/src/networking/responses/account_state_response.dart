class AccountStateResponse {
  AccountStateResponse({
    required this.balances,
    required this.info,
    required this.account,
    this.currentHeadBlock,
    this.representative,
  });

  factory AccountStateResponse.fromJson(final Map<String, dynamic> json) =>
      AccountStateResponse(
        account: json['account'] as String,
        currentHeadBlock: json['currentHeadBlock'] as String?,
        representative: json['representative'] as String?,
        balances: (json['balances'] as List<dynamic>)
            .map((final dynamic b) => AccountBalanceResponse.fromJson(b))
            .toList(),
        info: AccountInfoResponse.fromJson(json['info']),
      );
  final String account;
  final String? currentHeadBlock;
  final String? representative;
  final List<AccountBalanceResponse> balances;
  final AccountInfoResponse info;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'account': account,
    'currentHeadBlock': currentHeadBlock,
    'representative': representative,
    'balances': balances
        .map((final AccountBalanceResponse b) => b.toJson())
        .toList(),
    'info': info.toJson(),
  };
}

class AccountInfoResponse {
  // final Permissions? defaultPermission; // uncomment when implemented

  AccountInfoResponse({
    required this.name,
    required this.description,
    required this.metadata,
    this.supply,
    // this.defaultPermission,
  });

  factory AccountInfoResponse.fromJson(final Map<String, dynamic> json) =>
      AccountInfoResponse(
        name: json['name'] as String,
        description: json['description'] as String,
        metadata: json['metadata'] as String,
        supply: json['supply'] as String?,
        // defaultPermission: json['defaultPermission'] != null
        //     ? Permissions.fromJson(json['defaultPermission'])
        //     : null,
      );
  final String name;
  final String description;
  final String metadata;
  final String? supply;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'description': description,
    'metadata': metadata,
    'supply': supply,
    // 'defaultPermission': defaultPermission?.toJson(),
  };
}

class AccountBalanceResponse {
  AccountBalanceResponse({required this.token, required this.balance});

  factory AccountBalanceResponse.fromJson(final Map<String, dynamic> json) =>
      AccountBalanceResponse(
        token: json['token'] as String,
        balance: json['balance'] as String,
      );
  final String token;
  final String balance;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'token': token,
    'balance': balance,
  };
}
