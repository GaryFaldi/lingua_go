import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl = "https://api.frankfurter.app/latest";

  // Fetch semua rates berbasis USD, lalu konversi ke base yang diinginkan
  Future<Map<String, dynamic>> getLatestRates(String base) async {
    try {
      // Selalu fetch dari USD
      final response = await http.get(Uri.parse('$_baseUrl?from=USD'));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        print("DEBUG API response: $body");
        Map<String, dynamic> usdRates = Map<String, dynamic>.from(
          body['rates'],
        );
        usdRates['USD'] = 1.0; // Tambahkan USD sendiri

        // Kalau base memang USD, langsung return
        if (base == 'USD') return usdRates;

        // Kalau base bukan USD, konversi semua rate
        // Contoh: base = IDR
        // rateIDR/USD = usdRates['IDR']
        // rateX/IDR = rateX/USD / rateIDR/USD
        double baseRate = (usdRates[base] as num?)?.toDouble() ?? 1.0;

        Map<String, dynamic> converted = {};
        usdRates.forEach((currency, rate) {
          if (currency != base) {
            converted[currency] = (rate as num).toDouble() / baseRate;
          }
        });

        return converted;
      }
      print("DEBUG status code: ${response.statusCode}");
      return {};
    } catch (e) {
      debugPrint("CurrencyService error: $e");
      return {};
    }
  }
}
