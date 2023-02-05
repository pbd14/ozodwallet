import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';

class SafeStorageService {
  final storage = FlutterSecureStorage(
      aOptions: const AndroidOptions(
    encryptedSharedPreferences: true,
  ));

  Future<Map> getWalletData(String walletIndex) async {
    String? publicKey = await storage.read(key: 'publicKey${walletIndex}');
    String? privateKey = await storage.read(key: 'privateKey${walletIndex}');
    String? name = await storage.read(key: 'Wallet${walletIndex}');
    EthereumAddress valueAddress = EthPrivateKey.fromHex(privateKey!).address;
    Credentials credentials = EthPrivateKey.fromHex(privateKey);

    return {
      'privateKey': privateKey,
      'publicKey': publicKey,
      'name': name,
      'address': valueAddress,
      'walletIndex': walletIndex,
      'credentials': credentials,
    };
  }

  Future<List> getAllWallets() async {
    List wallets = [];
    String? lastWalletIndex = await storage.read(key: 'lastWalletIndex');
    for (int i = 1; i <= int.parse(lastWalletIndex!) - 1; i++) {
      String? valuePublicKey = await storage.read(key: 'publicKey${i}');
      String? valueName = await storage.read(key: 'Wallet${i}');
      wallets.add({i: valueName, 'publicKey': valuePublicKey});
    }
    return wallets;
  }

  Future<void> addNewWallet(String walletIndex, String privateKey,
      String publicKey, String password, String name) async {
    await storage.write(key: "privateKey${walletIndex}", value: privateKey);
    await storage.write(key: "publicKey${walletIndex}", value: publicKey);
    await storage.write(key: "password${walletIndex}", value: password);
    await storage.write(key: "Wallet${walletIndex}", value: name);
    await storage.write(
        key: "lastWalletIndex", value: (int.parse(walletIndex) + 1).toString());
    await storage.write(key: "walletExists", value: 'true');
  }

  Future<void> editWalletName(String walletIndex, String name) async {
    await storage.write(key: "Wallet${walletIndex}", value: name);
  }
}
