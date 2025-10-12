import 'dart:typed_data';

import 'package:convert/convert.dart';

extension HexStringToBytes on String {
  Uint8List toBytes() {
    final bool hasPrefix = startsWith('0x');
    final String cleanedHex = hasPrefix ? substring(2) : this;

    if (cleanedHex.length % 2 != 0) {
      throw const FormatException('Hex string has an odd number of characters');
    }

    final List<int> bytes = hex.decode(cleanedHex);

    return hasPrefix
        ? Uint8List.fromList(<int>[0, ...bytes])
        : Uint8List.fromList(bytes);
  }
}
