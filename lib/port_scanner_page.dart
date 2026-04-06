import 'dart:io';
import 'package:flutter/material.dart';

class PortScannerPage extends StatefulWidget {
  const PortScannerPage({super.key});

  @override
  State<PortScannerPage> createState() => _PortScannerPageState();
}

class _PortScannerPageState extends State<PortScannerPage> {
  final _hostCtrl = TextEditingController(text: '192.168.0.1');
  final _startCtrl = TextEditingController(text: '20');
  final _endCtrl = TextEditingController(text: '1024');
  bool _scanning = false;
  List<int> _openPorts = [];
  String? _error;

  @override
  void dispose() {
    _hostCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final host = _hostCtrl.text.trim();
    final start = int.tryParse(_startCtrl.text) ?? 0;
    final end = int.tryParse(_endCtrl.text) ?? 0;
    if (host.isEmpty || start <= 0 || end <= 0 || end < start) {
      setState(() => _error = 'Input tidak valid');
      return;
    }
    setState(() {
      _scanning = true;
      _openPorts = [];
      _error = null;
    });

    final open = <int>[];
    for (int port = start; port <= end; port++) {
      try {
        final socket = await Socket.connect(
          host,
          port,
          timeout: const Duration(milliseconds: 150),
        ).catchError((_) => null);
        await socket?.close();
        if (socket != null) open.add(port);
      } catch (_) {}
      if (!mounted) break;
      setState(() => _openPorts = List<int>.from(open));
    }

    if (mounted) {
      setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Port Scanner')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _hostCtrl,
              decoration: const InputDecoration(labelText: 'Host / IP'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Port awal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Port akhir'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _scanning ? null : _scan,
              child: Text(_scanning ? 'Scanning...' : 'Mulai Scan'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: const Color(0xFF7A5CFF))),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _openPorts.isEmpty
                  ? const Center(child: Text('Belum ada hasil'))
                  : ListView.builder(
                      itemCount: _openPorts.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: const Icon(Icons.check, color: const Color(0xFF4F8BFF)),
                        title: Text('Port ${_openPorts[i]} terbuka'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}




