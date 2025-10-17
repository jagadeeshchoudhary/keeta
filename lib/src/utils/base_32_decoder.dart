import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:keeta/src/utils/custom_exception.dart';

mixin Base32Decoder {
  static Uint8List decode({
    required final String value,
    required final int length,
  }) {
    Uint8List? result;

    try {
      // Normalize to RFC4648: uppercase and pad to multiple of 8 with '='
      String normalized = value.toUpperCase();
      final int rem = normalized.length % 8;
      if (rem != 0) {
        normalized = normalized + '=' * (8 - rem);
      }

      result = base32.decode(normalized);
    } catch (_) {
      throw CustomException.invalidInput;
    }

    if (result.length != length) {
      throw CustomException.invalidLength;
    }

    return result;
  }
}
