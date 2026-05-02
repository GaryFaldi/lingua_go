import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'currency_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key});

  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  final _amountController = TextEditingController(text: "1");
  String _baseCurrency = "IDR";
  String _targetCurrency = "USD";
  double _result = 0;
  bool _isLoading = true;
  Map<String, dynamic> _rates = {};

  @override
  void initState() {
    super.initState();
    _initLBSAndData();
  }

  // LBS: Deteksi Negara & Set Mata Uang Otomatis
  Future<void> _initLBSAndData() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        String? countryCode = placemarks.first.isoCountryCode; // Misal: "ID"
        setState(() {
          if (countryCode == "ID") _baseCurrency = "IDR";
          if (countryCode == "JP") _baseCurrency = "JPY";
          // Tambahkan logika negara lain jika perlu
        });
      }
    } catch (e) {
      debugPrint("LBS Error: $e");
    } finally {
      _fetchNewRates();
    }
  }

  Future<void> _fetchNewRates() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await CurrencyService().getLatestRates(_baseCurrency);

      if (mounted) {
        setState(() {
          _rates = data;
          _isLoading = false;
          // Debugging: Print untuk melihat apakah data masuk ke HP kamu
          debugPrint("Rates loaded for $_baseCurrency: $_rates");
          _calculate();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Error fetching rates: $e");
      }
    }
  }

  void _calculate() {
    if (_rates.isNotEmpty && _rates.containsKey(_targetCurrency)) {
      // Hapus titik agar bisa dibaca sebagai angka oleh Dart
      String cleanValue = _amountController.text.replaceAll('.', '');
      double amount = double.tryParse(cleanValue) ?? 0;

      double rate = (_rates[_targetCurrency] as num).toDouble();

      setState(() {
        _result = amount * rate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Currency Converter")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandSeparatorFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      hintText: "Contoh: 1.000",
                    ),
                    onChanged: (value) => _calculate(),
                  ),
                  const SizedBox(height: 20),

                  // Dropdown Row
                  Row(
                    children: [
                      Expanded(child: _buildCurrencyDropdown(true)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.grey,
                        ),
                      ),
                      Expanded(child: _buildCurrencyDropdown(false)),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Result Card (Sesuai Tema Biru-Ungu)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Result",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${NumberFormat("#,###", "pt_BR").format(_result).replaceAll(',', '.')} $_targetCurrency",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrencyDropdown(bool isBase) {
    // Daftar lengkap mata uang yang didukung API Frankfurter
    List<String> items = [
      "AUD",
      "BGN",
      "BRL",
      "CAD",
      "CHF",
      "CNY",
      "CZK",
      "DKK",
      "EUR",
      "GBP",
      "HKD",
      "HUF",
      "IDR",
      "ILS",
      "INR",
      "ISK",
      "JPY",
      "KRW",
      "MXN",
      "MYR",
      "NOK",
      "NZD",
      "PHP",
      "PLN",
      "RON",
      "SEK",
      "SGD",
      "THB",
      "TRY",
      "USD",
      "ZAR",
    ];

    return DropdownButtonFormField<String>(
      initialValue: isBase ? _baseCurrency : _targetCurrency,
      // Gunakan isExpanded agar teks tidak terpotong jika layar kecil
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: (val) {
        setState(() {
          if (isBase) {
            _baseCurrency = val!;
          } else {
            _targetCurrency = val!;
          }
        });
        if (isBase) {
          _fetchNewRates();
        } else {
          _calculate();
        }
      },
    );
  }
}

class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hapus semua karakter selain angka
    String cleanedText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Format angka menggunakan NumberFormat dari package intl
    final formatter = NumberFormat(
      "#,###",
      "pt_BR",
    ); // pt_BR menggunakan titik (.)
    double value = double.parse(cleanedText);
    String formattedText = formatter.format(value).replaceAll(',', '.');

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
