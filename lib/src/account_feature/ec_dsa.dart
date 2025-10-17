import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:keeta/src/account_feature/ec_dsa_signature.dart';
import 'package:keeta/src/account_feature/key_pair.dart';
import 'package:keeta/src/utils/custom_exception.dart';
import 'package:keeta/src/utils/hash.dart';
import 'package:keeta/src/utils/string_to_bytes.dart';
import 'package:pointycastle/digests/sha3.dart';
import 'package:secp256k1/secp256k1.dart';

/// ECDSA implementation using the secp256k1 elliptic curve.
/// Provides deterministic key generation, signing, and verification using
/// HKDF for key derivation and SHA3-256 for message hashing.
class EcDSA implements KeyUtils {
  /// Converts a byte array to a BigInt for cryptographic operations.
  static BigInt _bytesToBigInt(final Uint8List bytes) => BigInt.parse(
    bytes.map((final int b) => b.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );

  /// Converts a BigInt to a fixed-length byte array for signature components.
  static Uint8List _bigIntToBytes(final BigInt value, final int length) {
    final String hex = value.toRadixString(16).padLeft(length * 2, '0');
    return Uint8List.fromList(
      List<int>.generate(
        length,
        (final int i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }

  /// Creates a KeyPair from a seed using HKDF for key derivation.
  /// Uses HKDF to derive a 32-byte private key from the seed.
  @override
  KeyPair create({required final String fromSeed}) {
    final String privateKey = Hash.hkdf(fromSeed.toBytes());
    return keypair(fromPrivateKey: privateKey);
  }

  /// Creates a KeyPair from a private key, deriving  corresponding public key.
  /// Returns the public key in compressed format (33 bytes) as uppercase hex.
  @override
  KeyPair keypair({required final String fromPrivateKey}) {
    final Uint8List privateBytes = fromPrivateKey.toBytes();
    final PrivateKey keyResult = PrivateKey.fromHex(hex.encode(privateBytes));
    final String publicKey = keyResult.publicKey
        .toCompressedHex()
        .toUpperCase();

    return KeyPair(publicKey: publicKey, privateKey: fromPrivateKey);
  }

  /// Signs data using ECDSA with secp256k1.
  /// If the data is not already a 32-byte digest, it's hashed with SHA3-256.
  /// Returns a 64-byte signature in compact format (r || s).
  @override
  Uint8List sign({
    required final Uint8List data,
    required final Uint8List key,
  }) {
    final PrivateKey privateKey = PrivateKey.fromHex(hex.encode(key));
    // If input isn't a 32-byte digest, hash it with SHA3-256
    final Uint8List digest = data.length == Hash.digestLength
        ? data
        : SHA3Digest(256).process(data);
    final String hashHex = hex.encode(digest);
    final Signature sig = privateKey.signature(hashHex);

    // Return compact representation (64 bytes: r || s)
    // Convert r and s to 32-byte arrays
    final Uint8List rBytes = _bigIntToBytes(sig.R, 32);
    final Uint8List sBytes = _bigIntToBytes(sig.S, 32);

    return Uint8List.fromList(<int>[...rBytes, ...sBytes]);
  }

  /// Converts a DER-encoded ECDSA signature to compact format (64 bytes).
  /// Handles ASN.1 encoded integers of arbitrary size by
  /// normalizing to 32 bytes each.
  @override
  Uint8List signatureFromDER(final Uint8List signature) {
    final ECDSASignature ecdsaSignature = ECDSASignature.fromDER(signature);

    // ASN.1 encoded Integers are arbitrary sized, normalize to exactly
    // 32-byte buffers
    final List<Uint8List> sigSECValues = <Uint8List>[
      Uint8List.fromList(ecdsaSignature.r),
      Uint8List.fromList(ecdsaSignature.s),
    ];

    // Normalize each value to exactly 32 bytes
    for (int i = 0; i < sigSECValues.length; i++) {
      final Uint8List value = sigSECValues[i];

      if (value.length > 32) {
        // Truncate to the last 32 bytes (take suffix)
        sigSECValues[i] = Uint8List.fromList(value.sublist(value.length - 32));
      } else if (value.length < 32) {
        // Pad with zeros at the beginning
        final Uint8List padding = Uint8List(32 - value.length);
        sigSECValues[i] = Uint8List.fromList(<int>[...padding, ...value]);
      }
    }

    // Combine both values into a 64-byte array (r || s)
    final Uint8List sigSEC = Uint8List.fromList(<int>[
      ...sigSECValues[0],
      ...sigSECValues[1],
    ]);

    if (sigSEC.length != 64) {
      throw CustomException.invalidDERSignature;
    }

    return sigSEC;
  }

  /// Verifies an ECDSA signature against the provided data and public key.
  /// If the data is not already a 32-byte digest, it's hashed with SHA3-256.
  /// Handles both uncompressed and compressed public key formats.
  @override
  bool verify({
    required final Uint8List data,
    required final Uint8List signature,
    required final Uint8List key,
  }) {
    try {
      if (signature.length != 64) {
        return false;
      }
      PublicKey publicKey;
      final String keyHex = hex.encode(key);
      try {
        publicKey = PublicKey.fromHex(keyHex);
      } catch (_) {
        // Fallback for compressed keys if required by library
        publicKey = PublicKey.fromCompressedHex(keyHex);
      }
      // If input isn't a 32-byte digest, hash it with SHA3-256
      final Uint8List digest = data.length == Hash.digestLength
          ? data
          : SHA3Digest(256).process(data);
      final String hashHex = hex.encode(digest);

      // Parse signature from compact representation (64 bytes: r || s)
      final BigInt r = _bytesToBigInt(signature.sublist(0, 32));
      final BigInt s = _bytesToBigInt(signature.sublist(32, 64));
      final Signature sig = Signature(r, s);

      // Verify the signature against the hash
      return sig.verify(publicKey, hashHex);
    } catch (e) {
      return false;
    }
  }
}
