import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart';

mixin Hash {
  // SHA3-256 digest length is 32 bytes
  static int get digestLength => 32;

  // OID for SHA3-256
  static const String oid = '2.16.840.1.101.3.4.2.8'; // SHA3-256 OID

  /// Creates SHA3-256 hash instance
  static SHA3Digest _sha3_256() => SHA3Digest(256);

  /// Creates hash from bytes and returns hex string
  static String create({
    required final Uint8List fromBytes,
    final int? length,
  }) {
    final Uint8List hashBytes = _createBytes(from: fromBytes, length: length);
    return hex.encode(hashBytes).toUpperCase();
  }

  /// Creates hash from bytes and returns Uint8List
  static Uint8List createData({
    required final Uint8List fromData,
    final int? length,
  }) => _createBytes(from: fromData, length: length);

  /// Internal method to create hash bytes
  static Uint8List _createBytes({
    required final Uint8List from,
    final int? length,
  }) {
    final SHA3Digest digest = _sha3_256();
    final Uint8List hashBytes = digest.process(from);

    if (length != null) {
      return Uint8List.fromList(hashBytes.sublist(0, length));
    }
    return Uint8List.fromList(hashBytes);
  }

  /// HKDF (HMAC-based Key Derivation Function) using SHA3-256
  static String hkdf(
    final Uint8List prk, {
    final int length = 32,
    final Uint8List? info,
  }) {
    final Uint8List infoBytes = info ?? Uint8List(0);
    final int numBlocks = (length / digestLength).ceil();
    // SHA3-256 has a block size of 136 bytes (1088 bits)
    final HMac hmac = HMac(_sha3_256(), 136)..init(KeyParameter(prk));

    final List<int> ret = List<int>.filled(numBlocks * digestLength, 0);

    int offset = 0;
    List<int> value = <int>[];

    for (int i = 1; i <= numBlocks; i++) {
      value
        ..addAll(infoBytes)
        ..add(i);

      final Uint8List input = Uint8List.fromList(value);
      final Uint8List output = Uint8List(hmac.macSize);

      hmac
        ..reset()
        ..update(input, 0, input.length)
        ..doFinal(output, 0);

      ret.setRange(offset, offset + output.length, output);
      offset += output.length;
      value = output.toList();
    }

    return hex.encode(ret).toUpperCase();
  }
}
