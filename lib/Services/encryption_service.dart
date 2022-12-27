import 'package:encrypt/encrypt.dart';

class EncryptionService {
  final key = Key.fromUtf8('bdKC0MrHrYvMraoCEmJcuG3Ef5PNbHrZ');
  final iv = IV.fromLength(16);

  String enc(String data) {
    final encrypter = Encrypter(AES(key));
    Encrypted encrypted = encrypter.encrypt(data, iv: iv);

    return encrypted.base64;
  }

  String dec(String data) {
    final encrypter = Encrypter(AES(key));
    Encrypted encrypted = Encrypted.fromBase64(data);
    String decrypted = encrypter.decrypt(encrypted, iv: iv);

    return decrypted;
  }
}
