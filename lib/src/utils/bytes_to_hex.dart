import 'dart:typed_data';

import 'package:convert/convert.dart';

extension UintListX on Uint8List {
  // ignore: unused_element
  String toHexString() => hex.encode(this);
}
