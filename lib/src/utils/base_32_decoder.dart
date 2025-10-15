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
      result = base32.decode(value);
    } catch (_) {
      throw CustomException.invalidInput;
    }

    if (result.length != length) {
      throw CustomException.invalidLength;
    }

    return result;
  }
}
