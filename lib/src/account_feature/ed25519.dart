import 'dart:convert';
import 'dart:typed_data';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:keeta/src/account_feature/key_pair.dart';
import 'package:keeta/src/utils/hash.dart';
import 'package:keeta/src/utils/string_to_bytes.dart';

class Ed25519 implements KeyUtils {
  @override
  KeyPair create({required final String fromSeed}) {
    final String privateKey = Hash.create(fromBytes: fromSeed.toBytes());
    return keypair(fromPrivateKey: privateKey);
  }

  @override
  KeyPair keypair({required final String fromPrivateKey}) {
    final Uint8List privateKeyBytes = fromPrivateKey.toBytes();
    privateKeyBytes[0] &= 248;
    privateKeyBytes[31] &= 127;
    privateKeyBytes[31] |= 64;

    final String privateKey = base64Encode(privateKeyBytes);
    final List<int> publicKeyBytes = ed
        .public(ed.PrivateKey(privateKeyBytes))
        .bytes;
    final String publicKey = base64Encode(publicKeyBytes);

    return KeyPair(publicKey: publicKey, privateKey: privateKey);
  }

  @override
  Uint8List sign({
    required final Uint8List data,
    required final Uint8List key,
  }) => ed.sign(ed.PrivateKey(key), data);

  @override
  bool verify({
    required final Uint8List data,
    required final Uint8List signature,
    required final Uint8List key,
  }) => ed.verify(ed.PublicKey(key), data, signature);

  @override
  Uint8List signatureFromDER(final Uint8List signature) => signature;
}
