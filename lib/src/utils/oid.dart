enum OID {
  ecdsaWithSHA512('1.2.840.10045.4.3.4'),
  ecdsaWithSHA3_256('2.16.840.1.101.3.4.3.10'),
  ed25519('1.3.6.1.4.1.11591.15.1'),

  // X.500 attributes
  commonName('2.5.4.3'),
  serialNumber('2.5.4.5'),
  countryName('2.5.4.6'),
  localityName('2.5.4.7'),
  stateOrProvinceName('2.5.4.8'),
  streetAddress('2.5.4.9'),
  organizationName('2.5.4.10'),
  organizationalUnitName('2.5.4.11'),
  businessCategory('2.5.4.15'),
  postalCode('2.5.4.17'),
  dnQualifier('2.5.4.46'),

  hashData('2.16.840.1.101.3.3.1.3'),
  sha3_256('2.16.840.1.101.3.4.2.8'),
  domainComponent('0.9.2342.19200300.100.1.25'),
  emailAddress('1.2.840.113549.1.9.1'),
  userId('0.9.2342.19200300.100.1.1'),

  fees('1.3.6.1.4.1.62675.0.1.0');

  const OID(this.value);
  final String value;

  static OID fromValue(final String value) => OID.values.firstWhere(
    (final OID e) => e.value == value,
    orElse: () => throw ArgumentError('Invalid OID: $value'),
  );
}
