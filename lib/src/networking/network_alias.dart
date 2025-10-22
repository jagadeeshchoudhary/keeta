/// Network alias for Keeta networks
enum NetworkAlias {
  test,
  main;

  /// Returns the API base URL for a representative
  String keetaRepApiBaseUrl({final int number = 1}) =>
      'https://rep$number.$name.network.api.keeta.com/api';

  /// Returns the WebSocket base URL for a representative
  String keetaRepSocketBaseUrl({final int number = 1}) =>
      'wss://rep$number.$name.network.api.keeta.com/p2p';

  /// Returns the address for a representative
  String keetaRepAddress({int number = 1}) {
    final List<String> addresses;

    switch (this) {
      case NetworkAlias.test:
        addresses = <String>[
          '''keeta_aabi4bd3f7jrt67mxcq44ozj65bh4bp2mygmrkedxggu2rxwn2ztuw3b6exivbq''',
          '''keeta_aab3cxegizwhtim3zlyuwjhiqd5ikkhxg42smhwc3wx6yn7ep2t6lwo6emvw4wa''',
          '''keeta_aabznoicrzvte6ql5rxbgugmfrjqubbnjuo5l6ivopowy4rpkqgs5fco3oaezcq''',
          '''keeta_aabf7dz5asq2n2lrldct33x2ww65cophxp7egfiixbb7tbyat5r3kcbcez7ftpi''',
        ];
      case NetworkAlias.main:
        addresses = <String>[
          '''keeta_aabwip6zeo2fnzfxp5hssrrqtascs2277w2zk7vqd6d3k3m4dkt2flcbca2mqki''',
          '''keeta_aabvmwxttv4q56gbfveighwfwp3yvitlrdfsacic3ckqc7lqelsspvmhc7oldmq''',
          '''keeta_aabwqf5fnta4t2v2atieis545b3rqoq6z7x5w3geugiilqlz5jdsb5og2rmxvdq''',
          '''keeta_aablpogflko72eusdhuuqgsto2rwcvy2m5mo5snmvrmbacz3qczwjtwpmzf5ufq''',
        ];
    }

    return addresses[number - 1];
  }
}
