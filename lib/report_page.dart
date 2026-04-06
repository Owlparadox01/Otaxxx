import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReportPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const ReportPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  static const List<String> _endpoints = [
    "http://tirz.panel.jserver.web.id:2001/api/report",
    "http://tirz.panel.jserver.web.id:2001/api/report",
  ];
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _detailCtrl = TextEditingController();
  String _severity = "normal";
  bool _sending = false;
  String _msg = "";

  Future<void> _sendReport() async {
    final title = _titleCtrl.text.trim();
    final detail = _detailCtrl.text.trim();
    if (title.isEmpty || detail.isEmpty) {
      setState(() => _msg = "Judul dan detail wajib diisi.");
      return;
    }

    setState(() {
      _sending = true;
      _msg = "";
    });

    try {
      http.Response? successRes;
      Map<String, dynamic> successData = {};

      for (final endpoint in _endpoints) {
        try {
          final res = await http
              .post(
                Uri.parse(endpoint),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "key": widget.sessionKey,
                  "username": widget.username,
                  "title": title,
                  "detail": detail,
                  "severity": _severity,
                  "ts": DateTime.now().toIso8601String(),
                }),
              )
              .timeout(const Duration(seconds: 10));

          Map<String, dynamic> data = {};
          try {
            data = jsonDecode(res.body) as Map<String, dynamic>;
          } catch (_) {}

          if (res.statusCode >= 200 && res.statusCode < 300 && data["ok"] == true) {
            successRes = res;
            successData = data;
            break;
          }
        } catch (_) {
          // Try next endpoint.
        }
      }

      if (successRes != null && successData["ok"] == true) {
        setState(() => _msg = "Laporan terkirim ke bot admin.");
        _titleCtrl.clear();
        _detailCtrl.clear();
      } else {
        setState(() => _msg = "Gagal kirim laporan. Coba lagi.");
      }
    } catch (e) {
      setState(() => _msg = "Error koneksi: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Bug")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: "Judul Laporan",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _severity,
              decoration: const InputDecoration(
                labelText: "Level",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "low", child: Text("Low")),
                DropdownMenuItem(value: "normal", child: Text("Normal")),
                DropdownMenuItem(value: "high", child: Text("High")),
                DropdownMenuItem(value: "critical", child: Text("Critical")),
              ],
              onChanged: (v) => setState(() => _severity = v ?? "normal"),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _detailCtrl,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: "Detail",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _sendReport,
                icon: const Icon(Icons.send),
                label: Text(_sending ? "Mengirim..." : "Kirim Report"),
              ),
            ),
            const SizedBox(height: 10),
            if (_msg.isNotEmpty)
              Text(
                _msg,
                style: TextStyle(
                  color: _msg.toLowerCase().contains("gagal") || _msg.toLowerCase().contains("error")
                      ? const Color(0xFF5B4CFF)
                      : const Color(0xFF4DA3FF),
                ),
              ),
          ],
        ),
      ),
    );
  }
}






