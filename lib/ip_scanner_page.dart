import 'dart:io';
import 'package:flutter/material.dart';

class IpScannerPage extends StatefulWidget {
  const IpScannerPage({super.key});

  @override
  State<IpScannerPage> createState() => _IpScannerPageState();
}

class _IpScannerPageState extends State<IpScannerPage> {
  bool _loading = false;
  List<String> _addresses = [];

  Future<void> _scanInterfaces() async {
    setState(() {
      _loading = true;
      _addresses = [];
    });

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: true,
        includeLinkLocal: true,
      );
      final results = <String>[];
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          results.add('${iface.name} - ${addr.address}');
        }
      }
      setState(() => _addresses = results);
    } catch (e) {
      setState(() => _addresses = ['Error: $e']);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _scanInterfaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IP Scanner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _scanInterfaces,
              child: Text(_loading ? 'Scanning...' : 'Scan Interfaces'),
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _addresses.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.network_ping),
                  title: Text(_addresses[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




