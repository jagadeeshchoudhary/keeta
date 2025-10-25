import 'dart:io';
import 'dart:typed_data';

/// Compresses the given [data] using ZLIB (Deflate) with a standard
/// 2-byte zlib header (0x78, 0x9C)
Uint8List compress(final Uint8List data) {
  // Deflate codec (zlib)
  final ZLibCodec zlibCodec = ZLibCodec();

  // Compress
  final List<int> compressedBody = zlibCodec.encode(data);

  // Ensure 0x78 0x9C header (as in Swift)
  final Uint8List header = Uint8List.fromList(<int>[0x78, 0x9C]);

  // Combine header + compressed body
  return Uint8List.fromList(<int>[...header, ...compressedBody]);
}

/// Decompresses data compressed by [compress], dropping the
/// first 2 bytes (zlib header)
Uint8List decompress(final Uint8List data) {
  // Drop the first 2 bytes (0x78, 0x9C)
  final Uint8List body = data.sublist(2);

  // Decode (inflate)
  final ZLibCodec zlibCodec = ZLibCodec();
  return Uint8List.fromList(zlibCodec.decode(body));
}
