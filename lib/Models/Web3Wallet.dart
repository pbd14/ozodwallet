import 'package:encrypt/encrypt.dart';
import 'package:web3dart/web3dart.dart';

class Web3Wallet {
  String publicKey;
  String privateKey;
  String name;
  String localIndex;
  String password = "Password";

  Web3Wallet({
    this.privateKey = 'Loading',
    this.name = 'Loading',
    this.publicKey = 'Loading',
    this.localIndex = '1',
  });

  Credentials get credentials => EthPrivateKey.fromHex(privateKey);
  EthereumAddress get valueAddress => EthPrivateKey.fromHex(privateKey).address;

  final key = Key.fromUtf8('a9ece34e2413278f8f2e554fe65493c4');
  final iv = IV.fromLength(16);

  String encPrivateKey(String data) {
    final encrypter = Encrypter(AES(key));
    Encrypted encrypted = encrypter.encrypt(data, iv: iv);

    return encrypted.base64;
  }

  String decPrivateKey(String data) {
    final encrypter = Encrypter(AES(key));
    Encrypted encrypted = Encrypted.fromBase64(data);
    String decrypted = encrypter.decrypt(encrypted, iv: iv);

    return decrypted;
  }
}
