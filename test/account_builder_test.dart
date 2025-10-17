import 'dart:typed_data';

import 'package:keeta/keeta.dart';
import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/account_feature/account_builder.dart';
import 'package:keeta/src/utils/utils.dart';
import 'package:test/test.dart';

class PublicAccountConfig {
  const PublicAccountConfig({
    required this.keyAlgorithm,
    required this.publicKey,
    required this.encodedPublicKey,
  });
  final KeyAlgorithm keyAlgorithm;
  final String publicKey;
  final String encodedPublicKey;
}

class AccountConfig {
  const AccountConfig({
    required this.seed,
    required this.index,
    required this.publicKey,
    required this.privateKey,
    required this.publicKeyString,
    required this.algorithm,
  });
  final String seed;
  final int index;
  final String publicKey;
  final String privateKey;
  final String publicKeyString;
  final KeyAlgorithm algorithm;
}

void main() {
  final List<PublicAccountConfig> publicAccounts = <PublicAccountConfig>[
    const PublicAccountConfig(
      keyAlgorithm: KeyAlgorithm.ecdsaSecp256k1,
      publicKey:
          '020F2115FA0C9A10680AEECB64AB2E0564AED1AF821A72BF987AABF87A1AD68251',
      encodedPublicKey:
          '''keeta_aaba6iiv7igjuediblxmwzflfycwjlwrv6bbu4v7tb5kx6d2dllieunedvq3cza''',
    ),
    const PublicAccountConfig(
      keyAlgorithm: KeyAlgorithm.ed25519,
      publicKey:
          '0F2115FA0C9A10680AEECB64AB2E0564AED1AF821A72BF987AABF87A1AD68251',
      encodedPublicKey:
          'keeta_aehscfp2bsnba2ak53fwjkzoavsk5unpqinhfp4ypkv7q6q222bfcko6njrbw',
    ),
    const PublicAccountConfig(
      keyAlgorithm: KeyAlgorithm.network,
      publicKey:
          '372D46C3ADA9F897C74D349BBFE0E450C798167C9F580F8DAF85DEF57E96C3EA',
      encodedPublicKey:
          'keeta_ai3s2rwdvwu7rf6hju2jxp7a4rimpgawpspvqd4nv6c555l6s3b6uj6cr5klc',
    ),
    const PublicAccountConfig(
      keyAlgorithm: KeyAlgorithm.token,
      publicKey:
          '724E371B944A48E95B91EE059B7CB7110E5866CA707915C287C49CAB9B774AF1',
      encodedPublicKey:
          'keeta_anze4ny3srfer2k3shxalg34w4iq4wdgzjyhsfocq7cjzk43o5fpc2igkuifg',
    ),
  ];

  final List<AccountConfig> accountConfigs = <AccountConfig>[
    const AccountConfig(
      seed: '2401D206735C20485347B9A622D94DE9B21F2F1450A77C42102237FA4077567D',
      index: 0,
      publicKey:
          '02157AB0EB13544F1583635CF8DB2ED31FE9D029206E160100392EC91288D653A8',
      privateKey:
          'EEE6ABBC24F7FBB5A7035ABF27D6C389E94E4FF06D1A8948FDA56B4DC2D05794',
      publicKeyString: '''
keeta_aabbk6vq5mjvityvqnrvz6g3f3jr72oqfeqg4fqbaa4s5sisrdlfhkfr5p7chey''',
      algorithm: KeyAlgorithm.ecdsaSecp256k1,
    ),
    const AccountConfig(
      seed: '2401D206735C20485347B9A622D94DE9B21F2F1450A77C42102237FA4077567D',
      index: 1,
      publicKey:
          '0246B9851DF9019A4F2B16B0367ADBE1D0C09E37F84163A6173479E44BE94DDC8E',
      privateKey:
          '6FF01C1B8092A715DF4231AD531CA1101FA941E49BD76EADE0DA047D5333E20E',
      publicKeyString: '''
keeta_aabenomfdx4qdgspfmllant23pq5bqe6g74ecy5gc42htzcl5fg5zdr55yndzra''',
      algorithm: KeyAlgorithm.ecdsaSecp256k1,
    ),
    const AccountConfig(
      seed: '2401D206735C20485347B9A622D94DE9B21F2F1450A77C42102237FA4077567D',
      index: 0,
      publicKey:
          'C4FE1EC7D784869E485827E9A1CB21553ECD70570818DD367B86ACA295BC49BB',
      privateKey:
          'F0FAAE6AF2A3B84296F5B3216B4A7CB30228FC4593AAA10317D16C6412C9F05F',
      publicKeyString:
          'keeta_ahcp4hwh26cinhsilat6tiolefkt5tlqk4ebrxjwpodkziuvxre3x3r2wf5l6',
      algorithm: KeyAlgorithm.ed25519,
    ),
    const AccountConfig(
      seed: '2401D206735C20485347B9A622D94DE9B21F2F1450A77C42102237FA4077567D',
      index: 1,
      publicKey:
          '8462D010DAE2934F29DD6DA88A58E80ACD2B1F69D81834F141FC25FA9CCDD2D9',
      privateKey:
          '6823B06E9A84281499ADDFF3719B7A530B8E8C9764629858C73DCA7844675346',
      publicKeyString:
          'keeta_agcgfuaq3lrjgtzj3vw2rcsy5afm2ky7nhmbqnhrih6cl6u4zxjntb2x72hc2',
      algorithm: KeyAlgorithm.ed25519,
    ),
  ];

  final List<({Object error, String key})>
  invalidPublicKeys = <({Object error, String key})>[
    (
      key:
          '''keeta_cqaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabibevehoy''',
      error: ArgumentError('Invalid key algorithm: 20'),
    ),
    (
      key:
          'keeta_aguijv77cohs3fks62isqa4ywdvwlyhfddwpq4pqnvl6lssoyug2k7vkqfwuk',
      error: CustomException.invalidPublicKeyChecksum,
    ),
    (
      key: 'keeta_aguijv77cohs3fks62isqa4ywdvwlyhfddwpq4pqnvl6lssoyug2k7vkqfwu',
      error: const CustomException.invalidPublicKeyLength(60),
    ),
    (
      key: '0xadkee277rhdznsvjpnejiaomlb23f4dsrr3hyohyg2v7fzjhmkdnfp2vic3ke',
      error: CustomException.invalidPublicKeyPrefix,
    ),
    (
      key:
          '''notkeeta_adkee277rhdznsvjpnejiaomlb23f4dsrr3hyohyg2v7fzjhmkdnfp2vic3ke''',
      error: CustomException.invalidPublicKeyPrefix,
    ),
    (
      key: 'A884D7FF138F2D9552F691280398B0EB65E0E518ECF871F06D57E5CA4EC50DA5',
      error: CustomException.invalidPublicKeyPrefix,
    ),
  ];

  final List<({CustomException error, int index})> invalidIndexes =
      <({CustomException error, int index})>[
        (index: -1, error: CustomException.seedIndexNegative),
        (index: 0x7FFFFFFFFFFFFFFF, error: CustomException.seedIndexTooLarge),
      ];

  group('AccountBuilder Tests', () {
    test('createAccountsFromSeed', () {
      for (final AccountConfig config in accountConfigs) {
        final Account account = AccountBuilder.createFromSeed(
          seed: config.seed,
          index: config.index,
          algorithm: config.algorithm,
        );

        final KeyPair expected = KeyPair(
          publicKey: config.publicKey,
          privateKey: config.privateKey,
        );

        expect(account.keyPair, equals(expected));
        expect(account.keyAlgorithm, equals(config.algorithm));
        expect(account.publicKeyString, equals(config.publicKeyString));
      }
    });

    test('tryToCreateAccountWithInvalidPublicKeys', () {
      for (final ({Object error, String key}) config in invalidPublicKeys) {
        expect(
          () => AccountBuilder.createFromPublicKey(publicKey: config.key),
          throwsA(
            predicate(
              (final Object? e) => e.runtimeType == config.error.runtimeType,
            ),
          ),
          reason: 'Public key should be invalid: ${config.key}',
        );
      }
    });

    test('createAccountFromPublicKeys', () {
      for (final PublicAccountConfig config in publicAccounts) {
        final Account account = AccountBuilder.createFromPublicKey(
          publicKey: config.encodedPublicKey,
        );

        expect(account.keyAlgorithm, equals(config.keyAlgorithm));
        expect(account.keyPair, equals(KeyPair(publicKey: config.publicKey)));
      }
    });

    test('createAccountsFromPrivateKeys', () {
      for (final AccountConfig config in accountConfigs) {
        final Account account = AccountBuilder.createFromPrivateKey(
          privateKey: config.privateKey,
          algorithm: config.algorithm,
        );

        expect(
          account.keyPair,
          equals(
            KeyPair(publicKey: config.publicKey, privateKey: config.privateKey),
          ),
        );
        expect(account.keyAlgorithm, equals(config.algorithm));
      }
    });

    test('tryToCreateAccountWithInvalidIndex', () {
      const String seed =
          '2401D206735C20485347B9A622D94DE9B21F2F1450A77C42102237FA4077567D';

      for (final ({CustomException error, int index}) config
          in invalidIndexes) {
        expect(
          () => AccountBuilder.createFromSeed(seed: seed, index: config.index),
          throwsA(isA<CustomException>()),
          reason: 'Index should be invalid: ${config.index}',
        );
      }
    });

    test('accountSignAndVerifyData', () {
      const String seed =
          '2401D206735C20485347B9A622D94DE9B21F2F1450A77C42102237FA4077567D';
      final Uint8List data = 'Some random test data'.toBytes();

      final List<KeyAlgorithm> accountAlgorithms = <KeyAlgorithm>[
        KeyAlgorithm.ecdsaSecp256k1,
        KeyAlgorithm.ed25519,
      ];

      for (int i = 0; i < accountAlgorithms.length; i++) {
        final KeyAlgorithm algorithm = accountAlgorithms[i];
        final Account account = AccountBuilder.createFromSeed(
          seed: seed,
          index: i,
          algorithm: algorithm,
        );

        // Generate a valid signature and validate it
        final Uint8List signature = account.sign(data: data);
        final bool valid = account.verify(data: data, signature: signature);

        expect(valid, isTrue, reason: 'Account Type: $algorithm');
        expect(signature, isNotEmpty);

        // Modify that signature and verify that it cannot be validated
        final Uint8List invalidSignature = Uint8List.fromList(signature);
        invalidSignature[1] = (invalidSignature[1] + 1) % 256;
        try {
          final bool invalid1 = account.verify(
            data: data,
            signature: invalidSignature,
          );
          expect(invalid1, isFalse, reason: 'Signature should be invalid.');
        } catch (_) {}

        // Modify the data and verify that the signature cannot be validated
        final Uint8List invalidData = Uint8List.fromList(data);
        invalidData[1] = (invalidData[1] + 1) % 256;
        final bool invalid2 = account.verify(
          data: invalidData,
          signature: signature,
        );
        expect(invalid2, isFalse);
      }
    });

    test('signAndVerificationWithPublicKeyAndOptions', () {
      const String privateKey =
          '50A44F48CF187E47483614BDA872E9405D36FE0DDF0ADA0FAE5982BDFBE9EF13';
      final List<KeyAlgorithm> accountAlgorithms = <KeyAlgorithm>[
        KeyAlgorithm.ecdsaSecp256k1,
        KeyAlgorithm.ed25519,
      ];
      final Uint8List data = 'Some random test data'.toBytes();

      for (final KeyAlgorithm algorithm in accountAlgorithms) {
        final Account account = AccountBuilder.createFromPrivateKey(
          privateKey: privateKey,
          algorithm: algorithm,
        );

        final Uint8List signature1 = account.sign(data: data);
        final bool verified1 = account.verify(
          data: data,
          signature: signature1,
        );
        expect(verified1, isTrue);

        final Uint8List hashedData = Hash.createData(fromData: data);
        final Uint8List signature2 = account.sign(
          data: hashedData,
          options: const SigningOptions(raw: true, forCert: false),
        );
        final bool verified2 = account.verify(
          data: hashedData,
          signature: signature2,
          options: const SigningOptions(raw: true, forCert: false),
        );
        expect(verified2, isTrue);

        const String encodedPublicKey = '''
keeta_aabm7moneqqjpaaee5vxjqoe5f2ay3dchgr2hysdfh4wg3ycylohabivswjyfci''';
        final Account accountFromPublic = AccountBuilder.createFromPublicKey(
          publicKey: encodedPublicKey,
        );

        final bool verified3 = accountFromPublic.verify(
          data: hashedData,
          signature: signature2,
        );
        expect(verified3, isFalse);

        expect(
          () => account.verify(
            data: data,
            signature: signature1,
            options: const SigningOptions(raw: true, forCert: false),
          ),
          throwsA(isA<CustomException>()),
          reason: "Unhashed data shouldn't be verifiable.",
        );
      }
    });

    test('accountVerifyNodeSignature_ECDSA', () {
      final Uint8List data = 'Some random test data'.toBytes();

      final Uint8List signature =
          '''C0879BE652D4292DDDC6A183711F99ED1E0293C824651F8374365375990A2E7B35E0F21D156346118E1932117482F7A9145075442FCC91C28946F65CCDAC04BE'''
              .toBytes();

      const String privateKey =
          '50A44F48CF187E47483614BDA872E9405D36FE0DDF0ADA0FAE5982BDFBE9EF13';
      final Account account = AccountBuilder.createFromPrivateKey(
        privateKey: privateKey,
        algorithm: KeyAlgorithm.ecdsaSecp256k1,
      );

      final bool verified = account.verify(data: data, signature: signature);
      expect(verified, isTrue);
    });

    test('accountVerifyOpenSSLCert', () {
      const String privateKey =
          '50A44F48CF187E47483614BDA872E9405D36FE0DDF0ADA0FAE5982BDFBE9EF13';
      final Account account = AccountBuilder.createFromPrivateKey(
        privateKey: privateKey,
        algorithm: KeyAlgorithm.ecdsaSecp256k1,
      );

      // "Some random test data"
      final List<int> data = <int>[
        83,
        111,
        109,
        101,
        32,
        114,
        97,
        110,
        100,
        111,
        109,
        32,
        116,
        101,
        115,
        116,
        32,
        100,
        97,
        116,
        97,
      ];

      // Generated from OpenSSL: openssl dgst -sha3-256 -sign test.key data.txt
      final List<int> signature = <int>[
        0x5C,
        0xDC,
        0x7C,
        0x59,
        0xE0,
        0x9C,
        0xDD,
        0x1A,
        0xE1,
        0xE5,
        0xC8,
        0xD5,
        0x21,
        0x1E,
        0xFA,
        0x09,
        0x25,
        0x31,
        0x92,
        0x42,
        0x50,
        0xE1,
        0x56,
        0x26,
        0x66,
        0x00,
        0xCB,
        0xDC,
        0x69,
        0xBF,
        0x9F,
        0xED,
        0x5C,
        0x28,
        0x5F,
        0x33,
        0x9E,
        0x17,
        0xDA,
        0xA2,
        0xFC,
        0xAC,
        0xED,
        0x7C,
        0xD3,
        0xAC,
        0x40,
        0x3C,
        0x9E,
        0xFE,
        0x98,
        0x39,
        0x24,
        0x87,
        0xF4,
        0xEA,
        0x15,
        0x51,
        0xEC,
        0xCB,
        0x5D,
        0xBC,
        0x97,
        0x4F,
      ];

      final bool verified = account.verify(
        data: Uint8List.fromList(data),
        signature: Uint8List.fromList(signature),
      );
      expect(verified, isTrue);

      // Corrupted version which has the last byte modified
      final List<int> manipulatedSignature = <int>[
        0x5C,
        0xDC,
        0x7C,
        0x59,
        0xE0,
        0x9C,
        0xDD,
        0x1A,
        0xE1,
        0xE5,
        0xC8,
        0xD5,
        0x21,
        0x1E,
        0xFA,
        0x09,
        0x25,
        0x31,
        0x92,
        0x42,
        0x50,
        0xE1,
        0x56,
        0x26,
        0x66,
        0x00,
        0xCB,
        0xDC,
        0x69,
        0xBF,
        0x9F,
        0xED,
        0x5C,
        0x28,
        0x5F,
        0x33,
        0x9E,
        0x17,
        0xDA,
        0xA2,
        0xFC,
        0xAC,
        0xED,
        0x7C,
        0xD3,
        0xAC,
        0x40,
        0x3C,
        0x9E,
        0xFE,
        0x98,
        0x39,
        0x24,
        0x87,
        0xF4,
        0xEA,
        0x15,
        0x51,
        0xEC,
        0xCB,
        0x5D,
        0xBC,
        0x97,
        0x50,
      ];

      final bool notVerified = account.verify(
        data: Uint8List.fromList(data),
        signature: Uint8List.fromList(manipulatedSignature),
      );
      expect(notVerified, isFalse);
    });

    test('accountVerifyNodeSignature_ED25519', () {
      final Uint8List data = 'Some random test data'.toBytes();

      const String seed =
          '2401D206735C20485347B9A622D94DE9B21F2F1450A77C42102237FA4077567D';
      final Account account = AccountBuilder.createFromSeed(
        seed: seed,
        index: 1,
        algorithm: KeyAlgorithm.ed25519,
      );

      final Uint8List signature =
          '''
B7AC4D279F1602A315B939B90587D18BA65817B6C241D2539245DB32C05BB7A6C20F9067189F04F9B59E6F153D2DECAA06DFCF1E11989CACE3368CD20A878B04'''
              .toBytes();

      final bool verified = account.verify(data: data, signature: signature);
      expect(verified, isTrue);
    });

    test('verifySignaturesFromOtherAccountTypes', () {
      const String privateKey =
          '50A44F48CF187E47483614BDA872E9405D36FE0DDF0ADA0FAE5982BDFBE9EF13';

      final Account account1 = AccountBuilder.createFromPrivateKey(
        privateKey: privateKey,
        algorithm: KeyAlgorithm.ecdsaSecp256k1,
      );
      final Account account2 = AccountBuilder.createFromPrivateKey(
        privateKey: privateKey,
        algorithm: KeyAlgorithm.ed25519,
      );

      expect(
        account1.keyPair.publicKey,
        isNot(equals(account2.keyPair.publicKey)),
      );

      final Uint8List data = 'Some random test data'.toBytes();

      final Uint8List signature1 = account1.sign(data: data);
      final Uint8List signature2 = account2.sign(data: data);

      final bool verified1_1 = account1.verify(
        data: data,
        signature: signature1,
      );
      final bool verified1_2 = account1.verify(
        data: data,
        signature: signature2,
      );
      final bool verified2_1 = account2.verify(
        data: data,
        signature: signature1,
      );
      final bool verified2_2 = account2.verify(
        data: data,
        signature: signature2,
      );

      expect(verified1_1, isTrue);
      expect(verified1_2, isFalse);
      expect(verified2_1, isFalse);
      expect(verified2_2, isTrue);
    });

    test('tryAccountSignWithoutPrivateKey', () {
      const String encodedPublicKey = '''
keeta_aabm7moneqqjpaaee5vxjqoe5f2ay3dchgr2hysdfh4wg3ycylohabivswjyfci''';
      final Account account = AccountBuilder.createFromPublicKey(
        publicKey: encodedPublicKey,
      );
      final Uint8List data = 'Input to sign'.toBytes();

      expect(
        () => account.sign(data: data),
        throwsA(isA<CustomException>()),
        reason: 'Should not be possible to sign data without private key.',
      );
    });

    test('tokenIdentifier', () {
      const String seed =
          '2401D206735C20485347B9A622D94DE9B21F2F1450A77C42102237FA4077567D';
      final Account token = AccountBuilder.createFromSeed(
        seed: seed,
        index: 0,
      ).generateIdentifier();

      expect(
        token.publicKeyString,
        equals(
          'keeta_apawchjv3mp6odgesjluzgolzk6opwq3yzygmor2ojkkacjb4ra6anxxzwsti',
        ),
      );
    });

    test('createFromPublicKeyAndType', () {
      const String encodedPublicKey = '''
keeta_aabm7moneqqjpaaee5vxjqoe5f2ay3dchgr2hysdfh4wg3ycylohabivswjyfci''';
      final Account account = AccountBuilder.createFromPublicKey(
        publicKey: encodedPublicKey,
      );
      expect(
        account,
        equals(Account.fromPublicKeyAndType(account.publicKeyAndType)),
      );
    });
  });
}
