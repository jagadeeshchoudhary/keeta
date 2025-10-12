class SigningOptions {

  const SigningOptions({
    required this.raw,
    required this.forCert,
  });
  final bool raw;
  final bool forCert;

  static const SigningOptions defaults = SigningOptions(
    raw: false,
    forCert: false,
  );
}
