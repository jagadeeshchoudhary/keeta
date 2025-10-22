/// Represents a client representative with connection information
class ClientRepresentative {
  const ClientRepresentative({
    required this.address,
    required this.apiUrl,
    required this.socketUrl,
    this.weight,
  });

  final String address;
  final String apiUrl;
  final String socketUrl;
  final BigInt? weight;
}

/// Extension methods for List of ClientRepresentative
extension ClientRepresentativeListExtensions on List<ClientRepresentative> {
  /// Returns the preferred representative (one with maximum weight)
  ClientRepresentative? get preferred {
    if (isEmpty) {
      return null;
    }

    return reduce((
      final ClientRepresentative current,
      final ClientRepresentative next,
    ) {
      final BigInt currentWeight = current.weight ?? BigInt.zero;
      final BigInt nextWeight = next.weight ?? BigInt.zero;
      return currentWeight >= nextWeight ? current : next;
    });
  }
}
