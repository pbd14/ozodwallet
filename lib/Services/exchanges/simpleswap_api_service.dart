import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class SimpleswapApiService {
  Client httpClient = Client();

  Future<List> getSupportedCoins() async {
    await dotenv.load(fileName: ".env");
    final response = await httpClient.get(
      Uri.parse(
          'https://api.simpleswap.io/get_all_currencies?api_key=${dotenv.env['SIMPLESWAP_API']}'),
      headers: {'accept': 'application/json'},
    );
    return json.decode(response.body);
  }

  bool checkCoinForFiat(String coinId)  {
    if (['BTC', 'ETH', 'ALGO', 'BAT', 'BCH', 'DAI', 'USDT', 'TRX']
        .contains(coinId.toUpperCase())) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> checkCoin(String coinId) async {
    await dotenv.load(fileName: ".env");
    final response = await httpClient.get(
        Uri.parse(
            'https://api.simpleswap.io/get_currency?api_key=${dotenv.env['SIMPLESWAP_API']}&symbol=${coinId}'),
        headers: {'accept': 'application/json'});
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
