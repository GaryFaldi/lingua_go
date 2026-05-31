import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'currency_service.dart';

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key});

  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  final _amountController = TextEditingController();

  String _baseCurrency = "IDR";
  String _targetCurrency = "USD";

  // Default result dimulai dari 0 sebelum API selesai load
  double _result = 0;
  bool _isLoading = true;

  // Menyimpan rates hasil fetch dari API (misal: {"USD": 0.000063, "JPY": 0.0094})
  Map<String, dynamic> _rates = {};

  @override
  void initState() {
    super.initState();
    _fetchNewRates();
  }

  /// Ambil rates terbaru dari API berdasarkan [_baseCurrency] yang aktif.
  /// Dipanggil saat halaman pertama dibuka atau base currency berubah.
  Future<void> _fetchNewRates() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await CurrencyService().getLatestRates(_baseCurrency);

      if (mounted) {
        setState(() {
          _rates = data;
          _isLoading = false;
          _calculate(); // Hitung ulang begitu rates baru tersedia
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Hitung konversi dari input amount × rate target currency.
  /// Dipanggil otomatis setiap kali amount atau target currency berubah.
  void _calculate() {
    // Bersihkan separator titik ribuan sebelum di-parse
    final cleanValue = _amountController.text.replaceAll('.', '');
    final double amount = double.tryParse(cleanValue) ?? 0;

    // Jika base dan target sama, hasil = amount itu sendiri
    if (_baseCurrency == _targetCurrency) {
      setState(() => _result = amount);
      return;
    }

    // Jika rates belum ada (API belum selesai), reset ke 0
    if (_rates.isEmpty || !_rates.containsKey(_targetCurrency)) {
      setState(() => _result = 0);
      return;
    }

    final double rate = (_rates[_targetCurrency] as num).toDouble();
    setState(() => _result = amount * rate);
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
                  // Input jumlah uang — pakai ThousandSeparatorFormatter
                  // supaya otomatis tampil format ribuan (misal: 1.000.000)
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandSeparatorFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      hintText: "Example: 1.000",
                    ),
                    // Hitung ulang setiap kali nilai input berubah
                    onChanged: (_) => _calculate(),
                  ),
                  const SizedBox(height: 20),

                  // Row dropdown: [Base Currency] → [Target Currency]
                  Row(
                    children: [
                      Expanded(child: _buildCurrencyDropdown(isBase: true)),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            // Tukar posisi base dan target currency
                            final temp = _baseCurrency;
                            _baseCurrency = _targetCurrency;
                            _targetCurrency = temp;
                          });
                          // Fetch ulang karena base currency berubah
                          _fetchNewRates();
                        },
                        icon: const Icon(Icons.swap_horiz_rounded),
                        tooltip: "Swap currency",
                      ),
                      Expanded(child: _buildCurrencyDropdown(isBase: false)),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Tampilan hasil konversi dengan gradient
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
                          // Format angka dengan separator lokal Indonesia (titik ribuan)
                          "${NumberFormat("#,##0.00", "id_ID").format(_result)} $_targetCurrency",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Builder untuk dropdown pilihan mata uang.
  /// [isBase] = true → dropdown base currency, false → dropdown target currency.
  Widget _buildCurrencyDropdown({required bool isBase}) {
    const List<String> currencies = [
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
      value: isBase ? _baseCurrency : _targetCurrency,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      items: currencies
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val == null) return;
        setState(() {
          if (isBase) {
            _baseCurrency = val;
          } else {
            _targetCurrency = val;
          }
        });
        // Ganti base → harus fetch ulang karena rates berubah total
        // Ganti target → cukup hitung ulang dari rates yang sudah ada
        if (isBase) {
          _fetchNewRates();
        } else {
          _calculate();
        }
      },
    );
  }
}

/// Custom formatter yang menambahkan titik sebagai pemisah ribuan.
/// Contoh: "1000000" → "1.000.000"
class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');

    // Hapus semua karakter non-angka sebelum diformat ulang
    final cleanedText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedText.isEmpty) return newValue.copyWith(text: '');

    // Format dengan locale pt_BR (koma = ribuan), lalu ganti koma → titik
    // supaya sesuai konvensi Indonesia (1.000.000)
    final formatted = NumberFormat(
      "#,###",
      "pt_BR",
    ).format(double.parse(cleanedText)).replaceAll(',', '.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
