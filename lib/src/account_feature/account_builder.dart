import 'dart:typed_data';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/account_feature/key_algorithm.dart';
import 'package:keeta/src/account_feature/key_pair.dart';
import 'package:keeta/src/utils/remove_prefix.dart';
import 'package:keeta/src/utils/utils.dart';

/// Factory mixin for creating Account instances from various sources.
/// Handles seed-based derivation, public key parsing, and private key recovery.
mixin AccountBuilder {
  /// Creates an Account from a seed and index using the specified algorithm.
  /// The seed is combined with the index and then processed by the algorithm's
  /// key derivation function to produce a deterministic keypair.
  static Account createFromSeed({
    required final String seed,
    required final int index,
    final KeyAlgorithm algorithm = KeyAlgorithm.ecdsaSecp256k1,
  }) {
    // Combine seed with index to create a unique derivation input
    final String seedBase = combine(seed: seed, index: index);
    // Use algorithm-specific key derivation to create the keypair
    final KeyPair keyPair = algorithm.utils.create(fromSeed: seedBase);
    return Account(keyPair: keyPair, keyAlgorithm: algorithm);
  }

  /// Creates an Account from a public key string (e.g., "keeta_...").
  /// Validates format, checksum, & algorithm type before creating the account.
  static Account createFromPublicKey({required final String publicKey}) {
    String key = publicKey;
    bool prefixMatched = false;

    // Strip the "keeta_" prefix if present
    for (final String prefix in Account.accountPrefixes) {
      final String? updated = key.removePrefix(prefix);
      if (updated != null) {
        key = updated;
        prefixMatched = true;
        break;
      }
    }

    if (!prefixMatched) {
      throw CustomException.invalidPublicKeyPrefix;
    }

    // Validate the Base32-encoded key length matches expected sizes
    final int? pubKeySize = Account.publicKeyLengths[key.length];
    if (pubKeySize == null) {
      throw CustomException.invalidPublicKeyLength(key.length);
    }

    // Decode the Base32-encoded key data
    final Uint8List pubKeyValues = Base32Decoder.decode(
      value: key,
      length: pubKeySize,
    );
    // Extract the payload (without checksum) for verification
    final Uint8List checksumOf = pubKeyValues.sublist(
      0,
      pubKeyValues.length - Account.checksumLength,
    );
    // Extract the embedded checksum
    final String checksum = pubKeyValues
        .sublist(pubKeyValues.length - Account.checksumLength)
        .toHexString();
    // Recompute the expected checksum
    final Uint8List checksumCheckBytes = Hash.createData(
      fromData: checksumOf,
      length: Account.checksumLength,
    );
    final String checksumCheck = checksumCheckBytes.toHexString();

    // Verify the checksum matches to ensure data integrity
    if (checksum != checksumCheck) {
      throw CustomException.invalidPublicKeyChecksum;
    }

    // Extract the algorithm type (first byte) and the actual public key
    final String pubKey = pubKeyValues
        .sublist(1, pubKeyValues.length - Account.checksumLength)
        .toHexString();
    final int keyType = pubKeyValues[0];

    // Map the algorithm type to the corresponding enum
    final KeyAlgorithm algo = KeyAlgorithm.fromInt(keyType);

    return Account(
      keyPair: KeyPair(publicKey: pubKey),
      keyAlgorithm: algo,
    );
  }

  /// Creates an Account from a private key using the specified algorithm.
  /// The private key is used to derive the corresponding public key.
  static Account createFromPrivateKey({
    required final String privateKey,
    required final KeyAlgorithm algorithm,
  }) {
    final KeyPair keyPair = algorithm.utils.keypair(fromPrivateKey: privateKey);
    return Account(keyPair: keyPair, keyAlgorithm: algorithm);
  }

  /// Combines a seed with an index to create a unique derivation input.
  /// The index is appended as a 4-byte big-endian integer to the seed bytes.
  /// Ensures deterministic but unique key derivation for different indices.
  static String combine({
    required final String seed,
    required final int index,
  }) {
    // Validate index is non-negative
    if (index < 0) {
      throw CustomException.seedIndexNegative;
    }

    final BigInt indexValue = BigInt.from(index);

    // Ensure index fits within 32 bits to prevent overflow
    if (indexValue >> 32 != BigInt.zero) {
      throw CustomException.seedIndexTooLarge;
    }

    // Combine seed bytes with 4-byte big-endian index
    final Uint8List seedBytes = Uint8List.fromList(<int>[
      ...seed.toBytes(),

      // Extract bytes from index in big-endian order
      (indexValue >> 24 & BigInt.from(0xff)).toInt(),
      (indexValue >> 16 & BigInt.from(0xff)).toInt(),
      (indexValue >> 8 & BigInt.from(0xff)).toInt(),
      (indexValue & BigInt.from(0xff)).toInt(),
    ]);

    // Return as uppercase hex string for consistency
    return seedBytes.toHexString().toUpperCase();
  }
}
