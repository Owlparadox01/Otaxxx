import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';

// Pastikan URL ini sesuai dengan server NodeJS Anda
const String baseUrl = "http://tirz.panel.jserver.web.id:2001";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Premium Color Palette
  final Color primaryDark = const Color(0xFF0A0A1A);
  final Color primaryNeon = const Color(0xFF00E5FF);
  final Color secondaryNeon = const Color(0xFF7C4DFF);
  final Color accentRed = const Color(0xFFFF4081);
  final Color deepRed = const Color(0xFFD81B60);
  final Color softRed = const Color(0xFFFF5252);
  final Color textWhite = Colors.white;
  final Color textGrey = const Color(0xFFB8B8D0);
  final Color cardBg = const Color(0xCC16163A);
  
  final String _buyAccessUrl = "https://t.me/zanzsii";
  final String _whatsAppChannelUrl =
      "https://whatsapp.com/channel/0029VbBPTA21iUxU1kt8wC25";

  @override
  void initState() {
    super.initState();
    _initAnim();
    initLogin();
  }

  void _initAnim() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  // Fungsi Auto Login saat membuka aplikasi
  Future<void> initLogin() async {
    final id = await getAndroidId();
    if (mounted) setState(() => androidId = id);

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse(
        "$baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey",
      );

      try {
        final res = await http.get(uri);
        final data = jsonDecode(res.body);

        if (data['valid'] == true) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SplashScreen(
                  username: savedUser,
                  password: savedPass,
                  role: data['role'],
                  sessionKey: data['key'],
                  telegramId: (data['telegramId'] ?? '-').toString(),
                  expiredDate: data['expiredDate'],
                  listBug: (data['listBug'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList(),
                  listDoos: (data['listDDoS'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList(),
                  news: (data['news'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList(),
                ),
              ),
            );
          }
        }
      } catch (_) {
        // Jika error, biarkan user login manual
      }
    }
  }

  Future<String> getAndroidId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        return android.id;
      }
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return ios.identifierForVendor ?? "ios_unknown_device";
      }
      return "unknown_device";
    } catch (_) {
      return "unknown_device";
    }
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userController.text.trim();
    final password = passController.text.trim();

    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );

      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showPopup(
          title: "⏳ Access Expired",
          message: "Masa akses Anda telah habis.\nSilakan perpanjang akses.",
          color: const Color(0xFFFF9800),
          showContact: true,
        );
      } else if (validData['valid'] != true) {
        final String errorMsg = (validData['message'] ?? "").toLowerCase();

        if (errorMsg.contains("dihapus") || errorMsg.contains("deleted")) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove("username");
          await prefs.remove("password");
          await prefs.remove("key");
          _showPopup(
            title: "⛔ Akses Dihapus",
            message:
                "Akun ini sudah dihapus oleh server karena pelanggaran kebijakan login.",
            color: const Color(0xFFFF5252),
          );
        } else if (errorMsg.contains("perangkat") ||
            errorMsg.contains("device") ||
            errorMsg.contains("another")) {
          _showPopup(
            title: "⚠️ Sesi Aktif",
            message:
                "Akun ini sedang login di perangkat lain.\nSilakan logout terlebih dahulu di perangkat lama.",
            color: const Color(0xFF00E5FF),
          );
        } else {
          _showPopup(
            title: "❌ Login Gagal",
            message: "Username atau password salah.",
            color: const Color(0xFF7C4DFF),
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SplashScreen(
                username: username,
                password: password,
                role: validData['role'],
                sessionKey: validData['key'],
                telegramId: (validData['telegramId'] ?? '-').toString(),
                expiredDate: validData['expiredDate'],
                listBug: (validData['listBug'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                listDoos: (validData['listDDoS'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                news: (validData['news'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
              ),
            ),
          );
        }
      }
    } catch (_) {
      _showPopup(
        title: "⚠️ Connection Error",
        message: "Gagal terhubung ke server.\nPeriksa koneksi internet Anda.",
        color: const Color(0xFF7C4DFF),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _showPopup({
    required String title,
    required String message,
    Color color = const Color(0xFF7C4DFF),
    bool showContact = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12122A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
        ),
        title: Row(
          children: [
            Icon(
              title.contains("✅") ? Icons.check_circle :
              title.contains("❌") ? Icons.error_outline :
              title.contains("⚠️") ? Icons.warning_amber_rounded :
              Icons.info_outline,
              color: color,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title.replaceAll(RegExp(r'[❌✅⚠️⏳⛔]'), ''),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFB8B8D0),
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          if (showContact)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () async {
                  await launchUrl(
                    Uri.parse("https://t.me/zanzsii"),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Contact Admin",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Close",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0A1A),
              const Color(0xFF12122A),
              const Color(0xFF1A1A3A),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: _buildLoginPanel(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPanel(BuildContext context) {
    final width = MediaQuery.of(context).size.width.clamp(280.0, 520.0);
    return SizedBox(
      width: width.toDouble(),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHero(),
            const SizedBox(height: 32),
            _buildInput(userController, "Username", Icons.person_outline_rounded),
            const SizedBox(height: 18),
            _buildInput(passController, "Password", Icons.lock_outline_rounded, true),
            const SizedBox(height: 28),
            _buildButton(context),
            const SizedBox(height: 18),
            _buildAccessButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: accentRed.withOpacity(0.3 * _pulseAnim.value),
                    blurRadius: 30 * _pulseAnim.value,
                    spreadRadius: 5 * _pulseAnim.value,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [accentRed, secondaryNeon],
          ).createShader(bounds),
          child: Text(
            "NOVA CRASHER",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Poppins',
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: accentRed.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentRed.withOpacity(0.3)),
          ),
          child: Text(
            "By @FIXCHCRASHERROWR",
            style: TextStyle(
              color: accentRed.withOpacity(0.9),
              fontSize: 11,
              letterSpacing: 1.5,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label,
    IconData icon, [
    bool isPassword = false,
  ]) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentRed.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontFamily: 'Inter',
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? "Field tidak boleh kosong" : null,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: textGrey.withOpacity(0.5),
            fontSize: 14,
            fontFamily: 'Inter',
          ),
          prefixIcon: Icon(icon, color: accentRed.withOpacity(0.7), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: accentRed.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: accentRed, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentRed, secondaryNeon],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: accentRed.withOpacity(0.4 * _pulseAnim.value),
                blurRadius: 20 * _pulseAnim.value,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : login,
              borderRadius: BorderRadius.circular(30),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            "LOGIN",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentRed.withOpacity(0.1), secondaryNeon.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentRed.withOpacity(0.2)),
            ),
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(_buyAccessUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: Icon(Icons.shopping_bag_rounded, color: accentRed, size: 18),
              label: Text(
                "Buy Access",
                style: TextStyle(
                  color: accentRed,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryNeon.withOpacity(0.1), accentRed.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryNeon.withOpacity(0.2)),
            ),
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(_whatsAppChannelUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: Icon(
                Icons.chat_bubble_rounded,
                color: primaryNeon,
                size: 18,
              ),
              label: Text(
                "Join WA",
                style: TextStyle(
                  color: primaryNeon,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}