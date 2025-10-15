import 'dart:typed_data';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/account_feature/key_algorithm.dart';
import 'package:keeta/src/account_feature/key_pair.dart';
import 'package:keeta/src/utils/remove_prefix.dart';
import 'package:keeta/src/utils/utils.dart';

mixin AccountBuilder {
  static Account createFromSeed({
    required final String seed,
    required final int index,
    final KeyAlgorithm algorithm = KeyAlgorithm.ecdsaSecp256k1,
  }) {
    final String seedBase = combine(seed: seed, index: index);
    final KeyPair keyPair = algorithm.utils.create(fromSeed: seedBase);
    return Account(keyPair: keyPair, keyAlgorithm: algorithm);
  }

  /// Create account from public key string
  static Account createFromPublicKey({required final String publicKey}) {
    String key = publicKey;
    bool prefixMatched = false;

    // Remove acceptable prefixes
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

    // Verify key length
    final int? pubKeySize = Account.publicKeyLengths[key.length];
    if (pubKeySize == null) {
      throw CustomException.invalidPublicKeyLength(key.length);
    }

    // Decode Base32
    final Uint8List pubKeyValues = Base32Decoder.decode(
      value: key,
      length: pubKeySize,
    );
    final Uint8List checksumOf = pubKeyValues.sublist(
      0,
      pubKeyValues.length - Account.checksumLength,
    );
    final String checksum = pubKeyValues
        .sublist(pubKeyValues.length - Account.checksumLength)
        .toHexString();
    final Uint8List checksumCheckBytes = Hash.createData(
      fromData: checksumOf,
      length: Account.checksumLength,
    );
    final String checksumCheck = checksumCheckBytes.toHexString();

    if (checksum != checksumCheck) {
      throw CustomException.invalidPublicKeyChecksum;
    }

    // Parse key type and actual key
    final String pubKey = pubKeyValues
        .sublist(1, pubKeyValues.length - Account.checksumLength)
        .toHexString();
    final int keyType = pubKeyValues[0];

    final KeyAlgorithm algo = KeyAlgorithm.fromInt(keyType);

    return Account(
      keyPair: KeyPair(publicKey: pubKey),
      keyAlgorithm: algo,
    );
  }

  /// Create account from private key
  static Account createFromPrivateKey(
    final String privateKey,
    final KeyAlgorithm algorithm,
  ) {
    final KeyPair keyPair = algorithm.utils.keypair(fromPrivateKey: privateKey);
    return Account(keyPair: keyPair, keyAlgorithm: algorithm);
  }

  /// Internal — combine seed + index
  static String combine({
    required final String seed,
    required final int index,
  }) {
    if (index < 0) {
      throw CustomException.seedIndexNegative;
    }

    final BigInt indexValue = BigInt.from(index);

    // Ensure index fits in 32 bits
    if (indexValue >> 32 != BigInt.zero) {
      throw CustomException.seedIndexTooLarge;
    }

    final Uint8List seedBytes = seed.toBytes()
      ..addAll(<int>[
        (indexValue >> 24 & BigInt.from(0xff)).toInt(),
        (indexValue >> 16 & BigInt.from(0xff)).toInt(),
        (indexValue >> 8 & BigInt.from(0xff)).toInt(),
        (indexValue & BigInt.from(0xff)).toInt(),
      ]);

    return seedBytes.toHexString().toUpperCase();
  }
}
