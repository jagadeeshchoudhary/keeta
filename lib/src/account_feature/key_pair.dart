import 'dart:typed_data';

import 'package:keeta/src/utils/custom_exception.dart';
import 'package:keeta/src/utils/string_to_bytes.dart';
import 'package:meta/meta.dart';


@immutable
class KeyPair {
  const KeyPair({required this.publicKey, final String? privateKey})
    : _privateKey = privateKey;

  factory KeyPair.fromJson(final Map<String, dynamic> json) => KeyPair(
    publicKey: json['publicKey'] as String,
    privateKey: json['privateKey'] as String?,
  );
  final String publicKey;
  final String? _privateKey;

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
  int get hashCode =>
      publicKey.toLowerCase().hashCode ^
      (_privateKey?.toLowerCase().hashCode ?? 0);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'publicKey': publicKey,
    'privateKey': _privateKey,
  };

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

  bool verify(
    final Uint8List data,
    final Uint8List signature,
    final Verifiable using,
  ) {
    final Uint8List publicKeyBytes = publicKey.toBytes();
    return using.verify(data: data, signature: signature, key: publicKeyBytes);
  }
}

abstract interface class KeyCreateable {
  KeyPair create({required final String fromSeed});

  KeyPair keypair({required final String fromPrivateKey});
}

abstract interface class Signable {
  Uint8List sign({required final Uint8List data, required final Uint8List key});
}

abstract interface class Verifiable {
  bool verify({
    required final Uint8List data,
    required final Uint8List signature,
    required final Uint8List key,
  });

  Uint8List signatureFromDER(final Uint8List signature);
}
