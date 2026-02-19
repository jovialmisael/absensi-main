import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import 'mobil_home_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // Controller
  final _nikController = TextEditingController();
  final _passController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Animation Controllers
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  late AnimationController _formFadeController;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;

  // State
  bool _isLoading = false;
  final ValueNotifier<bool> _obscurePasswordNotifier = ValueNotifier(true);

  // Colors
  final Color _brandRed = const Color(0xFFD32F2F);
  final Color _brandBlack = const Color(0xFF212121);
  final double _logoWidth = 260.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // 1. Setup Animasi Garis
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    // 2. Setup Animasi Form
    _formFadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _formFadeAnimation = CurvedAnimation(
      parent: _formFadeController,
      curve: Curves.easeOutQuart,
    );

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_formFadeAnimation);

    // Jalankan animasi setelah delay
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        _entryController.forward();
        _formFadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _formFadeController.dispose();
    _nikController.dispose();
    _passController.dispose();
    _obscurePasswordNotifier.dispose();
    super.dispose();
  }

  // Fungsi Navigasi Terpusat
  void _navigateBasedOnRole(String token, String name, bool isMobile) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isMobile
            ? MobileHomeScreen(token: token, name: name)
            : HomeScreen(token: token, name: name),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // 1. Validasi Input (Pakai trim untuk hapus spasi tidak sengaja)
    final nik = _nikController.text.trim();
    final pass = _passController.text.trim();

    if (nik.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("NIK dan Password harus diisi"), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Mulai Loading
    setState(() => _isLoading = true);

    try {
      // 3. Panggil API Login
      LoginResponse res = await _apiService.login(nik, pass);

      if (res.success && res.accessToken != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', res.accessToken!);
        await prefs.setString('name', res.name ?? "User");
        await prefs.setString('nik', nik);

        // 4. Cek Password Lama (Reset Password)
        if (res.isOldPass) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ResetPasswordScreen(token: res.accessToken!)),
          );
          return;
        }

        // 5. Ambil Profile untuk cek Jabatan/Role
        var profileData = await _apiService.getProfile(res.accessToken!);

        if (!mounted) return;
        setState(() => _isLoading = false);

        bool isMobile = false;
        String userName = res.name ?? "User";

        // Logic Check Mobile yang Lebih Aman (Null Safety)
        if (profileData != null) {
          // Gunakan ?. dan ?? agar tidak crash jika data null
          final position = profileData['position'];
          print(position['is_mobile']);
          if (position != null && position['is_mobile'] == true) {
            isMobile = true;
          }
          // Update nama dari profile terbaru jika ada
          if (profileData['name'] != null) {
            userName = profileData['name'];
          }
        }

        // 6. Navigasi ke Home
        _navigateBasedOnRole(res.accessToken!, userName, isMobile);

      } else {
        // Login Gagal dari API
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      // Error Koneksi / Lainnya
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // --- LOGO IMAGE ---
                  RepaintBoundary(
                    child: Center(
                      child: Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          "lib/assets/sbb.png",
                          height: 100,
                          width: 250,
                          cacheWidth: 300,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- ANIMATED LINE ---
                  RepaintBoundary(
                    child: Center(
                      child: SizedBox(
                        width: _logoWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedBuilder(
                            animation: _entryAnimation,
                            builder: (context, child) {
                              return Container(
                                height: 4,
                                width: _logoWidth * _entryAnimation.value,
                                decoration: BoxDecoration(
                                  color: _brandRed,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _brandRed.withOpacity(0.3),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- FORM CONTENT ---
                  FadeTransition(
                    opacity: _formFadeAnimation,
                    child: SlideTransition(
                      position: _formSlideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- TITLE ---
                          RepaintBoundary(
                            child: ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [_brandRed, _brandBlack],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds),
                              child: const Text(
                                "ABSENSI",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                          Text(
                            "Masukan Data Diri",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),

                          const SizedBox(height: 40),

                          // --- INPUT FIELDS ---
                          _buildTextField(
                            controller: _nikController,
                            label: "Nomor Induk Karyawan (NIK)",
                            icon: Icons.badge_outlined,
                            primaryColor: _brandRed,
                            isPassword: false,
                          ),
                          const SizedBox(height: 20),

                          ValueListenableBuilder<bool>(
                            valueListenable: _obscurePasswordNotifier,
                            builder: (context, isObscure, child) {
                              return _buildTextField(
                                controller: _passController,
                                label: "Kata Sandi",
                                icon: Icons.lock_outline,
                                primaryColor: _brandRed,
                                isPassword: true,
                                isObscure: isObscure,
                                onToggleVisibility: () {
                                  _obscurePasswordNotifier.value = !isObscure;
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandRed,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: _brandRed.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                disabledBackgroundColor: _brandRed.withOpacity(0.6),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                                  : const Text(
                                "MASUK",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          const Center(
                            child: Text(
                              "Versi 1.0.0",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Digabung jadi satu fungsi builder agar lebih efisien
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    required bool isPassword,
    bool isObscure = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? isObscure : false,
        keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.text,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.8)),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[400],
            ),
            onPressed: onToggleVisibility,
          )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }
}