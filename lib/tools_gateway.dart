import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'telegram.dart';
import 'spyware.dart';
import 'ip_scanner_page.dart';
import 'port_scanner_page.dart';
import 'worm_game_page.dart';
import 'rat_page.dart' as rat_tools;
import 'owner_page.dart' as owner_pages;
import 'camera.dart';
import 'link_page.dart';
import 'pengecek.dart';
import 'report_page.dart';
import 'quick_access_page.dart';
import 'Remote_Control.dart';
import 'phone_lookup.dart';
import 'spotify.dart';
import 'theme_tools_page.dart';

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final String username;
  final String deviceId;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.username,
    required this.deviceId,
    required this.listDoos,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _fadeAnimation;

  // Premium Color Palette
  late Color primaryDark;
  late Color primaryNeon;
  late Color secondaryNeon;
  late Color accentPink;
  late Color surfaceColor;
  late Color textPrimary;
  late Color textSecondary;
  late Color cardColor;
  Color primaryWhite = Colors.white;
  Color primaryPurple = const Color(0xFF6B66A6);


  final Map<String, List<Map<String, dynamic>>> _toolsData = {
    'DDoS': [
      {'icon': Icons.flash_on_rounded, 'label': 'Attack Panel', 'route': 'ddos_panel', 'color': 0xFFFF4081},
      {'icon': Icons.dns_rounded, 'label': 'Manage Server', 'route': 'manage_server', 'color': 0xFF00E5FF},
    ],
    'Network': [
      {'icon': Icons.telegram_rounded, 'label': 'TG Spam', 'route': 'telegram', 'color': 0xFF0088CC},
      {'icon': Icons.message_rounded, 'label': 'Spam NGL', 'route': 'ngl', 'color': 0xFF00E676},
      {'icon': Icons.wifi_off_rounded, 'label': 'WiFi Killer', 'route': 'wifi_internal', 'color': 0xFFFF5252},
      {'icon': Icons.security_rounded, 'label': 'Spyware', 'route': 'spyware', 'color': 0xFF7C4DFF},
      {'icon': Icons.shield_rounded, 'label': 'RAT Control', 'route': 'rat_page', 'color': 0xFFFF4081},
      {'icon': Icons.router_rounded, 'label': 'WiFi Ext', 'route': 'wifi_external', 'vip': true, 'color': 0xFF00BCD4},
      // ✅ MENU WIFI AUTO CRACKER DITAMBAHKAN DI SINI
      {'icon': Icons.wifi_lock_rounded, 'label': 'WiFi Auto Cracker', 'route': 'wifi_cracker', 'color': 0xFF00BCD4},
    ],
    'OSINT': [
      {'icon': Icons.badge_rounded, 'label': 'NIK Detail', 'route': 'nik_check', 'color': 0xFF2196F3},
      {'icon': Icons.domain_rounded, 'label': 'Domain OSINT', 'route': 'domain_page', 'color': 0xFF673AB7},
    ],
    'Downloader': [
      {'icon': Icons.video_library_rounded, 'label': 'TikTok', 'route': 'tiktok', 'color': 0xFF000000},
      {'icon': Icons.camera_alt_rounded, 'label': 'Instagram', 'route': 'instagram', 'color': 0xFFE1306C},
    ],
    'Utilities': [
      {'icon': Icons.qr_code_rounded, 'label': 'QR Generator', 'route': 'qr_gen', 'color': 0xFF00BCD4},
      {'icon': Icons.sync_rounded, 'label': 'IP Scanner', 'route': 'ip_scanner', 'color': 0xFF4CAF50},
      {'icon': Icons.settings_ethernet_rounded, 'label': 'Port Scanner', 'route': 'port_scanner', 'color': 0xFFFF9800},
      {'icon': Icons.camera_alt_rounded, 'label': 'Camera Tool', 'route': 'camera_tool', 'color': 0xFF9C27B0},
      {'icon': Icons.link_rounded, 'label': 'Link Tools', 'route': 'link_page', 'color': 0xFF00E5FF},
      {'icon': Icons.gpp_good_rounded, 'label': 'Pengecek Link', 'route': 'pengecek', 'color': 0xFF4CAF50},
      {'icon': Icons.campaign_rounded, 'label': 'Report', 'route': 'report_page', 'color': 0xFFFF5252},
      {'icon': Icons.settings_remote_rounded, 'label': 'Remote Control', 'route': 'remote_control', 'color': 0xFF7C4DFF},
      {'icon': Icons.phone_in_talk_rounded, 'label': 'Phone Lookup', 'route': 'phone_lookup', 'color': 0xFF00BCD4},
      {'icon': Icons.music_note_rounded, 'label': 'Spotify', 'route': 'spotify', 'color': 0xFF1DB954},
    ],
    'Game': [
      {'icon': Icons.bug_report_rounded, 'label': 'Worm Game', 'route': 'worm_game', 'color': 0xFF00E676},
    ],
    'Quick': [
      {'icon': Icons.manage_accounts_rounded, 'label': 'Quick Access', 'route': 'quick_access', 'ownerOnly': true, 'color': 0xFFFF4081},
    ],
    'Theme': [
      {'icon': Icons.palette_rounded, 'label': 'Theme Color', 'route': 'theme_tools', 'color': 0xFF9C27B0},
    ],
  };

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scheme = Theme.of(context).colorScheme;
    primaryDark = const Color(0xFF0A0A1A);
    primaryNeon = const Color(0xFF00E5FF);
    secondaryNeon = const Color(0xFF7C4DFF);
    accentPink = const Color(0xFFFF4081);
    surfaceColor = const Color(0xFF12122A);
    textPrimary = Colors.white;
    textSecondary = const Color(0xFFB8B8D0);
    cardColor = const Color(0xCC16163A);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _toolsData.keys
        .where((c) => _getVisibleItems(c).isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: primaryDark,
      body: Container(
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
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryCard(category);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            secondaryNeon.withOpacity(0.15),
            primaryNeon.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: primaryNeon.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryNeon, secondaryNeon],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryNeon.withOpacity(0.4),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [primaryNeon, secondaryNeon],
                      ).createShader(bounds),
                      child: const Text(
                        "TOOLS HUB",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Premium Security Tools Collection",
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryNeon.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryNeon.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryNeon,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryNeon,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.userRole.toUpperCase(),
                      style: TextStyle(
                        color: primaryNeon,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: textSecondary, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Tap on any category to explore available tools",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'DDoS':
        return Icons.flash_on_rounded;
      case 'Network':
        return Icons.wifi_tethering_rounded;
      case 'OSINT':
        return Icons.travel_explore_rounded;
      case 'Downloader':
        return Icons.download_for_offline_rounded;
      case 'Utilities':
        return Icons.widgets_rounded;
      case 'Game':
        return Icons.sports_esports_rounded;
      case 'Quick':
        return Icons.rocket_launch_rounded;
      case 'Theme':
        return Icons.palette_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  List<Color> _getGradientColors(String category) {
    switch (category) {
      case 'DDoS':
        return [const Color(0xFFFF4081), const Color(0xFF7C4DFF)];
      case 'Network':
        return [const Color(0xFF00E5FF), const Color(0xFF7C4DFF)];
      case 'OSINT':
        return [const Color(0xFF2196F3), const Color(0xFF673AB7)];
      case 'Downloader':
        return [const Color(0xFF00E676), const Color(0xFF00BCD4)];
      case 'Utilities':
        return [const Color(0xFFFF9800), const Color(0xFFFF4081)];
      case 'Game':
        return [const Color(0xFF4CAF50), const Color(0xFF00E676)];
      case 'Quick':
        return [const Color(0xFF7C4DFF), const Color(0xFFFF4081)];
      case 'Theme':
        return [const Color(0xFF9C27B0), const Color(0xFFE91E63)];
      default:
        return [primaryNeon, secondaryNeon];
    }
  }

  List<Map<String, dynamic>> _getVisibleItems(String category) {
    final items = _toolsData[category] ?? [];
    return items.where((item) {
      if (item['vip'] == true &&
          widget.userRole != 'vip' &&
          widget.userRole != 'owner') {
        return false;
      }
      if (item['ownerOnly'] == true && widget.userRole != 'owner') {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildCategoryCard(String category) {
    final icon = _categoryIcon(category);
    final gradientColors = _getGradientColors(category);
    final totalTools = _getVisibleItems(category).length;
    
    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_fadeAnimation.value * 0.02),
            child: GestureDetector(
              onTap: () => _showCategoryModal(category),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradientColors[0].withOpacity(0.15),
                      gradientColors[1].withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: gradientColors[0].withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              gradientColors[0].withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradientColors,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradientColors[0].withOpacity(0.4),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Icon(icon, color: Colors.white, size: 22),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: gradientColors[0].withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  "$totalTools",
                                  style: TextStyle(
                                    color: gradientColors[0],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 40,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradientColors),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${_getVisibleItems(category).length} tools available",
                            style: TextStyle(
                              color: textSecondary.withOpacity(0.7),
                              fontSize: 10,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCategoryModal(String category) {
    final visibleItems = _getVisibleItems(category);
    final gradientColors = _getGradientColors(category);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: const Color(0xFF12122A),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          border: Border.all(
            color: gradientColors[0].withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradientColors),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_categoryIcon(category), color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${visibleItems.length} premium tools",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.close, color: textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visibleItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: textSecondary,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No tools available",
                            style: TextStyle(
                              color: textSecondary,
                              fontFamily: 'Inter',
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Upgrade your role to access more tools",
                            style: TextStyle(
                              color: textSecondary.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: visibleItems.length,
                      itemBuilder: (context, index) {
                        final item = visibleItems[index];
                        return _buildModalListItem(item, gradientColors);
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModalListItem(Map<String, dynamic> item, List<Color> gradientColors) {
    final itemColor = Color(item['color'] ?? gradientColors[0]);
    
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _navigateToTool(item['route']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: itemColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: itemColor.withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [itemColor, itemColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: itemColor.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(item['icon'], color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (item['vip'] == true || item['ownerOnly'] == true) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: itemColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: itemColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              item['ownerOnly'] == true ? "OWNER ONLY" : "VIP",
                              style: TextStyle(
                                color: itemColor,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: itemColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: itemColor,
                      size: 14,
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

  void _navigateToTool(String route) {
  Widget? page;

  switch (route) {
    case 'ddos_panel':
      page = AttackPanel(
        sessionKey: widget.sessionKey,
        listDoos: widget.listDoos,
      );
      break;
    case 'manage_server':
      page = ManageServerPage(keyToken: widget.sessionKey);
      break;
    case 'wifi_internal':
      page = WifiKillerPage();
      break;
    case 'wifi_external':
      page = WifiInternalPage(sessionKey: widget.sessionKey);
      break;
    case 'telegram':
      page = TelegramSpamPage(sessionKey: widget.sessionKey);
      break;
    case 'ngl':
      page = NglPage();
      break;
    case 'spyware':
      page = SpywarePage(sessionKey: widget.sessionKey);
      break;
    case 'nik_check':
      page = const NikCheckerPage();
      break;
    case 'domain_page':
      page = const DomainOsintPage();
      break;
    case 'tiktok':
      page = const TiktokDownloaderPage();
      break;
    case 'instagram':
      page = const InstagramDownloaderPage();
      break;
    case 'qr_gen':
      page = const QrGeneratorPage();
      break;
    case 'ip_scanner':
      page = const IpScannerPage();
      break;
    case 'port_scanner':
      page = const PortScannerPage();
      break;
    case 'worm_game':
      page = const WormGamePage();
      break;
    case 'rat_page':
      page = rat_tools.OwnerPage(
        sessionKey: widget.sessionKey,
        username: widget.username,
      );
      break;
    case 'camera_tool':
      page = CameraToolPage(
        sessionKey: widget.sessionKey,
        username: widget.username,
      );
      break;
    case 'link_page':
      page = const LinkPage();
      break;
    case 'pengecek':
      page = PengecekPage(sessionKey: widget.sessionKey);
      break;
    case 'report_page':
      page = ReportPage(
        sessionKey: widget.sessionKey,
        username: widget.username,
      );
      break;
    case 'quick_access':
      page = QuickAccessPage(sessionKey: widget.sessionKey);
      break;
    case 'remote_control':
      page = RemoteControlPage(
        deviceId: widget.deviceId,
        deviceName: widget.username,
      );
      break;
    case 'phone_lookup':
      page = PhoneLookupPage(sessionKey: widget.sessionKey);
      break;
    case 'spotify':
      page = SpotifyPage(sessionKey: widget.sessionKey);
      break;
    case 'theme_tools':
      page = const ThemeToolsPage();
      break;
    // ✅ TAMBAHKAN CASE UNTUK WIFI CRACKER
    case 'wifi_cracker':
      page = const WiFiCrackerScreen(); // Pastikan class di WiFiCrackerV2.dart bernama WiFiCrackerScreen
      break;
  }

  if (page != null) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
  }
}

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.hourglass_top, color: primaryWhite),
            const SizedBox(width: 8),
            Text(
              'Feature Coming Soon!',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                color: primaryWhite,
              ),
            ),
          ],
        ),
        backgroundColor: primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}




