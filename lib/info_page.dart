import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InfoPage extends StatefulWidget {
  final String sessionKey;

  const InfoPage({super.key, required this.sessionKey});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  // --- State Data ---
  Map<String, dynamic>? serverInfo;
  bool isLoading = true;

  // API Status State
  bool isApiOnline = false;
  int apiPingMs = 0;
  Color apiStatusColor = const Color(0xFF6B66A6);
  String apiStatusText = "Checking...";
  Timer? _pingTimer;

  // --- TEMA WARNA UNGU (Consistent) ---
  final Color bgDark = const Color(0xFF070317);
  final Color primaryPurple = const Color(0xFF7A5CFF);
  final Color accentPurple = const Color(0xFF4DA3FF);
  final Color primaryWhite = Colors.white;
  final Color textGrey = const Color(0xFFC7CEFF);
  final Color cardGlass = Colors.white.withOpacity(0.05);
  final Color borderGlass = Colors.white.withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    _fetchServerInfo(); // Fetch info (optional logic if needed later)
    _startApiPingLoop();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  // Fetch data config dari server (Disimpan untuk logic server status)
  Future<void> _fetchServerInfo() async {
    try {
      final res = await http.get(
        Uri.parse(
          'http://tirz.panel.jserver.web.id/:2001/getServerInfo?key=${widget.sessionKey}',
        ),
      );
      if (res.statusCode == 200) {
        setState(() {
          serverInfo = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Loop Ping API setiap 5 detik
  void _startApiPingLoop() {
    _checkApiPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkApiPing();
    });
  }

  Future<void> _checkApiPing() async {
    final start = DateTime.now();
    try {
      final res = await http
          .get(
            Uri.parse(
              'http://tirz.panel.jserver.web.id/:2001/ping?key=${widget.sessionKey}',
            ),
          )
          .timeout(const Duration(seconds: 3));

      final end = DateTime.now();
      final duration = end.difference(start).inMilliseconds;

      if (res.statusCode == 200) {
        setState(() {
          isApiOnline = true;
          apiPingMs = duration;
          if (duration < 200) {
            apiStatusColor = const Color(0xFF4DA3FF);
          } else if (duration < 500) {
            apiStatusColor = const Color(0xFF70B4FF);
          } else {
            apiStatusColor = const Color(0xFF4DA3FF);
          }
          apiStatusText = "Online (${duration}ms)";
        });
      } else {
        throw Exception("Failed");
      }
    } catch (e) {
      setState(() {
        isApiOnline = false;
        apiPingMs = 0;
        apiStatusColor = const Color(0xFF5B4CFF);
        apiStatusText = "Offline";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jika loading server info tampilkan loader
    if (isLoading) {
      return Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text("Info", style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4DA3FF)),
        ),
      );
    }

    // Data Peraturan
    final List<Map<String, String>> rulesList = [
      {
        "title": "Larangan Barter Akun",
        "desc":
            "Akun tidak boleh ditukar dengan barang, jasa, atau akun lain dalam bentuk apa pun.",
      },
      {
        "title": "Larangan Membagikan Akun",
        "desc":
            "Setiap akun bersifat pribadi dan hanya boleh digunakan oleh pemilik akun yang terdaftar.",
      },
      {
        "title": "Larangan Menjual Akun",
        "desc":
            "Member TIDAK diperbolehkan menjual akun. Penjualan akun hanya boleh dilakukan oleh role yang diizinkan secara resmi.",
      },
      {
        "title": "Larangan Jual Durasi Ilegal",
        "desc":
            "Dilarang menjual akses harian, mingguan, trial, atau sejenisnya di luar ketentuan yang telah ditetapkan.",
      },
      {
        "title": "Larangan Banting Harga",
        "desc":
            "Dilarang merusak atau menurunkan harga yang telah ditentukan (banting harga) di bawah ketentuan OTAX.",
      },
    ];

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "PERATURAN & INFO",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. API STATUS (Compact di atas)
            _buildCompactApiStatus(),

            const SizedBox(height: 20),

            // 2. HEADER PERATURAN
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.gavel,
                    color: Color(0xFF4DA3FF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "PERATURAN PENGGUNA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. LIST PERATURAN
            ...rulesList.asMap().entries.map((entry) {
              int index = entry.key + 1;
              Map<String, String> rule = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardGlass,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderGlass),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentPurple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: accentPurple.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              "Rule $index",
                              style: TextStyle(
                                color: accentPurple,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rule['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rule['desc']!,
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // 4. SANKSI (Red Warning Box)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF7A5CFF).withOpacity(0.1),
                    Color(0xFF7A5CFF).withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(0xFF5B4CFF).withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF5B4CFF).withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFF5B4CFF),
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "SANKSI",
                        style: TextStyle(
                          color: const Color(0xFF5B4CFF),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Jika pengguna terbukti melanggar salah satu peraturan di atas:",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Akun akan DIHAPUS secara permanen 🚫",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Tanpa pengembalian akun, saldo, atau kompensasi apa pun ‼️",
                    style: TextStyle(
                      color: const Color(0xFF5B4CFF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. FOOTER DISCLAIMER
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shield_moon_rounded,
                    color: accentPurple,
                    size: 30,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Peraturan ini dibuat untuk menjaga keamanan, kenyamanan, dan kestabilan ekosistem OTAX App. Dengan menggunakan aplikasi ini, pengguna dianggap telah menyetujui seluruh peraturan di atas.",
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 4,
                    width: 100,
                    decoration: BoxDecoration(
                      color: accentPurple,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactApiStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGlass),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: apiStatusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: apiStatusColor.withOpacity(0.5),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "System Status: ${apiStatusText.toUpperCase()}",
            style: TextStyle(
              color: textGrey,
              fontSize: 13,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ],
      ),
    );
  }
}
