import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:geolocator/geolocator.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;

class TimeConversionPage extends StatefulWidget {
  const TimeConversionPage({super.key});

  @override
  State<TimeConversionPage> createState() => _TimeConversionPageState();
}

class _TimeConversionPageState extends State<TimeConversionPage> {
  late Timer _timer;
  DateTime _utcNow = DateTime.now().toUtc();
  String _localZoneName = "Loading...";

  // Kita tidak perlu menulis offset manual lagi, cukup ID lokasinya saja
  final List<Map<String, String>> _displayLocations = [
    {'id': 'Asia/Jakarta', 'name': 'Jakarta', 'desc': 'WIB - West Indonesia'},
    {'id': 'Asia/Makassar', 'name': 'Denpasar', 'desc': 'WITA - Central Indonesia'},
    {'id': 'Asia/Jayapura', 'name': 'Jayapura', 'desc': 'WIT - East Indonesia'},
    {'id': 'Europe/London', 'name': 'London', 'desc': 'United Kingdom'},
    {'id': 'Asia/Tokyo', 'name': 'Tokyo', 'desc': 'Japan'},
    {'id': 'America/New_York', 'name': 'New York', 'desc': 'USA'},
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition(); // Panggil LBS
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _utcNow = DateTime.now().toUtc());
    });
  }

  // Fungsi LBS: Deteksi lokasi user dan tentukan zona waktunya
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    // Konversi Lat/Lng ke ID zona waktu (misal: "Asia/Jakarta")
    String zoneId = tzmap.latLngToTimezoneString(position.latitude, position.longitude);
    
    setState(() {
      _localZoneName = zoneId;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('World Clock')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildMainClock(colorScheme),
          const SizedBox(height: 25),
          const Text("Zone Explorer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._displayLocations.map((loc) => _buildTimeTile(loc['id']!, loc['name']!, loc['desc']!, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildMainClock(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text("Detected Zone: $_localZoneName", style: const TextStyle(color: Colors.white70)),
          Text(
            DateFormat('HH:mm:ss').format(DateTime.now()),
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile(String zoneId, String city, String desc, ColorScheme colorScheme) {
    // Mengambil waktu spesifik berdasarkan zona waktu ID dari library timezone
    final location = tz.getLocation(zoneId);
    final cityTime = tz.TZDateTime.from(_utcNow, location);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(city, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: Text(
          DateFormat('HH:mm').format(cityTime),
          style: TextStyle(fontSize: 20, color: colorScheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}