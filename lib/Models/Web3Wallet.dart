import 'package:web3dart/web3dart.dart';

class Web3Wallet {
  String publicKey;
  String privateKey;
  String name;
  String localIndex;
  String password = "Password";

  Web3Wallet({
    required this.privateKey,
    required this.publicKey,
    required this.name,
    required this.localIndex,
  });

  Credentials get credentials => EthPrivateKey.fromHex(privateKey);
  EthereumAddress get valueAddress =>
      EthPrivateKey.fromHex(privateKey).address;
}
