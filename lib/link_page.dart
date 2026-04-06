import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkPage extends StatefulWidget {
  const LinkPage({super.key});

  @override
  State<LinkPage> createState() => _LinkPageState();
}

class _LinkPageState extends State<LinkPage> {
  final TextEditingController _controller = TextEditingController();
  String _result = "";

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == "http" || uri.scheme == "https");
  }

  Future<void> _openLink() async {
    final raw = _controller.text.trim();
    if (!_isValidUrl(raw)) {
      setState(() => _result = "Link tidak valid. Gunakan http/https.");
      return;
    }

    final uri = Uri.parse(raw);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    setState(() => _result = ok ? "Link berhasil dibuka." : "Gagal membuka link.");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Link Tools")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Masukkan Link",
                hintText: "https://example.com",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openLink,
                icon: const Icon(Icons.open_in_browser),
                label: const Text("Cek & Buka Link"),
              ),
            ),
            const SizedBox(height: 12),
            if (_result.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_result),
              ),
          ],
        ),
      ),
    );
  }
}




