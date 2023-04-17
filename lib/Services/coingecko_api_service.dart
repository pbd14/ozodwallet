import 'dart:convert';

import 'package:http/http.dart';

class CoingeckoApiService {
  Client httpClient = Client();
  String api = "https://api.coingecko.com/api/v3/";

  // "ethereum", "matic-network"

  Future<String> getCoinsList() async {
    final response = await httpClient.get(Uri.parse("$api/coins/list"));
    return response.body;
  }

  Future<double> getEthVsUsd() async {
    final response = await httpClient.get(
      Uri.parse("$api/simple/price?ids=ethereum&vs_currencies=usd"),
    );
    return jsonDecode(response.body)["ethereum"]["usd"];
  }

  Future<double> getMaticVsUsd() async {
    final response = await httpClient.get(
      Uri.parse("$api/simple/price?ids=matic-network&vs_currencies=usd"),
    );
    return jsonDecode(response.body)["matic-network"]["usd"];
  }
}
