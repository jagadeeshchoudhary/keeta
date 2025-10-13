import 'dart:convert';
import 'dart:typed_data';

import 'package:keeta/src/account_feature/key_pair.dart';
import 'package:keeta/src/utils/custom_exception.dart';
import 'package:keeta/src/utils/string_to_bytes.dart';

class IdentifierKeyPair implements KeyUtils {
  @override
  KeyPair create({required final String fromSeed}) {
    final String privateKey = base64Encode(fromSeed.toBytes());
    return keypair(fromPrivateKey: privateKey);
  }

  @override
  KeyPair keypair({required final String fromPrivateKey}) =>
      KeyPair(publicKey: fromPrivateKey, privateKey: fromPrivateKey);

  @override
  Uint8List sign({
    required final Uint8List data,
    required final Uint8List key,
  }) {
    throw CustomException.signingNotSupported;
  }

  @override
  bool verify({
    required final Uint8List data,
    required final Uint8List signature,
    required final Uint8List key,
  }) {
    throw CustomException.verifyingNotSupported;
  }

  @override
  Uint8List signatureFromDER(final Uint8List signature) {
    throw CustomException.noPrivateKey;
  }
}
