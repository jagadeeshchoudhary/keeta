import 'dart:typed_data';

import 'package:keeta/src/utils/custom_exception.dart';
import 'package:keeta/src/utils/string_to_bytes.dart';
import 'package:meta/meta.dart';

/// Immutable key pair containing a public key and optional private key.
/// Provides signing and verification capabilities
/// through algorithm-specific utilities.
@immutable
class KeyPair {
  const KeyPair({required this.publicKey, final String? privateKey})
    : _privateKey = privateKey;

  /// Creates a KeyPair from JSON representation.
  factory KeyPair.fromJson(final Map<String, dynamic> json) => KeyPair(
    publicKey: json['publicKey'] as String,
    privateKey: json['privateKey'] as String?,
  );

  /// The public key as a hex string (uppercase).
  final String publicKey;

  /// The private key as a hex string (uppercase), null if not available.
  final String? _privateKey;

  /// Returns true if this key pair has a private key available for signing.
  bool get hasPrivateKey => _privateKey != null;

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! KeyPair) {
      return false;
    }

    return publicKey.toLowerCase() == other.publicKey.toLowerCase() &&
        (_privateKey?.toLowerCase() ?? '') ==
            (other._privateKey?.toLowerCase() ?? '');
  }

  @override
  int get hashCode => publicKey.hashCode;

  // @override
  // int get hashCode =>
  //     publicKey.toLowerCase().hashCode ^
  //     (_privateKey?.toLowerCase().hashCode ?? 0);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'publicKey': publicKey,
    'privateKey': _privateKey,
  };

  /// Signs data using the private key and the provided signing utility.
  /// Throws an exception if no private key is available.
  Uint8List sign({
    required final Uint8List data,
    required final Signable using,
  }) {
    if (_privateKey == null) {
      throw CustomException.noPrivateKey;
    }

    final Uint8List privateKeyBytes = _privateKey.toBytes();
    return using.sign(data: data, key: privateKeyBytes);
  }

  /// Verifies a signature against the data using the public key
  /// and verification utility.
  bool verify({
    required final Uint8List data,
    required final Uint8List signature,
    required final Verifiable using,
  }) {
    final Uint8List publicKeyBytes = publicKey.toBytes();
    return using.verify(data: data, signature: signature, key: publicKeyBytes);
  }
}

/// Interface for creating key pairs from seeds or private keys.
abstract interface class KeyCreateable {
  /// Creates a key pair from a seed using algorithm-specific derivation.
  KeyPair create({required final String fromSeed});

  /// Creates a key pair from an existing private key.
  KeyPair keypair({required final String fromPrivateKey});
}

/// Interface for signing data with a private key.
abstract interface class Signable {
  /// Signs the provided data using the given private key.
  Uint8List sign({required final Uint8List data, required final Uint8List key});
}

/// Interface for verifying signatures with a public key.
abstract interface class Verifiable {
  /// Verifies a signature against the provided data and public key.
  bool verify({
    required final Uint8List data,
    required final Uint8List signature,
    required final Uint8List key,
  });

  /// Converts a DER-encoded signature to the algorithm's native format.
  Uint8List signatureFromDER(final Uint8List signature);
}

/// Complete interface combining all cryptographic operations.
abstract interface class KeyUtils
    implements KeyCreateable, Signable, Verifiable {}
