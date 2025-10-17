import 'dart:typed_data';
import 'package:keeta/src/account_feature/account_builder.dart';
import 'package:keeta/src/account_feature/key_algorithm.dart';
import 'package:keeta/src/account_feature/key_pair.dart';
import 'package:keeta/src/account_feature/signing_options.dart';
import 'package:keeta/src/block_feature/block.dart';
import 'package:keeta/src/utils/utils.dart';
import 'package:meta/meta.dart';

@immutable
class Account {
  /// Constructor: Account(keyPair: KeyPair, keyAlgorithm: KeyAlgorithm)
  factory Account({
    required final KeyPair keyPair,
    required final KeyAlgorithm keyAlgorithm,
  }) {
    final String publicKeyString = Account.fromPublicKeyString(
      fromPublicKey: keyPair.publicKey,
      algorithm: keyAlgorithm,
    );

    final Uint8List publicKeyAndType = Account.publicKeyAndTypeToByte(
      fromPublicKey: keyPair.publicKey,
      algorithm: keyAlgorithm,
    );

    return Account._(
      keyPair: keyPair,
      publicKeyString: publicKeyString,
      publicKeyAndType: publicKeyAndType,
      keyAlgorithm: keyAlgorithm,
    );
  }

  /// Constructor: Account(data: Data)
  factory Account.fromData(final Uint8List data) {
    final String publicKey = Account.publicKeyStringFromBytes(data);
    return AccountBuilder.createFromPublicKey(publicKey: publicKey);
  }

  /// Constructor: Account(publicKeyAndType: PublicKeyAndType)
  factory Account.fromPublicKeyAndType(final Uint8List publicKeyAndType) =>
      Account.fromData(publicKeyAndType);

  const Account._({
    required this.keyPair,
    required this.publicKeyString,
    required this.publicKeyAndType,
    required this.keyAlgorithm,
  });
  final KeyPair keyPair;
  final String publicKeyString;
  final Uint8List publicKeyAndType;
  final KeyAlgorithm keyAlgorithm;

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Account) {
      return false;
    }
    return keyAlgorithm == other.keyAlgorithm &&
        keyPair == other.keyPair &&
        publicKeyString == other.publicKeyString &&
        _listEquals(publicKeyAndType, other.publicKeyAndType);
  }

  @override
  int get hashCode => Object.hash(
    keyAlgorithm,
    keyPair,
    publicKeyString,
    _bytesHash(publicKeyAndType),
  );

  static bool _listEquals(final List<int> a, final List<int> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  static int _bytesHash(final List<int> bytes) {
    int hash = 0;
    for (final int b in bytes) {
      hash = 0x1fffffff & (hash + b);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }

  // Constants
  static const Map<int, int> publicKeyLengths = <int, int>{
    61: 32 + 5 + 1, // 32 bytes public key + 5 checksum + 1 type
    63: 33 + 5 + 1, // 33 bytes public key + 5 checksum + 1 type
  };

  static const List<String> accountPrefixes = <String>['keeta_'];
  static const int checksumLength = 5;

  /// Check if account can sign
  bool get canSign {
    if (!keyPair.hasPrivateKey) {
      return false;
    }

    // Not all key pair implementations support signing(e.g. IdentifierKeyPair)
    try {
      final KeyUtils _ = keyAlgorithm.utils;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if account is an identifier
  bool get isIdentifier =>
      keyAlgorithm == KeyAlgorithm.token ||
      keyAlgorithm == KeyAlgorithm.network;

  /// Sign data
  Uint8List sign({
    required final Uint8List data,
    final SigningOptions options = SigningOptions.defaults,
  }) {
    final Uint8List preparedData = _prepare(data: data, options: options);
    final KeyUtils utils = keyAlgorithm.utils;
    return keyPair.sign(data: preparedData, using: utils);
  }

  /// Verify signature
  bool verify({
    required final Uint8List data,
    required final Uint8List signature,
    final SigningOptions options = SigningOptions.defaults,
  }) {
    final Uint8List preparedData = _prepare(data: data, options: options);
    final KeyUtils verifier = keyAlgorithm.utils;

    // When handling X.509 certificates, we must process DER encoded data
    final Uint8List finalSignature = options.forCert
        ? verifier.signatureFromDER(signature)
        : signature;

    return keyPair.verify(
      data: preparedData,
      signature: finalSignature,
      using: verifier,
    );
  }

  /// Generate identifier account
  Account generateIdentifier({final KeyAlgorithm type = KeyAlgorithm.token}) {
    if (isIdentifier) {
      if (keyAlgorithm != KeyAlgorithm.network) {
        throw CustomException.invalidIdentifierAccount;
      }
      if (type != KeyAlgorithm.token) {
        throw CustomException.invalidIdentifierAlgorithm;
      }
    }

    final String accountOpeningHash = Block.accountOpeningHash(this);
    final Uint8List blockHash = accountOpeningHash.toBytes();

    final Uint8List combinedBytes = Uint8List.fromList(<int>[
      ...publicKeyAndType,
      ...blockHash,
    ]);

    final String seed = Hash.create(fromBytes: combinedBytes);

    return AccountBuilder.createFromSeed(seed: seed, index: 0, algorithm: type);
  }

  /// Prepare data for signing/verification
  Uint8List _prepare({
    required final Uint8List data,
    required final SigningOptions options,
  }) {
    if (options.raw) {
      if (data.length != Hash.digestLength) {
        throw CustomException.invalidDataLength;
      }
      return data;
    } else {
      return Hash.createData(fromData: data);
    }
  }

  // Static helper methods

  /// Get publicKeyAndType from public key string and algorithm
  static Uint8List publicKeyAndTypeToByte({
    required final String fromPublicKey,
    required final KeyAlgorithm algorithm,
  }) =>
      Uint8List.fromList(<int>[algorithm.rawValue, ...fromPublicKey.toBytes()]);

  /// Get public key string from public key and algorithm
  static String fromPublicKeyString({
    required final String fromPublicKey,
    required final KeyAlgorithm algorithm,
  }) {
    // Construct the array of public key bytes
    final Uint8List keyBytes = fromPublicKey.toBytes();
    final List<int> pubKeyValues = <int>[algorithm.rawValue, ...keyBytes];
    fromPublicKey.toBytes();

    return publicKeyStringFromBytes(Uint8List.fromList(pubKeyValues));
  }

  /// Get public key string from key bytes
  static String publicKeyStringFromBytes(final Uint8List keyBytes) {
    // Append the checksum
    final Uint8List checksumBytes = Hash.createData(
      fromData: keyBytes,
      length: checksumLength,
    );
    final Uint8List extendedKeyBytes = Uint8List.fromList(<int>[
      ...keyBytes,
      ...checksumBytes,
    ]);

    // Ensure we have the right size
    if (!publicKeyLengths.values.any(
      (final int length) => extendedKeyBytes.length == length,
    )) {
      throw CustomException.invalidPublicKeyLength(extendedKeyBytes.length);
    }

    final String accountPrefix = accountPrefixes[0];
    final String output = Base32Encoder.encode(bytes: extendedKeyBytes);

    return '$accountPrefix$output';
  }
}
