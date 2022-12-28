import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class SwapzoneApiService {
  Client httpClient = Client();

  Future<List> getSupportedCoins() async {
    await dotenv.load(fileName: ".env");
    final swapzone_response = await httpClient.get(
        Uri.parse('https://api.swapzone.io/v1/exchange/currencies'),
        headers: {'x-api-key': dotenv.env['SWAPZONE_API']!});
    return json.decode(swapzone_response.body);
  }

  Future<List> getRate(String currencyId, String coinId) async {
    await dotenv.load(fileName: ".env");
    final swapzone_response = await httpClient.get(
        Uri.parse(
            'https://api.swapzone.io/v1/exchange/get-rate?from=${currencyId}&to=${currencyId}&amount=0.1&rateType=all&availableInUSA=false&chooseRate=best&noRefundAddress=false'),
        headers: {'x-api-key': dotenv.env['SWAPZONE_API']!});
    return [];
  }
}
