import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:keeta/src/account_feature/key_pair.dart';
import 'package:keeta/src/utils/hash.dart';
import 'package:keeta/src/utils/string_to_bytes.dart';

/// Ed25519 elliptic curve digital signature algorithm implementation.
/// Provides deterministic key generation, signing, and verification using
/// the Ed25519 curve with proper seed clamping as per RFC 8032.
class Ed25519 implements KeyUtils {
  /// Creates a KeyPair from a seed using SHA3-256 for key derivation.
  /// The seed is hashed to produce a 32-byte Ed25519 seed.
  @override
  KeyPair create({required final String fromSeed}) {
    // Derive Ed25519 private key as SHA3-256 of combined seed+index
    final String privateKey = Hash.create(fromBytes: fromSeed.toBytes());
    return keypair(fromPrivateKey: privateKey);
  }

  /// Creates a KeyPair from a 32-byte private key with proper Ed25519 clamping.
  /// Private key is clamped according to RFC 8032 & used to derive public key.
  @override
  KeyPair keypair({required final String fromPrivateKey}) {
    // Convert 32-byte private key (seed) from hex to bytes
    final Uint8List seedBytes = fromPrivateKey.toBytes();

    // Clamp the seed according to Ed25519 specification (RFC 8032)
    // Clear the lowest 3 bits of the first byte
    seedBytes[0] &= 248;
    // Clear the highest bit of the last byte
    seedBytes[31] &= 127;
    // Set the second highest bit of the last byte
    seedBytes[31] |= 64;

    // Derive keypair from clamped seed per Ed25519 spec
    final ed.PrivateKey sk = ed.newKeyFromSeed(seedBytes);
    final ed.PublicKey pk = ed.public(sk);
    final Uint8List publicKeyBytes = Uint8List.fromList(pk.bytes);

    // Return both keys as uppercase hex strings
    final String publicKeyHex = hex.encode(publicKeyBytes).toUpperCase();
    final String clampedPrivateHex = hex.encode(seedBytes).toUpperCase();
    return KeyPair(publicKey: publicKeyHex, privateKey: clampedPrivateHex);
  }

  /// Signs data using the provided private key with Ed25519.
  /// The private key is clamped before use to ensure proper Ed25519 behavior.
  @override
  Uint8List sign({
    required final Uint8List data,
    required final Uint8List key,
  }) {
    // Clamp the provided 32-byte seed according to Ed25519 spec
    final Uint8List seed = Uint8List.fromList(key);
    seed[0] &= 248;
    seed[31] &= 127;
    seed[31] |= 64;
    final ed.PrivateKey sk = ed.newKeyFromSeed(seed);
    return ed.sign(sk, data);
  }

  /// Verifies an Ed25519 signature against the provided data and public key.
  @override
  bool verify({
    required final Uint8List data,
    required final Uint8List signature,
    required final Uint8List key,
  }) => ed.verify(ed.PublicKey(key), data, signature);

  /// signatures are already in correct format, no DER conversion needed.
  @override
  Uint8List signatureFromDER(final Uint8List signature) => signature;
}
