import 'package:SumberBaru/screens/mobil_home_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'home_screen.dart';
import 'mobil_home_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _submitChangePassword() async {
    // 1. Validasi Input
    if (_currentPassController.text.isEmpty ||
        _newPassController.text.isEmpty ||
        _confirmPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua kolom harus diisi"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password baru dan konfirmasi tidak sama"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 2. Request Ganti Password
    bool success = await _apiService.changePassword(
      widget.token,
      _currentPassController.text,
      _newPassController.text,
      _confirmPassController.text,
    );

    // Perhatikan: Loading jangan dimatikan dulu jika sukses,
    // karena kita mau fetch profile

    if (success) {
      // Tampilkan notifikasi sukses
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password berhasil diperbarui!"), backgroundColor: Colors.green),
      );

      // 3. LOGIC REDIRECT (Cek Profile Dulu)
      // Ambil data profile untuk cek is_mobile
      var profileData = await _apiService.getProfile(widget.token);

      setState(() => _isLoading = false); // Stop loading setelah data profile dapat

      bool isMobile = false;
      String userName = profileData?['name'] ?? "User";

      // Cek apakah data valid dan is_mobile true
      if (profileData != null &&
          profileData['position'] != null &&
          profileData['position']['is_mobile'] == true) {
        isMobile = true;
      }

      if (!mounted) return;


      if (isMobile) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MobileHomeScreen(token: widget.token, name: userName)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(token: widget.token, name: userName)),
        );
      }

    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memperbarui password. Cek password lama Anda."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.orange),
            const SizedBox(height: 15),
            const Text(
              "Keamanan Diperlukan",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Anda terdeteksi menggunakan password lama. Silakan buat password baru untuk melanjutkan.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            _buildPasswordField(
              controller: _currentPassController,
              label: "Password Lama",
              isObscure: _obscureCurrent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 15),

            _buildPasswordField(
              controller: _newPassController,
              label: "Password Baru",
              isObscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 15),

            _buildPasswordField(
              controller: _confirmPassController,
              label: "Konfirmasi Password Baru",
              isObscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _submitChangePassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SIMPAN PASSWORD BARU", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }
}