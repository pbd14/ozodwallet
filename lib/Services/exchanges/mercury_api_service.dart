
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';

class MercuryoApiService {
  Client httpClient = Client();

  // Future<List> getSupportedCoins() async {
  //   await dotenv.load(fileName: ".env");
  //   final response = await httpClient.get(
  //     Uri.parse(
  //         'https://api.simpleswap.io/get_all_currencies?api_key=${dotenv.env['SIMPLESWAP_API']}'),
  //     headers: {'accept': 'application/json'},
  //   );
  //   return json.decode(response.body);
  // }

  bool checkCoinForFiat(String coinId) {
    if ([
      'BTC',
      'ETH',
      'BAT',
      'USDT',
      'ALGO',
      'TRX',
      'OKB',
      'BCH',
      'DAI',
      'TON',
      'BNB',
      '1INCH',
      'BUSD',
      'NEAR',
      'SOL',
      'DOT',
      'ADA',
      'KSM',
      'MATIC',
      'ATOM',
      'AVAX',
      'XLM',
      'XRP',
      'LTC',
      'SAND',
      'DYDX',
      'MANA',
      'USDC',
      'CRV',
      'FTM',
      'DOGE',
      'XTZ'
    ].contains(coinId.toUpperCase())) {
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
