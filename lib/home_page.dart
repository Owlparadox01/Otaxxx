import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:lottie/lottie.dart';
import 'customfunct.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  String selectedBugId = "";

  String _selectedBugMode = "number";
  String _selectedSenderScope = "private";

  bool _isSending = false;
  String? _responseMessage;

  bool get _canUseGlobalSender {
    final role = widget.role.toLowerCase();
    return role == "vip" || role == "owner";
  }

  // --- Premium Color Palette ---
  final Color primaryBg = const Color(0xFF0A0A1A);
  final Color secondaryBg = const Color(0xFF12122A);
  final Color cardBg = const Color(0xCC16163A);
  final Color primaryNeon = const Color(0xFF00E5FF);
  final Color secondaryNeon = const Color(0xFF7C4DFF);
  final Color accentPink = const Color(0xFFFF4081);
  final Color successGreen = const Color(0xFF00E676);
  final Color warningOrange = const Color(0xFFFF9800);
  final Color errorRed = const Color(0xFFFF5252);
  final Color textWhite = Colors.white;
  final Color textGrey = const Color(0xFFB8B8D0);

  // Premium Gradients
  final LinearGradient primaryGradient = const LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient secondaryGradient = const LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient bgGradient = const LinearGradient(
    colors: [Color(0xFF0A0A1A), Color(0xFF12122A), Color(0xFF1A1A3A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }

    if (!_canUseGlobalSender) {
      _selectedSenderScope = "private";
    }

    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4');

    _videoController.initialize().then((_) {
      setState(() {
        _videoController.setVolume(0.1);
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          showControls: false,
          autoInitialize: true,
        );
        _isVideoInitialized = true;
      });
    }).catchError((error) {
      setState(() {
        _isVideoInitialized = false;
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    targetController.dispose();
    _videoController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  bool isValidGroupLink(String input) {
    return input.contains('chat.whatsapp.com') && input.contains('https://');
  }

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final key = widget.sessionKey;
    final senderScope = _selectedSenderScope;

    if (senderScope == "global" && !_canUseGlobalSender) {
      _showAlert("⚠️ Restricted", "Global sender hanya untuk VIP/OWNER.");
      return;
    }

    if (_selectedBugMode == "custom") {
      _showAlert(
        "Custom Function",
        "Gunakan menu Custom Func untuk menjalankan fungsi custom.",
      );
      return;
    }

    if (_selectedBugMode == "number") {
      final target = formatPhoneNumber(rawInput);
      if (target == null || key.isEmpty) {
        _showAlert(
          "❌ Invalid Number",
          "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.",
        );
        return;
      }
    } else {
      if (!isValidGroupLink(rawInput)) {
        _showAlert(
          "❌ Invalid Link",
          "Masukkan link group WA yang valid (contoh: https://chat.whatsapp.com/...).",
        );
        return;
      }
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      final uri = Uri.parse(
        "http://tirz.panel.jserver.web.id/:2001/sendBug",
      ).replace(
        queryParameters: {
          "key": key,
          "target": rawInput,
          "bug": selectedBugId,
          "sender": senderScope,
        },
      );
      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      final serverMessage = data["message"]?.toString().trim();

      if (data["cooldown"] == true) {
        final wait = data["wait"];
        final waitText = wait != null ? " (${wait}s)" : "";
        setState(() => _responseMessage = "⏳ Cooldown: Tunggu ${waitText}");
      } else if (data["valid"] == false) {
        setState(() => _responseMessage = "❌ Key Invalid: Silakan login ulang.");
      } else if (data["permission"] == false) {
        setState(() => _responseMessage = serverMessage?.isNotEmpty == true
            ? "⚠️ $serverMessage"
            : "⚠️ Kamu tidak memiliki izin.");
      } else if (data["sended"] == false) {
        setState(() => _responseMessage = serverMessage?.isNotEmpty == true
            ? "⚠️ $serverMessage"
            : "⚠️ Gagal: Server sedang maintenance.");
      } else {
        setState(() => _responseMessage = "✅ Berhasil mengirim bug!");
        targetController.clear();
      }
    } catch (_) {
      setState(() => _responseMessage = "❌ Error: Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: primaryNeon.withOpacity(0.5), width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.circle_notifications, color: primaryNeon, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          msg,
          style: const TextStyle(
            color: Color(0xFFB8B8D0),
            fontFamily: 'Inter',
            fontSize: 14,
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassMorphismCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryNeon.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHeaderPanel() {
    return _buildGlassMorphismCard(
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: primaryNeon.withOpacity(0.5 * _glowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage("assets/images/logo.png"),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => primaryGradient.createShader(bounds),
                  child: const Text(
                    "NOVA CRASHER",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "Poppins",
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Premium Attack System",
                  style: TextStyle(
                    color: textGrey,
                    fontFamily: "Inter",
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: secondaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.role.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return Container(
        width: double.infinity,
        height: 200,
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryNeon),
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryNeon.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: primaryNeon.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: Stack(
            children: [
              Chewie(controller: _chewieController),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, primaryNeon.withOpacity(0.2)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [secondaryNeon.withOpacity(0.2), primaryNeon.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primaryNeon.withOpacity(0.2), width: 1),
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(27),
        ),
        child: child,
      ),
    );
  }

  void _openCustomFunctionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomFunctionPage(
          username: widget.username,
          password: widget.password,
          sessionKey: widget.sessionKey,
          listBug: widget.listBug,
          role: widget.role,
          expiredDate: widget.expiredDate,
        ),
      ),
    );
  }

  Widget _buildCustomFuncPanel() {
    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.code_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "Custom Function",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Buat dan jalankan bug custom dengan function sendiri",
            style: TextStyle(
              color: textGrey,
              fontFamily: 'Inter',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryNeon.withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _openCustomFunctionPage,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              label: const Text(
                "OPEN CUSTOM FUNC",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontFamily: 'Poppins',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    Widget buildModeTile({
      required String mode,
      required IconData icon,
      required String label,
      VoidCallback? onTap,
    }) {
      final isActive = _selectedBugMode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: onTap ?? () {
            setState(() {
              _selectedBugMode = mode;
              targetController.clear();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: isActive ? primaryGradient : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? Colors.white : primaryNeon.withOpacity(0.3),
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isActive ? Colors.white : textGrey, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : textGrey,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildModeTile(mode: "number", icon: Icons.phone_android, label: "NOMOR"),
        const SizedBox(width: 12),
        buildModeTile(mode: "group", icon: Icons.group, label: "GROUP"),
        const SizedBox(width: 12),
        buildModeTile(
          mode: "custom",
          icon: Icons.code,
          label: "CUSTOM",
          onTap: () {
            setState(() {
              _selectedBugMode = "custom";
              targetController.clear();
            });
            _openCustomFunctionPage();
          },
        ),
      ],
    );
  }

  Widget _buildInputPanel() {
    final isCustom = _selectedBugMode == "custom";
    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBugMenuHeader(),
          const SizedBox(height: 20),
          _buildModeSelector(),
          const SizedBox(height: 24),
          if (isCustom) ...[
            _buildCustomFuncPanel(),
          ] else ...[
            _buildTargetInputField(),
            const SizedBox(height: 20),
            _buildBugSelectorCard(),
            const SizedBox(height: 20),
            _buildSenderScopeSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildBugMenuHeader() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: secondaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "ATTACK CONTROL",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryNeon.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "ACTIVE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedBugMode == "number" ? "TARGET NUMBER" : "GROUP LINK",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            fontFamily: 'Poppins',
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryNeon.withOpacity(0.2)),
          ),
          child: TextField(
            controller: targetController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: primaryNeon,
            keyboardType: _selectedBugMode == "number" ? TextInputType.phone : TextInputType.url,
            decoration: InputDecoration(
              hintText: _selectedBugMode == "number"
                  ? "+62xxxxxxxxxx"
                  : "https://chat.whatsapp.com/...",
              hintStyle: TextStyle(color: textGrey.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: primaryNeon.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: primaryNeon, width: 2),
              ),
              prefixIcon: Icon(
                _selectedBugMode == "number" ? Icons.phone : Icons.link,
                color: primaryNeon,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBugSelectorCard() {
    final selectedBug = widget.listBug.firstWhere(
      (b) => b['bug_id'] == selectedBugId,
      orElse: () => <String, dynamic>{'bug_name': '-', 'description': ''},
    );
    final selectedName = selectedBug['bug_name'].toString();
    final description = selectedBug['description']?.toString() ?? 'No description';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bug_report, color: primaryNeon, size: 18),
            const SizedBox(width: 8),
            const Text(
              "SELECT PAYLOAD",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFamily: 'Poppins',
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryNeon.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${widget.listBug.length} AVAILABLE",
                style: TextStyle(
                  color: primaryNeon,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryNeon.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF1A1A3A),
              value: selectedBugId,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: primaryNeon),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
              items: widget.listBug.map((bug) {
                return DropdownMenuItem<String>(
                  value: bug['bug_id'],
                  child: Text(bug['bug_name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBugId = value ?? "";
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: textGrey, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(color: textGrey, fontSize: 11, fontFamily: 'Inter'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSenderScopeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.send, color: primaryNeon, size: 18),
            const SizedBox(width: 8),
            const Text(
              "SENDER MODE",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFamily: 'Poppins',
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildScopeTile(
              scope: "private",
              icon: Icons.lock_outline,
              label: "PRIVATE",
              enabled: true,
            ),
            const SizedBox(width: 12),
            _buildScopeTile(
              scope: "global",
              icon: Icons.public,
              label: "GLOBAL",
              enabled: _canUseGlobalSender,
            ),
          ],
        ),
        if (!_canUseGlobalSender) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: warningOrange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: warningOrange, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Global sender khusus untuk member VIP & OWNER",
                    style: TextStyle(color: warningOrange, fontSize: 11, fontFamily: 'Inter'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScopeTile({
    required String scope,
    required IconData icon,
    required String label,
    required bool enabled,
  }) {
    final isActive = _selectedSenderScope == scope;
    return Expanded(
      child: GestureDetector(
        onTap: enabled
            ? () {
                setState(() {
                  _selectedSenderScope = scope;
                });
              }
            : () {
                _showAlert("Restricted", "Global sender hanya untuk VIP/OWNER");
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive && enabled ? primaryGradient : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive && enabled
                  ? Colors.white
                  : (enabled ? primaryNeon.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
              width: isActive && enabled ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? (isActive ? Colors.white : textGrey) : Colors.white38,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? (isActive ? Colors.white : textGrey) : Colors.white38,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: primaryGradient,
            boxShadow: [
              BoxShadow(
                color: primaryNeon.withOpacity(0.4 * _pulseController.value),
                blurRadius: 20 * _pulseController.value,
                spreadRadius: 2 * _pulseController.value,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendBug,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: _isSending
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        "EXECUTE ATTACK",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    if (_responseMessage!.startsWith('✅')) {
      bgColor = successGreen.withOpacity(0.1);
      borderColor = successGreen;
      textColor = successGreen;
      icon = Icons.check_circle;
    } else if (_responseMessage!.startsWith('❌')) {
      bgColor = errorRed.withOpacity(0.1);
      borderColor = errorRed;
      textColor = errorRed;
      icon = Icons.error;
    } else {
      bgColor = warningOrange.withOpacity(0.1);
      borderColor = warningOrange;
      textColor = warningOrange;
      icon = Icons.warning;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _responseMessage!,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: bgGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderPanel(),
                const SizedBox(height: 16),
                _buildVideoPlayer(),
                const SizedBox(height: 16),
                _buildInputPanel(),
                const SizedBox(height: 24),
                if (_selectedBugMode != "custom") ...[
                  _buildSendButton(),
                  _buildResponseMessage(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}