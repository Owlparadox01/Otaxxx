import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RiwayatPage extends StatefulWidget {
  final String sessionKey;
  final String role;

  const RiwayatPage({
    super.key,
    required this.sessionKey,
    required this.role,
  });

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  // --- TEMA WARNA UNGU ---
  final Color bgDark = const Color(0xFF070317);
  final Color primaryPurple = const Color(0xFF7A5CFF);
  final Color accentPurple = const Color(0xFF4DA3FF);
  final Color lightPurple = const Color(0xFF9CB7FF);
  final Color primaryWhite = Colors.white;
  final Color accentGrey = const Color(0xFFC7CEFF);
  final Color cardGlass = Colors.white.withOpacity(0.05);
  final Color borderGlass = Colors.white.withOpacity(0.1);

  List<ActivityModel> activities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    // Definisikan baseUrl di dalam fungsi (Local Variable)
    // Ganti dengan IP dan PORT server Anda
    const baseUrl = "http://tirz.panel.jserver.web.id:2001";

    try {
      // Request ke endpoint baru yang kita buat
      final response = await http.get(
        Uri.parse('$baseUrl/getMyActivity?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid']) {
          List<dynamic> rawList = data['activities'];

          setState(() {
            activities = rawList.map((item) {
              return ActivityModel(
                type: item['type'] ?? 'system',
                title: item['title'] ?? 'Aktivitas',
                description: item['description'] ?? '-',
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                    item['timestamp'] ?? DateTime.now().millisecondsSinceEpoch
                ),
              );
            }).toList();
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        print("Server Error: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching history: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text(
          "Riwayat Aktivitas",
          style: TextStyle(
            color: primaryWhite,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: primaryPurple.withOpacity(0.8),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgDark,
              primaryPurple.withOpacity(0.1),
              bgDark,
            ],
          ),
        ),
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4DA3FF),
          ),
        )
            : activities.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, size: 60, color: accentGrey),
              const SizedBox(height: 16),
              Text(
                "Belum ada aktivitas",
                style: TextStyle(color: accentGrey, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "Pastikan server aktif",
                style: TextStyle(color: accentGrey.withOpacity(0.6), fontSize: 12),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadActivities,
          color: accentPurple,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityCard(activity);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    Color iconColor;
    IconData iconData;
    String typeLabel;

    switch (activity.type) {
      case 'login':
        iconColor = const Color(0xFF4DA3FF);
        iconData = Icons.login_rounded;
        typeLabel = "LOGIN";
        break;
      case 'bug':
        iconColor = const Color(0xFF4DA3FF);
        iconData = Icons.bug_report_outlined;
        typeLabel = "ATTACK";
        break;
      case 'create':
        iconColor = const Color(0xFF4DA3FF);
        iconData = Icons.person_add_alt_1_rounded;
        typeLabel = "ACCOUNT";
        break;
      default:
        iconColor = accentGrey;
        iconData = Icons.info_outline;
        typeLabel = "SYSTEM";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGlass, width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withOpacity(0.3)),
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryPurple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: accentPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  activity.description,
                  style: TextStyle(
                    color: accentGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: accentGrey.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(activity.timestamp),
                      style: TextStyle(
                        color: accentGrey.withOpacity(0.7),
                        fontSize: 11,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityModel {
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;

  ActivityModel({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });
}





