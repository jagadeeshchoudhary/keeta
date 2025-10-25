import 'dart:convert';
import 'dart:typed_data';

// Encoding
extension EncodableBtoa on Object {
  String btoa() {
    final String jsonString = jsonEncode(this);
    return jsonString.btoa();
  }
}

extension StringBtoa on String {
  String btoa() {
    if (isEmpty) {
      return this;
    }
    final Uint8List latin1Bytes = latin1.encode(this);
    return base64.encode(latin1Bytes);
  }
}

// Decoding
extension DecodableBtoa<T> on Type {
  static T create<T>(
    final String btoa,
    final T Function(Map<String, dynamic>) fromJson,
  ) {
    final Uint8List decodedBytes = base64.decode(btoa);
    final Uint8List jsonBytes = decodedBytes.btoa();
    final String jsonString = utf8.decode(jsonBytes);
    final Map<String, dynamic> jsonMap =
        jsonDecode(jsonString) as Map<String, dynamic>;
    return fromJson(jsonMap);
  }
}

extension Uint8ListBtoa on Uint8List {
  Uint8List btoa() {
    final String latin1String = latin1.decode(this);
    final Uint8List utf8Bytes = utf8.encode(latin1String);
    return utf8Bytes;
  }
}
