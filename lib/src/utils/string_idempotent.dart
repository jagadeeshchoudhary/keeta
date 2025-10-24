import 'dart:convert';
import 'dart:typed_data';

import 'package:keeta/src/utils/custom_exception.dart';

extension IdempotentString on String {
  /// Converts the string to its Base64 representation using UTF-8 encoding.
  /// Throws [CustomException] if the string cannot be encoded.
  String idempotent() {
    try {
      final Uint8List bytes = utf8.encode(this);
      return base64Encode(bytes);
    } catch (_) {
      throw CustomException.invalidString;
    }
  }
}
