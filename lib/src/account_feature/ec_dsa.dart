import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:keeta/src/account_feature/ec_dsa_signature.dart';
import 'package:keeta/src/account_feature/key_pair.dart';
import 'package:keeta/src/utils/custom_exception.dart';
import 'package:keeta/src/utils/hash.dart';
import 'package:keeta/src/utils/string_to_bytes.dart';
import 'package:pointycastle/digests/sha3.dart';
import 'package:secp256k1/secp256k1.dart';

class EcDSA implements KeyCreateable, Signable, Verifiable {
  /// Converts bytes to BigInt
  static BigInt _bytesToBigInt(final Uint8List bytes) => BigInt.parse(
    bytes.map((final int b) => b.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );

  /// Converts BigInt to bytes with specified length
  static Uint8List _bigIntToBytes(final BigInt value, final int length) {
    final String hex = value.toRadixString(16).padLeft(length * 2, '0');
    return Uint8List.fromList(
      List<int>.generate(
        length,
        (final int i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }

  @override
  KeyPair create({required final String fromSeed}) {
    final String privateKey = Hash.hkdf(fromSeed.toBytes());
    return keypair(fromPrivateKey: privateKey);
  }

  @override
  KeyPair keypair({required final String fromPrivateKey}) {
    final Uint8List privateBytes = fromPrivateKey.toBytes();
    final PrivateKey keyResult = PrivateKey.fromHex(hex.encode(privateBytes));
    final String publicKey = keyResult.publicKey
        .toCompressedHex()
        .toUpperCase();

    return KeyPair(publicKey: publicKey, privateKey: fromPrivateKey);
  }

  @override
  Uint8List sign({
    required final Uint8List data,
    required final Uint8List key,
  }) {
    final PrivateKey privateKey = PrivateKey.fromHex(hex.encode(key));

    final SHA3Digest digest = SHA3Digest(256);
    final Uint8List hash = digest.process(data);
    final String hashHex = hex.encode(hash);

    final Signature sig = privateKey.signature(hashHex);

    // Return compact representation (64 bytes)
    // Convert r and s to 32-byte arrays
    final Uint8List rBytes = _bigIntToBytes(sig.R, 32);
    final Uint8List sBytes = _bigIntToBytes(sig.S, 32);

    return Uint8List.fromList(<int>[...rBytes, ...sBytes]);
  }

  @override
  Uint8List signatureFromDER(final Uint8List signature) {
    final ECDSASignature ecdsaSignature = ECDSASignature.fromDER(signature);

    // ASN.1 encoded Integers are arbitrary sized, forces exactly 32-byte buffer
    final List<Uint8List> sigSECValues = <Uint8List>[
      Uint8List.fromList(ecdsaSignature.r),
      Uint8List.fromList(ecdsaSignature.s),
    ];

    // Normalize each value to exactly 32 bytes
    for (int i = 0; i < sigSECValues.length; i++) {
      final Uint8List value = sigSECValues[i];

      if (value.length > 32) {
        // Truncate to the last 32 bytes - matches value.suffix(32)
        sigSECValues[i] = Uint8List.fromList(value.sublist(value.length - 32));
      } else if (value.length < 32) {
        // Pad with zeros at the beginning
        final Uint8List padding = Uint8List(32 - value.length);
        sigSECValues[i] = Uint8List.fromList(<int>[...padding, ...value]);
      }
    }

    // Combine both values into a 64-byte array
    final Uint8List sigSEC = Uint8List.fromList(<int>[
      ...sigSECValues[0],
      ...sigSECValues[1],
    ]);

    if (sigSEC.length != 64) {
      throw CustomException.invalidDERSignature;
    }

    return sigSEC;
  }

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
      final PublicKey publicKey = PublicKey.fromHex(hex.encode(key));
      final SHA3Digest digest = SHA3Digest(256);
      final Uint8List hash = digest.process(data);
      final String hashHex = hex.encode(hash);

      // Parse signature from compact representation (64 bytes: r + s)
      final BigInt r = _bytesToBigInt(signature.sublist(0, 32));
      final BigInt s = _bytesToBigInt(signature.sublist(32, 64));
      final Signature sig = Signature(r, s);

      // Verify - matches publicKey.isValidSignature(signature, for:)
      return sig.verify(publicKey, hashHex);
    } catch (e) {
      return false;
    }
  }
}
