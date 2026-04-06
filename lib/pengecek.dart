import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PengecekPage extends StatefulWidget {
  final String sessionKey;

  const PengecekPage({super.key, required this.sessionKey});

  @override
  State<PengecekPage> createState() => _PengecekPageState();
}

class _PengecekPageState extends State<PengecekPage> {
  static const String _baseUrl = "http://tirz.panel.jserver.web.id:2001";
  final TextEditingController _urlController = TextEditingController();

  bool _loading = false;
  Map<String, dynamic>? _result;
  String _error = "";

  Future<void> _scanUrl() async {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _loading = true;
      _error = "";
      _result = null;
    });

    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/api/tools/link/scan"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "key": widget.sessionKey,
          "url": raw,
          "ts": DateTime.now().toIso8601String(),
        }),
      );
      Map<String, dynamic> data = {};
      try {
        data = (jsonDecode(res.body) as Map<String, dynamic>);
      } catch (_) {
        data = {"ok": false, "message": "Respons server tidak valid"};
      }
      if (res.statusCode >= 400 || data["ok"] != true) {
        final isWebCors =
            data["message"]?.toString().toLowerCase().contains("xmlhttprequest") == true;
        setState(
          () => _error = isWebCors
              ? "Request diblokir browser (CORS). Pastikan API mengizinkan origin web."
              : (data["message"]?.toString() ?? "Gagal scan link."),
        );
      } else {
        setState(() => _result = data);
      }
    } catch (e) {
      setState(() => _error = "Error koneksi: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "safe":
        return const Color(0xFF4F8BFF);
      case "suspicious":
        return const Color(0xFF6B8CFF);
      case "danger":
        return const Color(0xFF7A5CFF);
      default:
        return const Color(0xFF6B66A6);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = (_result?["status"] ?? "unknown").toString();
    final reasons = (_result?["reasons"] as List?)?.cast<String>() ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text("Pengecek Link Anti-Ransom")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: "URL target",
                hintText: "https://example.com",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _scanUrl,
                icon: const Icon(Icons.security),
                label: Text(_loading ? "Scanning..." : "Scan Link"),
              ),
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: const Color(0xFF5B4CFF))),
            if (_result != null) ...[
              Row(
                children: [
                  const Text("Status: "),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _statusColor(status)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("Risk Score: ${_result?["riskScore"] ?? 0}/100"),
              const SizedBox(height: 8),
              Text("Host: ${_result?["host"] ?? "-"}"),
              const SizedBox(height: 8),
              const Text("Alasan deteksi:"),
              const SizedBox(height: 6),
              if (reasons.isEmpty) const Text("- Tidak ada indikator berbahaya."),
              ...reasons.map((e) => Text("- $e")),
            ],
          ],
        ),
      ),
    );
  }
}







