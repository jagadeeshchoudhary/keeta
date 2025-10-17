import 'package:keeta/src/account_feature/ec_dsa.dart';
import 'package:keeta/src/account_feature/ed25519.dart';
import 'package:keeta/src/account_feature/identifier_key_pair.dart';
import 'package:keeta/src/account_feature/key_pair.dart';

/// Supported cryptographic key algorithms for account generation & operations.
/// Each algorithm provides different security properties and use cases.
enum KeyAlgorithm {
  /// ECDSA with secp256k1 curve (Bitcoin-compatible)
  ecdsaSecp256k1(0),

  /// Ed25519 elliptic curve digital signature algorithm
  ed25519(1),

  /// Network identifier (special purpose)
  network(2),

  /// Token identifier (special purpose)
  token(3);

  const KeyAlgorithm(this.rawValue);

  /// The raw integer value used in protocol encoding
  final int rawValue;

  /// Gets utility class implementing cryptographic operations for algorithm
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

  /// Creates a KeyAlgorithm from its raw integer value
  static KeyAlgorithm fromInt(final int value) =>
      KeyAlgorithm.values.firstWhere(
        (final KeyAlgorithm e) => e.rawValue == value,
        orElse: () => throw ArgumentError('Invalid key algorithm: $value'),
      );
}
