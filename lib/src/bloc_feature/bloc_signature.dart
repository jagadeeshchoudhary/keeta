import 'dart:typed_data';
import 'package:convert/convert.dart';

/// Represents a block signature which can be either single or multi-signature.
sealed class BlockSignature {
  const BlockSignature();

  /// Factory constructors
  factory BlockSignature.single(final Uint8List signature) = SingleSignature;
  factory BlockSignature.multi(final List<Uint8List> signatures) =
      MultiSignature;

  /// Converts the signature to a hex string representation.
  String toHexString();
}

/// Represents a single signature.
class SingleSignature extends BlockSignature {
  const SingleSignature(this.signature);
  final Uint8List signature;

  @override
  String toHexString() => hex.encode(signature);
}

/// Represents multiple signatures (not implemented yet).
class MultiSignature extends BlockSignature {
  const MultiSignature(this.signatures);
  final List<Uint8List> signatures;

  @override
  String toHexString() => 'Multi-signatures not implemented';
}
