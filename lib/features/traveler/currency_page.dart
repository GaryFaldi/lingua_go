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
  bool _hasConverted =
      false; // Untuk tampilkan hasil hanya setelah tombol ditekan
  Map<String, dynamic> _rates = {};

  @override
  void initState() {
    super.initState();
    _initLBSAndData();
  }

  Future<void> _initLBSAndData() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low, // Lebih cepat
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          String? countryCode = placemarks.first.isoCountryCode;
          setState(() {
            if (countryCode == "ID")
              _baseCurrency = "IDR";
            else if (countryCode == "JP")
              _baseCurrency = "JPY";
            else if (countryCode == "US")
              _baseCurrency = "USD";
            else if (countryCode == "GB")
              _baseCurrency = "GBP";
            else if (countryCode == "AU")
              _baseCurrency = "AUD";
          });
        }
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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Error fetching rates: $e");
      }
    }
  }

  // Sekarang dipanggil manual via tombol
  void _convert() {
    if (_rates.isEmpty || !_rates.containsKey(_targetCurrency)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rates belum tersedia, coba lagi.")),
      );
      return;
    }

    String cleanValue = _amountController.text.replaceAll('.', '');
    double amount = double.tryParse(cleanValue) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan jumlah yang valid.")),
      );
      return;
    }

    double rate = (_rates[_targetCurrency] as num).toDouble();

    setState(() {
      _result = amount * rate;
      _hasConverted = true;
    });
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
                    // Hapus onChanged → tidak auto-calculate lagi
                  ),
                  const SizedBox(height: 20),

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

                  const SizedBox(height: 24),

                  // TOMBOL CONVERT
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _convert,
                      icon: const Icon(Icons.currency_exchange),
                      label: const Text(
                        "Convert",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Result Card — hanya muncul setelah tombol ditekan
                  if (_hasConverted)
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
                          Text(
                            "${_amountController.text} $_baseCurrency =",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
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
      // FIX: ganti initialValue → value
      value: isBase ? _baseCurrency : _targetCurrency,
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
            _hasConverted = false; // Reset hasil saat base berubah
          } else {
            _targetCurrency = val!;
            _hasConverted = false; // Reset hasil saat target berubah
          }
        });
        if (isBase) _fetchNewRates(); // Fetch ulang hanya jika base berubah
      },
    );
  }
}

// FIX: Guard against empty/zero input
class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');

    String cleanedText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedText.isEmpty) return newValue.copyWith(text: '');

    double? value = double.tryParse(cleanedText);
    if (value == null) return oldValue;

    final formatter = NumberFormat("#,###", "pt_BR");
    String formattedText = formatter.format(value).replaceAll(',', '.');

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
