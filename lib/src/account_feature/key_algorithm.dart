import 'package:keeta/src/account_feature/ec_dsa.dart';
import 'package:keeta/src/account_feature/ed25519.dart';
import 'package:keeta/src/account_feature/identifier_key_pair.dart';
import 'package:keeta/src/account_feature/key_pair.dart';

/// Key algorithms
enum KeyAlgorithm {
  ecdsaSecp256k1(0),
  ed25519(1),
  network(2),
  token(3);

  const KeyAlgorithm(this.rawValue);
  final int rawValue;

  /// Get the utility class for this algorithm
  KeyUtils get utils {
    switch (this) {
      case KeyAlgorithm.ecdsaSecp256k1:
        return EcDSA();
      case KeyAlgorithm.ed25519:
        return Ed25519();
      case KeyAlgorithm.network:
      case KeyAlgorithm.token:
        return IdentifierKeyPair();
    }
  }

  static KeyAlgorithm fromInt(final int value) =>
      KeyAlgorithm.values.firstWhere(
        (final KeyAlgorithm e) => e.rawValue == value,
        orElse: () => throw ArgumentError('Invalid key algorithm: $value'),
      );
}
