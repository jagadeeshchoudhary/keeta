import 'package:keeta/src/account_feature/account.dart';
import 'package:keeta/src/account_feature/account_builder.dart';
import 'package:keeta/src/networking/client_representative.dart';
import 'package:keeta/src/networking/network_alias.dart';

typedef NetworkID = BigInt;

class NetworkConfig {
  const NetworkConfig({
    required this.networkAlias,
    required this.networkID,
    required this.baseToken,
    required this.baseTokenDecimals,
    required this.fountain,
    required this.reps,
  });

  /// Creates a network configuration for the given network alias
  factory NetworkConfig.create({required final NetworkAlias forNetwork}) {
    final NetworkID networkID;
    switch (forNetwork) {
      case NetworkAlias.test:
        networkID = BigInt.from(0x54455354); // 1413829460

      case NetworkAlias.main:
        networkID = BigInt.from(0x5382); // 21378
    }

    final String baseTokenPubKey;
    switch (forNetwork) {
      case NetworkAlias.test:
        baseTokenPubKey =
            '''keeta_anyiff4v34alvumupagmdyosydeq24lc4def5mrpmmyhx3j6vj2uucckeqn52''';

      case NetworkAlias.main:
        baseTokenPubKey =
            '''keeta_anqdilpazdekdu4acw65fj7smltcp26wbrildkqtszqvverljpwpezmd44ssg''';
    }

    final int baseTokenDecimals;
    switch (forNetwork) {
      case NetworkAlias.test:
        baseTokenDecimals = 9;

      case NetworkAlias.main:
        baseTokenDecimals = 18;
    }

    final String? fountainSeed;
    switch (forNetwork) {
      case NetworkAlias.test:
        fountainSeed =
            '0000000000000000000000000000000000000000000000000000000000000000';

      case NetworkAlias.main:
        fountainSeed = null;
    }

    const int numberOfReps = 4;

    final Account? fountain;
    if (fountainSeed != null) {
      fountain = AccountBuilder.createFromSeed(
        seed: fountainSeed,
        index: 0xffffffff,
      );
    } else {
      fountain = null;
    }

    final List<ClientRepresentative> reps = <ClientRepresentative>[];
    for (int i = 1; i <= numberOfReps; i++) {
      reps.add(
        ClientRepresentative(
          address: forNetwork.keetaRepAddress(number: i),
          apiUrl: forNetwork.keetaRepApiBaseUrl(number: i),
          socketUrl: forNetwork.keetaRepSocketBaseUrl(number: i),
        ),
      );
    }

    return NetworkConfig(
      networkAlias: forNetwork,
      networkID: networkID,
      baseToken: AccountBuilder.createFromPublicKey(publicKey: baseTokenPubKey),
      baseTokenDecimals: baseTokenDecimals,
      fountain: fountain,
      reps: reps,
    );
  }

  final NetworkAlias networkAlias;
  final NetworkID networkID;
  final Account baseToken;
  final int baseTokenDecimals;
  final Account? fountain;
  final List<ClientRepresentative> reps;
}
