class AccountInfo {

  const AccountInfo({
    required this.name,
    required this.description,
    required this.metadata,
    this.supply,
  });
  final String name;
  final String description;
  final String metadata;
  final BigInt? supply;
}
