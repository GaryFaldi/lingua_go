import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl = "https://api.frankfurter.app/latest";

  Future<Map<String, dynamic>> getLatestRates(String base) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?from=$base'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['rates'];
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}