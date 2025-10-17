import 'dart:convert' as conv;
import 'dart:typed_data';

import 'package:convert/convert.dart';

extension HexStringToBytes on String {
  Uint8List toBytes() {
    final bool hasPrefix = startsWith('0x');
    final String cleaned = hasPrefix ? substring(2) : this;

    final RegExp hexRe = RegExp(r'^[0-9a-fA-F]+$');
    final bool isHex = cleaned.isNotEmpty && hexRe.hasMatch(cleaned);

    if (isHex) {
      if (cleaned.length % 2 != 0) {
        throw const FormatException(
          'Hex string has an odd number of characters',
        );
      }
      final List<int> bytes = hex.decode(cleaned);
      return hasPrefix
          ? Uint8List.fromList(<int>[0, ...bytes])
          : Uint8List.fromList(bytes);
    }

    // Fallback: treat as UTF-8 text
    return Uint8List.fromList(conv.utf8.encode(this));
  }
}
