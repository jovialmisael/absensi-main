import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;

  const ProfileScreen({super.key, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  // Variable untuk menampung Future profile
  late Future<Map<String, dynamic>?> _profileFuture;

  // Animation Controllers
  late AnimationController _headerController;
  late Animation<double> _headerFade;

  late AnimationController _listController;

  // Automotive Brand Colors
  final Color _brandRed = const Color(0xFFD32F2F);
  final Color _darkAsphalt = const Color(0xFF1E1E1E); // Warna Ban/Dashboard
  final Color _silverMetal = const Color(0xFFF0F0F0); // Warna Body Silver
  final Color _chrome = const Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _refreshData();

    // Setup Header Animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFade = CurvedAnimation(parent: _headerController, curve: Curves.easeOut);

    // Setup List Animation (Staggered)
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Start Animations
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _headerController.forward();
        _listController.forward();
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _profileFuture = _apiService.getProfile(widget.token);
    });
    // Menunggu future selesai untuk refresh indicator
    try {
      await _profileFuture;
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  // --- FUNGSI EDIT DATA ---
  void _showEditDialog(String title, String fieldName, String currentValue) {
    TextEditingController controller = TextEditingController(text: currentValue == "-" ? "" : currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Ubah $title", style: TextStyle(fontWeight: FontWeight.bold, color: _darkAsphalt)),
          content: TextField(
            controller: controller,
            keyboardType: title == "Telepon" ? TextInputType.phone : TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Masukkan $title baru",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _brandRed, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(context); // Tutup dialog
                await _saveData(fieldName, controller.text);
              },
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveData(String field, String value) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menyimpan data...")));

    bool success = await _apiService.updateProfile(widget.token, field, value);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil disimpan"), backgroundColor: Colors.green));
      _refreshData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan data."), backgroundColor: Colors.red));
    }
  }

  // --- FUNGSI LOGOUT ---
  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Keluar"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _brandRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _silverMetal,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: _brandRed,
        backgroundColor: Colors.white,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            // Tampilan Loading Awal (bukan saat refresh)
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return Center(child: CircularProgressIndicator(color: _brandRed));
            }
        
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Center(
                child: SingleChildScrollView( // Agar bisa pull-to-refresh saat error
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text("Gagal memuat profil", style: TextStyle(color: Colors.grey[600])),
                      TextButton(onPressed: _refreshData, child: Text("Coba Lagi", style: TextStyle(color: _brandRed)))
                    ],
                  ),
                ),
              );
            }
        
            var data = snapshot.data!;
            // Parse Data
            String name = data['name'] ?? "-";
            String nik = data['nik'] ?? "-";
            String email = data['email'] ?? "-";
            String phone = data['phone'] ?? "-";
            String role = data['role'] ?? "Staff";
            String branch = (data['branch'] != null) ? data['branch']['name'] : "-";
            String position = (data['position'] != null) ? data['position']['name'] : "-";
            String homebase = (data['homebase'] != null) ? data['homebase']['name'] : "-";
            String joinDate = data['join_date'] ?? "-";
        
            return Stack(
              children: [
                // 1. BACKGROUND LAYER (Header + Textured Body)
                Column(
                  children: [
                    // HEADER AREA
                    Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: _darkAsphalt,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                          ]
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.35,
                              child: Image.asset(
                                'lib/assets/Gemini_Generated_Image_7461ma7461ma7461.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.2),
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Aksen Racing Stripe Atas
                          Positioned(
                            right: 40,
                            top: -20,
                            child: Transform.rotate(
                              angle: -0.2,
                              child: Container(
                                width: 15,
                                height: 350,
                                decoration: BoxDecoration(
                                  color: _brandRed.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // BODY AREA (Textured with Neat Tire Tracks)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: _silverMetal,
                        child: Stack(
                          children: [
                            // 1. VERTICAL TIRE TRACK (LEFT) - Parallel and Neat
                            Positioned(
                              left: 20, top: 0, bottom: 0,
                              child: _buildTireTrack(isHorizontal: false),
                            ),
        
                            // 2. HORIZONTAL TIRE TRACK (LOWER MIDDLE) - Parallel and Neat
                            Positioned(
                              left: 0, right: 0, bottom: 100,
                              child: _buildTireTrack(isHorizontal: true),
                            ),
        
                            // Watermark Logo
                            Positioned(
                              bottom: 30,
                              right: 20,
                              child: Opacity(
                                opacity: 0.1,
                                child: Image.asset(
                                  'lib/assets/sbb.png',
                                  width: 200,
                                  errorBuilder: (context, error, stackTrace) => Container(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        
                // 2. CONTENT LAYER
                SafeArea(
                  child: Column(
                    children: [
                      // AppBar Custom
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text("PROFIL SAYA", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          ],
                        ),
                      ),
        
                      Expanded(
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(), // PENTING: Agar bisa refresh meski konten sedikit
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                          children: [
        
                            // --- KARTU ID KARYAWAN ---
                            FadeTransition(
                              opacity: _headerFade,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8)),
                                  ],
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _brandRed, width: 2.5),
                                      ),
                                      child: CircleAvatar(
                                        radius: 35,
                                        backgroundColor: _chrome,
                                        child: Text(
                                          name.isNotEmpty ? name[0] : "?",
                                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _darkAsphalt),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name.toUpperCase(),
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkAsphalt),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            position,
                                            style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _darkAsphalt,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "NIK: $nik",
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
        
                            const SizedBox(height: 35),
        
                            // --- SEKSI KONTAK ---
                            _buildSectionHeader("KONTAK & AKUN", Icons.perm_contact_calendar_outlined),
                            _buildInfoCard([
                              _buildItemRow("Email", email, icon: Icons.email_outlined, isEditable: true, onTap: () => _showEditDialog("Email", "email", email)),
                              _buildDivider(),
                              _buildItemRow("Telepon", phone, icon: Icons.phone_android_outlined, isEditable: true, onTap: () => _showEditDialog("Telepon", "phone", phone)),
                            ]),
        
                            const SizedBox(height: 25),
        
                            // --- SEKSI DATA KARYAWAN ---
                            _buildSectionHeader("DATA PERUSAHAAN", Icons.business_center_outlined),
                            _buildInfoCard([
                              _buildItemRow("Cabang", branch, icon: Icons.store_outlined),
                              _buildDivider(),
                              _buildItemRow("Homebase", homebase, icon: Icons.map_outlined),
                              _buildDivider(),
                              _buildItemRow("Bergabung", joinDate, icon: Icons.calendar_today_outlined),
                              _buildDivider(),
                              _buildItemRow("Status", role, icon: Icons.admin_panel_settings_outlined),
                            ]),
        
                            const SizedBox(height: 40),
        
                            // --- TOMBOL LOGOUT ---
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(color: _brandRed.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                                  ]
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _brandRed,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                onPressed: _logout,
                                child: const Text("KELUAR APLIKASI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2.0)),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildTireTrack({required bool isHorizontal}) {
    return Opacity(
      opacity: 0.05,
      child: isHorizontal
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (index) => Container(
          margin: const EdgeInsets.symmetric(vertical: 2.5),
          height: 3, width: 1000, // Long horizontal lines
          color: _darkAsphalt,
        )),
      )
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: 3, height: 1000, // Long vertical lines
          color: _darkAsphalt,
        )),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _brandRed.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 18, color: _brandRed),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800], letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildItemRow(String label, String value, {required IconData icon, bool isEditable = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _silverMetal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _darkAsphalt.withOpacity(0.7), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
            if (isEditable)
              Icon(Icons.edit_square, size: 20, color: _brandRed.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: _silverMetal, indent: 70);
  }
}