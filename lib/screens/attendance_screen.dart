import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_services.dart';

class AttendanceScreen extends StatefulWidget {
  final String token;
  final bool isMobile;

  const AttendanceScreen({
    super.key,
    required this.token,
    this.isMobile = false,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  File? _image;
  bool _isLoading = false;
  String _statusMessage = "Siap"; // Pesan status dinamis
  final ApiService _apiService = ApiService();

  // --- LOGIC 1: PERMISSION & GPS HANDLER ---
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackbar("GPS mati. Mohon nyalakan GPS/Lokasi Anda.");
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackbar("Izin lokasi ditolak.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _showPermissionDialog();
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      _showErrorSnackbar("Sinyal GPS lemah. Coba pindah ke area terbuka.");
      return null;
    }
  }

  Future<void> _showPermissionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Izin Lokasi Dibutuhkan'),
          content: const Text('Mohon buka pengaturan dan izinkan akses lokasi.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Buka Settings'),
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- LOGIC 2: PROSES ABSEN ---
  Future<void> _doAbsen() async {
    // START LOADING: MENDETEKSI LOKASI
    setState(() {
      _isLoading = true;
      _statusMessage = "Mendeteksi Lokasi...";
    });

    try {
      // 1. Cari Lokasi
      Position? pos = await _determinePosition();

      if (pos == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Persiapan Kamera
      setState(() => _statusMessage = "Menyiapkan Kamera...");
      await Future.delayed(const Duration(milliseconds: 500)); // Delay dikit biar transisi halus

      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 40,
        maxWidth: 600,
      );

      if (photo != null) {
        _image = File(photo.path);

        // 3. Mengirim Data (Status Upload)
        setState(() => _statusMessage = "Mengupload Data...");

        // Memanggil API
        Map<String, dynamic> result = await _apiService.postAttendance(
            widget.token,
            pos.latitude,
            pos.longitude,
            _image!
        );

        bool isSuccess = result['success'];
        String message = result['message'];

        if (!mounted) return;

        if (isSuccess) {
          // 4. Sukses
          setState(() => _statusMessage = "Berhasil!");
          await Future.delayed(const Duration(milliseconds: 1000)); // Tahan sebentar biar user liat "Berhasil"

          if(!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.green)
          );
          Navigator.pop(context); // Kembali ke Home
        } else {
          // Gagal dari API
          _showErrorSnackbar(message);
          setState(() => _isLoading = false);
        }
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = "Absen Dibatalkan";
        });
      }
    } catch (e) {
      _showErrorSnackbar("Gagal: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red)
    );
  }

  // --- BUILDER: TAMPILAN LOADING KEREN ---
  Widget _buildLoadingScreen() {
    // Tentukan Icon berdasarkan pesan status
    IconData statusIcon = Icons.hourglass_top;
    Color iconColor = Colors.blue;

    if (_statusMessage.contains("Lokasi")) {
      statusIcon = Icons.location_searching;
      iconColor = Colors.orange;
    } else if (_statusMessage.contains("Kamera")) {
      statusIcon = Icons.camera_alt;
      iconColor = Colors.purple;
    } else if (_statusMessage.contains("Mengupload")) {
      statusIcon = Icons.cloud_upload;
      iconColor = Colors.blue;
    } else if (_statusMessage.contains("Berhasil")) {
      statusIcon = Icons.check_circle;
      iconColor = Colors.green;
    }

    return Container(
      color: Colors.white, // Background putih bersih menutup layar belakang
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Card Melayang
          Container(
            padding: const EdgeInsets.all(30),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                // Icon Animasi
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    statusIcon,
                    key: ValueKey<String>(_statusMessage),
                    size: 60,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 30),

                // Text Status
                Text(
                  "Mohon Tunggu",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800]
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),

                // Progress Bar
                LinearProgressIndicator(
                  backgroundColor: Colors.grey[100],
                  color: iconColor,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String infoText = widget.isMobile
        ? "Mode Lapangan: Lokasi Anda akan dicatat saat mengambil foto."
        : "Pastikan Anda berada di lokasi kantor sebelum absen.";

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background agak abu sedikit biar modern
      appBar: AppBar(
        title: const Text("Absensi"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      // MENGGUNAKAN STACK AGAR LOADING MUNCUL DI ATAS KONTEN
      body: Stack(
        children: [
          // 1. KONTEN UTAMA
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        widget.isMobile ? Icons.map_outlined : Icons.location_on_outlined,
                        size: 60,
                        color: Colors.blueAccent
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Siap untuk Absen?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    infoText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("AMBIL FOTO SEKARANG", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _doAbsen,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. OVERLAY LOADING (Hanya muncul jika _isLoading = true)
          if (_isLoading)
            _buildLoadingScreen(),
        ],
      ),
    );
  }
}