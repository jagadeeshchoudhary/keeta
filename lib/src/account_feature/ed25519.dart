import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:keeta/src/account_feature/key_pair.dart';
import 'package:keeta/src/utils/hash.dart';
import 'package:keeta/src/utils/string_to_bytes.dart';

class Ed25519 implements KeyUtils {
  @override
  KeyPair create({required final String fromSeed}) {
    // Derive Ed25519 private key as SHA3-256 of combined seed+index
    final String privateKey = Hash.create(fromBytes: fromSeed.toBytes());
    return keypair(fromPrivateKey: privateKey);
  }

  @override
  KeyPair keypair({required final String fromPrivateKey}) {
    // Convert 32-byte private key (seed) from hex to bytes
    final Uint8List seedBytes = fromPrivateKey.toBytes();

    // Clamp the seed (matches Swift reference implementation)
    seedBytes[0] &= 248;
    seedBytes[31] &= 127;
    seedBytes[31] |= 64;

    // Derive keypair from clamped seed per Ed25519 spec
    final ed.PrivateKey sk = ed.newKeyFromSeed(seedBytes);
    final ed.PublicKey pk = ed.public(sk);
    final Uint8List publicKeyBytes = Uint8List.fromList(pk.bytes);

    final String publicKeyHex = hex.encode(publicKeyBytes).toUpperCase();
    final String clampedPrivateHex = hex.encode(seedBytes).toUpperCase();
    return KeyPair(publicKey: publicKeyHex, privateKey: clampedPrivateHex);
  }

  @override
  Uint8List sign({
    required final Uint8List data,
    required final Uint8List key,
  }) {
    // Clamp provided 32-byte seed then sign
    final Uint8List seed = Uint8List.fromList(key);
    seed[0] &= 248;
    seed[31] &= 127;
    seed[31] |= 64;
    final ed.PrivateKey sk = ed.newKeyFromSeed(seed);
    return ed.sign(sk, data);
  }

  @override
  bool verify({
    required final Uint8List data,
    required final Uint8List signature,
    required final Uint8List key,
  }) => ed.verify(ed.PublicKey(key), data, signature);

  @override
  Uint8List signatureFromDER(final Uint8List signature) => signature;
}
