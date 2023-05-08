import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ozodwallet/Models/Web3Wallet.dart';

class SafeStorageService {
  final storage = FlutterSecureStorage(
      aOptions: const AndroidOptions(
    encryptedSharedPreferences: true,
  ));

  Future<Web3Wallet> getWallet(String walletIndex) async {
    String? publicKey = await storage.read(key: 'publicKey${walletIndex}');
    String? privateKey = await storage.read(key: 'privateKey${walletIndex}');
    String? name = await storage.read(key: 'Wallet${walletIndex}');

    return Web3Wallet(
      privateKey: privateKey ?? "Error",
      publicKey: publicKey ?? "Error",
      name: name ?? "Error",
      localIndex: walletIndex,
    );
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

  Future<void> addNewWallet(Web3Wallet wallet) async {
    await storage.write(
        key: "privateKey${wallet.localIndex}", value: wallet.privateKey);
    await storage.write(
        key: "publicKey${wallet.localIndex}", value: wallet.publicKey);
    await storage.write(
        key: "password${wallet.localIndex}", value: wallet.password);
    await storage.write(key: "Wallet${wallet.localIndex}", value: wallet.name);
    await storage.write(
        key: "lastWalletIndex",
        value: (int.parse(wallet.localIndex) + 1).toString());
    await storage.write(key: "walletExists", value: 'true');
  }

  Future<void> editWalletName(String walletIndex, String name) async {
    await storage.write(key: "Wallet${walletIndex}", value: name);
  }

  Future<void> deleteAllData() async {
    await storage.deleteAll();
  }
}
