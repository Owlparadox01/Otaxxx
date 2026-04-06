import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:torch_light/torch_light.dart';
import 'update_service.dart';

// Import halaman-halaman lain Anda
import 'nik_check.dart';
import 'admin_page.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'tools_gateway.dart';
import 'ddos_panel.dart';
import 'chat_public.dart';
import 'login_page.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final String telegramId;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.telegramId,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _pageController;
  late Animation<double> _pageAnimation;

  // State Variables
  late WebSocketChannel channel;
  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late String telegramId;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  String androidId = "unknown";
  File? _profileImage;
  VideoPlayerController? _menuVideoController;

  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();

  int onlineUsers = 0;
  int activeConnections = 0;
  List<Map<String, dynamic>> recentActivities = [];
  Offset? _quickMenuOffset;
  static const double _quickMenuSize = 58;
  static const double _quickMenuPadding = 12;
  bool _updateCheckInProgress = false;
  bool _apkUpdateInProgress = false;
  bool _flashlightOn = false;
  bool _isOnline = true;
  Timer? _networkTimer;
  bool _networkCheckInProgress = false;

  // Dynamic palette from global theme seed.
  Color bgDark = const Color(0xFF120A2B);
  Color primaryPurple = const Color(0xFF6B66A6);
  Color accentCyan = const Color(0xFFC7CEFF);
  Color accentPurple = const Color(0xFF8E24AA);
  Color primaryWhite = const Color(0xFFF4F6FF);
  Color glassBg = const Color(0x1A4DA3FF);
  Color glassBorder = const Color(0x264DA3FF);

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    telegramId = widget.telegramId;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    _pageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageAnimation = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOut,
    );
    _pageController.forward();
    _selectedPage = _buildNewsPage();

    _startNetworkMonitor();
    _initAndroidIdAndConnect();
    _loadProfileImage();
    _initMenuVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scheme = Theme.of(context).colorScheme;
    primaryPurple = scheme.primary;
    accentCyan = scheme.primary;
    bgDark = Color.alphaBlend(scheme.primary.withOpacity(0.22), scheme.surface);
    primaryWhite = scheme.onSurface;
    glassBg = Color.alphaBlend(
      scheme.primary.withOpacity(0.12),
      scheme.surfaceContainerHigh,
    );
    glassBorder = scheme.primary.withOpacity(0.45);
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  void _initMenuVideo() {
    try {
      _menuVideoController =
          VideoPlayerController.asset('assets/videos/landing.mp4')
            ..initialize().then((_) {
              setState(() {});
              _menuVideoController?.setLooping(true);
              _menuVideoController?.setVolume(0);
              _menuVideoController?.play();
            });
    } catch (e) {
      print("Video asset error: $e");
    }
  }

  void _startNetworkMonitor() {
    _checkNetworkStatus();
    _networkTimer?.cancel();
    _networkTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _checkNetworkStatus(),
    );
  }

  Future<void> _checkNetworkStatus() async {
    if (_networkCheckInProgress) return;
    _networkCheckInProgress = true;

    try {
      final online = await _probeOnline();
      if (!mounted) return;

      if (online != _isOnline) {
        setState(() {
          _isOnline = online;
        });

        if (!_isOnline) {
          _showOfflineSnack();
        } else {
          _showOnlineSnack();
        }
      }
    } finally {
      _networkCheckInProgress = false;
    }
  }

  Future<bool> _probeOnline() async {
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _initAndroidIdAndConnect() async {
    androidId = await _resolveDeviceId();
    _connectToWebSocket();
  }

  Future<String> _resolveDeviceId() async {
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
      if (Platform.isWindows) {
        final windows = await deviceInfo.windowsInfo;
        return windows.deviceId;
      }
      if (Platform.isMacOS) {
        final mac = await deviceInfo.macOsInfo;
        return mac.systemGUID ?? "mac_unknown_device";
      }
      if (Platform.isLinux) {
        final linux = await deviceInfo.linuxInfo;
        return linux.machineId ?? "linux_unknown_device";
      }
      return "unknown_device";
    } catch (_) {
      return "unknown_device";
    }
  }

  void _connectToWebSocket() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('wss://ws-dalangstore.my.id:8027'),
      );
      channel.sink.add(
        jsonEncode({
          "type": "validate",
          "key": sessionKey,
          "androidId": androidId,
        }),
      );
      channel.sink.add(jsonEncode({"type": "auth", "key": sessionKey}));
      channel.sink.add(jsonEncode({"type": "stats"}));

      channel.stream.listen((event) {
        final data = jsonDecode(event);
        if (data['type'] == 'myInfo') {
          if (data['valid'] == false) {
            if (data['reason'] == 'androidIdMismatch') {
              _handleInvalidSession("Account logged on another device.");
            } else if (data['reason'] == 'keyInvalid') {
              _handleInvalidSession("Key is not valid.");
            }
          }
        }
        if (data['type'] == 'stats') {
          setState(() {
            onlineUsers = data['onlineUsers'] ?? 0;
            activeConnections = data['activeConnections'] ?? 0;
          });
        }
        if (data['type'] == 'recentActivityInit') {
          final raw = (data['items'] as List?) ?? [];
          setState(() {
            recentActivities = raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          });
        }
        if (data['type'] == 'recentActivity' && data['data'] is Map) {
          final item = Map<String, dynamic>.from(data['data']);
          setState(() {
            recentActivities = [item, ...recentActivities].take(30).toList();
          });
        }
      });
    } catch (e) {
      print("WS Connection Error: $e");
    }
  }

  Future<void> _manualCheckUpdate() async {
    if (_updateCheckInProgress) return;
    if (kIsWeb || !Platform.isAndroid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Update Play Store hanya untuk Android."),
          backgroundColor: primaryPurple,
        ),
      );
      return;
    }

    _updateCheckInProgress = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (!mounted) return;

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        final shouldUpdate = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Update Tersedia"),
            content: const Text(
              "Versi baru tersedia di Play Store. Update sekarang?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Nanti"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Update"),
              ),
            ],
          ),
        );

        if (shouldUpdate == true) {
          if (info.immediateUpdateAllowed) {
            await InAppUpdate.performImmediateUpdate();
          } else if (info.flexibleUpdateAllowed) {
            await InAppUpdate.startFlexibleUpdate();
            await InAppUpdate.completeFlexibleUpdate();
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Aplikasi sudah versi terbaru."),
            backgroundColor: primaryPurple,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Gagal cek update. Coba lagi nanti."),
            backgroundColor: primaryPurple,
          ),
        );
      }
    } finally {
      _updateCheckInProgress = false;
    }
  }

  Future<void> _manualCheckApkUpdate() async {
    if (_apkUpdateInProgress) return;
    if (!Platform.isAndroid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Update APK hanya untuk Android."),
          backgroundColor: primaryPurple,
        ),
      );
      return;
    }

    _apkUpdateInProgress = true;
    try {
      final info = await UpdateService.fetchLatest();
      if (!mounted) return;

      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Update belum tersedia."),
            backgroundColor: primaryPurple,
          ),
        );
        return;
      }

      final available = await UpdateService.hasUpdate(info);
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Aplikasi sudah versi terbaru."),
            backgroundColor: primaryPurple,
          ),
        );
        return;
      }

      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Update APK Tersedia"),
          content: Text(
            [
              "Versi terbaru: ${info.version}",
              if (info.notes.trim().isNotEmpty) "Catatan: ${info.notes}",
              "Download update sekarang?",
            ].join("\n"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Nanti"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Download"),
            ),
          ],
        ),
      );

      if (shouldDownload != true) return;

      double progress = 0;
      bool dialogOpen = true;
      StateSetter? dialogSetState;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              dialogSetState = setDialogState;
              return AlertDialog(
                title: const Text("Downloading..."),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 12),
                    Text("${(progress * 100).toStringAsFixed(0)}%"),
                  ],
                ),
              );
            },
          );
        },
      ).then((_) => dialogOpen = false);

      final filePath = await UpdateService.downloadApk(
        info.url,
        onProgress: (p) {
          progress = p;
          if (dialogOpen) {
            dialogSetState?.call(() {});
          }
        },
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final shouldInstall = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Install Update"),
          content: const Text("APK sudah diunduh. Install sekarang?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Nanti"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Install"),
            ),
          ],
        ),
      );

      if (shouldInstall == true) {
        await UpdateService.installApk(filePath);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Gagal update APK. Coba lagi nanti."),
            backgroundColor: primaryPurple,
          ),
        );
      }
    } finally {
      _apkUpdateInProgress = false;
    }
  }

  Future<void> _toggleFlashlight() async {
    try {
      if (_flashlightOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      if (mounted) {
        setState(() {
          _flashlightOn = !_flashlightOn;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _flashlightOn ? "Senter dinyalakan" : "Senter dimatikan",
            ),
            backgroundColor: primaryPurple,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gagal mengakses senter di perangkat ini."),
          backgroundColor: primaryPurple,
        ),
      );
    }
  }

  void _showQuickMenuPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Quick Menu",
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return SafeArea(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildQuickMenuPopup(dialogContext),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildQuickMenuPopup(BuildContext dialogContext) {
    final height = MediaQuery.of(dialogContext).size.height;
    final maxHeight = height * 0.78;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 300, maxHeight: maxHeight),
        child: Container(
          padding: const EdgeInsets.all(1.4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryPurple.withOpacity(0.95),
                accentCyan.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: accentCyan.withOpacity(0.35),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: bgDark.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _buildQuickMenuHeader(),
                    Divider(color: Colors.white.withOpacity(0.08), height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        children: [
                          _buildPopupMenuItem(
                            dialogContext,
                            icon: Icons.home_rounded,
                            label: "Home",
                            isActive: _bottomNavIndex == 0,
                            onTap: () => _onBottomNavTapped(0),
                          ),
                          _buildPopupMenuItem(
                            dialogContext,
                            icon: FontAwesomeIcons.whatsapp,
                            label: "WhatsApp",
                            isActive: _bottomNavIndex == 1,
                            onTap: () => _onBottomNavTapped(1),
                          ),
                          _buildPopupMenuItem(
                            dialogContext,
                            icon: Icons.notifications_active_rounded,
                            label: "Info",
                            isActive: _bottomNavIndex == 2,
                            onTap: () => _onBottomNavTapped(2),
                          ),
                          _buildPopupMenuItem(
                            dialogContext,
                            icon: Icons.build_rounded,
                            label: "Tools",
                            isActive: _bottomNavIndex == 3,
                            onTap: () => _onBottomNavTapped(3),
                          ),
                          _buildPopupMenuItem(
                            dialogContext,
                            icon: Icons.public_rounded,
                            label: "Chat",
                            isActive: _bottomNavIndex == 4,
                            onTap: () => _onBottomNavTapped(4),
                          ),
                          const SizedBox(height: 10),
                          Divider(
                            color: Colors.white.withOpacity(0.08),
                            height: 1,
                          ),
                          const SizedBox(height: 10),
                          _buildPopupMenuItem(
                            dialogContext,
                            icon: Icons.lock_reset_rounded,
                            label: "Change Password",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangePasswordPage(
                                    username: username,
                                    sessionKey: sessionKey,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildPopupMenuItem(
                            dialogContext,
                            icon: Icons.bug_report_rounded,
                            label: "Bug Sender",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BugSenderPage(
                                    sessionKey: sessionKey,
                                    username: username,
                                    role: role,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildPopupMenuItem(
                            dialogContext,
                            icon: Icons.hub_rounded,
                            label: "Tools Gateway",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ToolsPage(
                                    sessionKey: sessionKey,
                                    userRole: role,
                                    username: username,
                                    listDoos: listDoos,
                                    deviceId: androidId,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildPopupMenuItem(
                            dialogContext,
                            icon: _flashlightOn
                                ? Icons.flashlight_on_rounded
                                : Icons.flashlight_off_rounded,
                            label: _flashlightOn
                                ? "Flashlight (ON)"
                                : "Flashlight (OFF)",
                            onTap: _toggleFlashlight,
                          ),
                          _buildPopupMenuItem(
                            dialogContext,
                            icon: Icons.system_update_alt_rounded,
                            label: "Update APK",
                            onTap: _manualCheckApkUpdate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMenuHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [primaryPurple, accentCyan]),
              boxShadow: [
                BoxShadow(color: accentCyan.withOpacity(0.3), blurRadius: 12),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.file(_profileImage!, fit: BoxFit.cover)
                      : const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentCyan.withOpacity(0.4)),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: accentCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.menu_rounded, color: accentCyan),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge() {
    final Color statusColor = _isOnline
        ? const Color(0xFF30D158)
        : const Color(0xFFFF453A);
    final String label = _isOnline ? "ONLINE" : "OFFLINE";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenuItem(
    BuildContext dialogContext, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(dialogContext).pop();
          if (enabled) {
            Future.microtask(onTap);
          } else {
            Future.microtask(_showOfflineSnack);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? accentCyan.withOpacity(0.16)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? accentCyan.withOpacity(0.6)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [primaryPurple, accentCyan]),
                ),
                child: Icon(
                  icon,
                  color: enabled ? Colors.white : Colors.white54,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: enabled
                        ? primaryWhite
                        : primaryWhite.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: enabled ? accentCyan : accentCyan.withOpacity(0.4),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfflineSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Koneksi offline. Beberapa fitur mungkin butuh internet.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF5B4CFF),
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showOnlineSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Koneksi kembali online. Semua menu aktif.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF30D158),
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showComingSoon() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Fitur ini akan segera hadir!")),
  );
}

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {}
  }

  void _handleInvalidSession(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF120A2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "⚠️ Session Expired",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text(
              "OK",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPage(int index) {
    _bottomNavIndex = index;
    _pageController.reset();
    _pageController.forward();

    if (index == 0) {
      _selectedPage = _buildNewsPage();
    } else if (index == 1) {
      _selectedPage = HomePage(
        username: username,
        password: password,
        listBug: listBug,
        role: role,
        expiredDate: expiredDate,
        sessionKey: sessionKey,
      );
    } else if (index == 2) {
      _selectedPage = InfoPage(sessionKey: sessionKey);
    } else if (index == 3) {
      _selectedPage = ToolsPage(
        sessionKey: sessionKey,
        userRole: role,
        username: username,
        listDoos: listDoos,
        deviceId: androidId,
      );
    } else if (index == 4) {
      _selectedPage = ChatPublicPage(
        username: username,
        role: role,
        apiKey: sessionKey,
        bottomSafeInset: 86,
      );
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectPage(index);
    });
  }

  void _onSidebarTabSelected(int index) {
    setState(() {
      if (index == 1) {
        _selectedPage = SellerPage(keyToken: sessionKey);
      } else if (index == 2) {
        _selectedPage = AdminPage(sessionKey: sessionKey);
      } else if (index == 3) {
        _selectedPage = OwnerPage(sessionKey: sessionKey, username: username);
      }
    });
    Navigator.pop(context);
  }

  // --- UI BUILDERS ---

  Widget _buildNewsPage() {
  Widget quickAction(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? accent,
    bool enabled = true,
  }) {
    final glow = (accent ?? accentCyan).withOpacity(0.6);
    return GestureDetector(
      onTap: enabled ? onTap : _showOfflineSnack,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (accent ?? accentCyan).withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(color: glow, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: glow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: primaryWhite, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryWhite.withOpacity(0.85),
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: primaryWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: primaryWhite.withOpacity(0.65),
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.only(bottom: 120),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========== FULL WIDTH BANNER LOGO (TANPA VIDEO) ==========
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: accentCyan.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gambar Logo Full Width
              Image.asset(
                'assets/images/logo.png',
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.3),
                      const Color(0xFF12071E).withOpacity(0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Content Overlay
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("🔥", style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          "OTAX SYSTEM",
                          style: TextStyle(
                            color: accentCyan,
                            fontSize: 22,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Premium Security & Tools Platform",
                      style: TextStyle(
                        color: primaryWhite.withOpacity(0.85),
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ========== QUICK ACCESS TOOLS - HORIZONTAL SCROLL ==========
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentCyan, accentPurple],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "QUICK ACCESS",
                    style: TextStyle(
                      color: primaryWhite,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _onBottomNavTapped(2);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentCyan.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "See All",
                            style: TextStyle(
                              color: accentCyan,
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, color: accentCyan, size: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Tool 1 - DDoS Panel
                    quickAction(
                      Icons.flash_on_rounded,
                      "DDoS",
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttackPanel(
                            sessionKey: sessionKey,
                            listDoos: listDoos,
                          ),
                        ),
                      ),
                      accent: const Color(0xFFFF5A5A),
                    ),
                    const SizedBox(width: 16),
                    
                    // Tool 2 - WhatsApp
                    quickAction(
                      FontAwesomeIcons.whatsapp,
                      "WhatsApp",
                      () => _onBottomNavTapped(1),
                      accent: const Color(0xFF4BE37A),
                    ),
                    const SizedBox(width: 16),
                    
                    // Tool 3 - Public Chat
                    quickAction(
                      Icons.chat_bubble_rounded,
                      "Chat",
                      () => _onBottomNavTapped(4),
                      accent: const Color(0xFF7CC5FF),
                    ),
                    const SizedBox(width: 16),
                    
                    // Tool 4 - Profile
                    quickAction(
                      Icons.manage_accounts_rounded,
                      "Account",
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            username: username,
                            password: password,
                            role: role,
                            expiredDate: expiredDate,
                            sessionKey: sessionKey,
                          ),
                        ),
                      ),
                      accent: const Color(0xFFB783FF),
                    ),
                    const SizedBox(width: 16),
                    
                    // Tool 5 - Bug Sender
                    quickAction(
                      FontAwesomeIcons.bug,
                      "Sender",
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BugSenderPage(
                            sessionKey: sessionKey,
                            username: username,
                            role: role,
                          ),
                        ),
                      ),
                      accent: const Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 16),
                    
                    // Tool 6 - Tools Hub
                    quickAction(
                      Icons.grid_view_rounded,
                      "Tools",
                      () => _onBottomNavTapped(2),
                      accent: const Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 16),
                    
                    // Tool 7 - Admin (if role is admin or owner)
                    if (role == 'admin' || role == 'owner')
                      quickAction(
                        Icons.admin_panel_settings_rounded,
                        "Admin",
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminPage(sessionKey: sessionKey),
                          ),
                        ),
                        accent: const Color(0xFFFF4081),
                      ),
                    const SizedBox(width: 16),
                    
                    // Tool 8 - Settings
                    quickAction(
                      Icons.settings_rounded,
                      "Settings",
                      () {
                        _showComingSoon();
                      },
                      accent: const Color(0xFF9E9E9E),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ========== TELEGRAM PROMO BANNER ==========
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () => _openUrl("https://t.me/XtremeRam2"),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B2CFF), Color(0xFFB64CFF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF7B2CFF).withOpacity(0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.telegram_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Join Telegram Channel",
                          style: TextStyle(
                            color: primaryWhite,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Get latest updates & premium tools",
                          style: TextStyle(
                            color: primaryWhite.withOpacity(0.85),
                            fontSize: 11,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // ========== SERVER STATS ==========
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.55),
                  const Color(0xFF1B0E2B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentCyan.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentCyan, accentPurple],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "SERVER STATISTICS",
                      style: TextStyle(
                        color: primaryWhite,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    statItem(
                      Icons.people_alt_rounded,
                      "Online Users",
                      onlineUsers.toString(),
                      const Color(0xFF7CC5FF),
                    ),
                    const SizedBox(width: 12),
                    statItem(
                      Icons.hub_rounded,
                      "Active Sender",
                      activeConnections.toString(),
                      const Color(0xFFB783FF),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // ========== RECENT ACTIVITIES ==========
        if (recentActivities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentCyan, accentPurple],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "RECENT ACTIVITY",
                      style: TextStyle(
                        color: primaryWhite,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recentActivities.take(4).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _activityTile(
                      e['title']?.toString() ?? "Activity",
                      _formatTimeAgo(e['at']?.toString()),
                      subtitle: "${e['username'] ?? '-'} • ${e['detail'] ?? ''}",
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 18),

        // ========== NEWS & UPDATES ==========
        if (newsList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentCyan, accentPurple],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "NEWS & UPDATES",
                      style: TextStyle(
                        color: primaryWhite,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: newsList.first['image'] != null &&
                                newsList.first['image'].toString().isNotEmpty
                            ? Image.network(
                                newsList.first['image'].toString(),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 160,
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported, color: Colors.white54),
                                    ),
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/images/logo.png',
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        newsList.first['title']?.toString() ?? "System Update",
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        newsList.first['description']?.toString() ?? 
                        "Latest system updates and features",
                        style: TextStyle(
                          color: primaryWhite.withOpacity(0.7),
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // ========== OPEN SENDER BUTTON ==========
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildModernBtn(
            "OPEN BUG SENDER",
            FontAwesomeIcons.bug,
            primaryPurple,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BugSenderPage(
                    sessionKey: sessionKey,
                    username: username,
                    role: role,
                  ),
                ),
              );
            },
            isGradient: true,
          ),
        ),

        const SizedBox(height: 30),
      ],
    ),
  );
}

  String _formatTimeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return "-";
    final dt = DateTime.tryParse(iso);
    if (dt == null) return "-";
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  Offset _clampQuickMenuOffset(
    Offset raw,
    BoxConstraints constraints,
    EdgeInsets safePadding,
  ) {
    final maxX =
        constraints.maxWidth -
        _quickMenuSize -
        _quickMenuPadding -
        safePadding.right;
    final maxY =
        constraints.maxHeight -
        _quickMenuSize -
        _quickMenuPadding -
        safePadding.bottom;
    final minX = _quickMenuPadding + safePadding.left;
    final minY = _quickMenuPadding + safePadding.top;

    return Offset(raw.dx.clamp(minX, maxX), raw.dy.clamp(minY, maxY));
  }

  Widget _activityTile(String title, String timeAgo, {String? subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: glassBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: primaryWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: const Color(0xFFC7CEFF), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBtn(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isGradient = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isGradient
              ? LinearGradient(colors: [primaryPurple, accentCyan])
              : null,
          color: isGradient ? null : glassBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGradient ? Colors.transparent : glassBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DRAWER & MENU ITEMS ---
  Widget _buildCustomDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Container(
        decoration: BoxDecoration(
          color: bgDark.withOpacity(0.95),
          border: Border(right: BorderSide(color: glassBorder)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 30,
                left: 20,
                right: 20,
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [primaryPurple, accentCyan],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                        child: ClipOval(
                          child: _profileImage != null
                              ? Image.file(_profileImage!, fit: BoxFit.cover)
                              : const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    username,
                    style: TextStyle(
                      color: primaryWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        color: accentCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  if (role == "reseller")
                    _buildDrawerItem(
                      FontAwesomeIcons.store,
                      "Seller Panel",
                      () => _onSidebarTabSelected(1),
                    ),
                  if (role == "admin")
                    _buildDrawerItem(
                      FontAwesomeIcons.userShield,
                      "Admin Panel",
                      () => _onSidebarTabSelected(2),
                    ),
                  if (role == "owner")
                    _buildDrawerItem(
                      FontAwesomeIcons.crown,
                      "OTAX Owner",
                      () => _onSidebarTabSelected(3),
                    ),
                  _buildDrawerItem(
                    FontAwesomeIcons.clockRotateLeft,
                    "History",
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RiwayatPage(sessionKey: sessionKey, role: role),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(FontAwesomeIcons.code, "Report Bug", () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BugSenderPage(
                          sessionKey: sessionKey,
                          username: username,
                          role: role,
                        ),
                      ),
                    );
                  }),
                  _buildDrawerItem(
                    FontAwesomeIcons.rightFromBracket,
                    "Log Out",
                    () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    isDanger: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDanger = false,
    bool enabled = true,
  }) {
    final baseColor = isDanger ? const Color(0xFF5B4CFF) : accentCyan;
    final textColor = isDanger ? const Color(0xFF5B4CFF) : primaryWhite;
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? baseColor : baseColor.withOpacity(0.4),
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: enabled ? textColor : textColor.withOpacity(0.5),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: enabled ? onTap : _showOfflineSnack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black.withOpacity(0.1),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            "${role.toUpperCase()} PANEL",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildConnectionBadge(),
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.headset, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ContactPage()),
              );
            },
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    username: username,
                    password: password,
                    role: role,
                    expiredDate: expiredDate,
                    sessionKey: sessionKey,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 15),
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentCyan),
                image: _profileImage != null
                    ? DecorationImage(
                        image: FileImage(_profileImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileImage == null
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ],
      ),
      drawer: _buildCustomDrawer(),
      endDrawer: _buildQuickNavDrawer(),
      endDrawerEnableOpenDragGesture: true,

      body: LayoutBuilder(
        builder: (context, constraints) {
          final safePadding = MediaQuery.of(context).padding;
          final defaultOffset = Offset(
            constraints.maxWidth - _quickMenuSize - 18 - safePadding.right,
            constraints.maxHeight - _quickMenuSize - 26 - safePadding.bottom,
          );
          final effectiveOffset = _clampQuickMenuOffset(
            _quickMenuOffset ?? defaultOffset,
            constraints,
            safePadding,
          );

          return Stack(
            children: [
              // Background
              Positioned.fill(child: Container(color: Colors.black)),

              // Content
              SafeArea(
                child: FadeTransition(
                  opacity: _pageAnimation,
                  child: _selectedPage,
                ),
              ),

              // Draggable quick button -> open right popup menu.
              Positioned(
                left: effectiveOffset.dx,
                top: effectiveOffset.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final next = _clampQuickMenuOffset(
                      effectiveOffset + details.delta,
                      constraints,
                      safePadding,
                    );
                    setState(() {
                      _quickMenuOffset = next;
                    });
                  },
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _showQuickMenuPopup,
                    child: Container(
                      width: _quickMenuSize,
                      height: _quickMenuSize,
                      decoration: BoxDecoration(
                        color: glassBg,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: glassBorder, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.menu_open_rounded,
                            color: accentCyan,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickNavDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.63,
      child: Container(
        decoration: BoxDecoration(
          color: bgDark.withOpacity(0.94),
          border: Border(left: BorderSide(color: glassBorder)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  "QUICK NAV",
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildQuickNavItem(Icons.home_rounded, "Home", 0),
                    _buildQuickNavItem(FontAwesomeIcons.whatsapp, "Sender", 1),
                    _buildQuickNavItem(
                      Icons.notifications_active_rounded,
                      "Info",
                      2,
                    ),
                    _buildQuickNavItem(Icons.build_rounded, "Tools", 3),
                    _buildQuickNavItem(Icons.public_rounded, "Chat", 4),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNavItem(
    IconData icon,
    String label,
    int index, {
    bool enabled = true,
  }) {
    final bool isSelected = _bottomNavIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pop(context);
          if (enabled) {
            _onBottomNavTapped(index);
          } else {
            _showOfflineSnack();
          }
        },
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.12)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? accentCyan.withOpacity(0.6)
                    : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? accentCyan : Colors.white70,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? accentCyan : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, int index) {
    final bool isSelected = _bottomNavIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.white.withOpacity(0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? accentCyan.withOpacity(0.6)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? accentCyan : Colors.white70,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? accentCyan : Colors.white70,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    _networkTimer?.cancel();
    _pageController.dispose();
    _menuVideoController?.dispose();
    if (_flashlightOn) {
      TorchLight.disableTorch();
    }
    super.dispose();
  }
}

// --- BACKGROUND ANIMATION ---
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BackgroundPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animationValue;
  _BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Color(0xFF4DA3FF).withOpacity(0.05);
    final centers = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.9),
    ];

    for (int i = 0; i < centers.length; i++) {
      final offset = (animationValue + i / 3) % 1.0;
      final yShift = math.sin(offset * math.pi * 2) * 60;
      final radius = 120 + math.sin(offset * math.pi * 2 + i) * 40;
      canvas.drawCircle(
        Offset(centers[i].dx, centers[i].dy + yShift),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- NEWS MEDIA WIDGET ---
class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(0.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) {
    return url.endsWith(".mp4") ||
        url.endsWith(".webm") ||
        url.endsWith(".mov") ||
        url.endsWith(".mkv");
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4DA3FF)),
        );
      }
    } else {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF2A2A4E),
          child: const Icon(Icons.error, color: Colors.white),
        ),
      );
    }
  }
}
