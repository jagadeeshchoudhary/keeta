import 'dart:typed_data';

import 'package:base32/base32.dart';

mixin Base32Encoder {
  static String encode({required final Uint8List bytes}) {
    final String encoded = base32.encode(bytes);

    int length = encoded.length;
    while (length > 0 && encoded[length - 1] == '=') {
      length--;
    }

    return encoded.substring(0, length).toLowerCase();
  }
}
