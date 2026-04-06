//JANGAN LU MALING
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PhoneLookupPage extends StatefulWidget {
  final String sessionKey;

  const PhoneLookupPage({super.key, required this.sessionKey});

  @override
  State<PhoneLookupPage> createState() => _PhoneLookupPageState();
}

class _PhoneLookupPageState extends State<PhoneLookupPage> {
  final TextEditingController _phoneController = TextEditingController();
  Map<String, String>? _phoneData;
  bool _isLoading = false;
  static const String _baseUrl = "http://tirz.panel.jserver.web.id:2001";

  Future<void> _lookupPhone() async {
    if (_phoneController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _phoneData = null;
    });

    try {
      final phoneNumber = _phoneController.text.trim();
      final url = Uri.parse(
        '$_baseUrl/api/tools/phone-lookup?key=${Uri.encodeQueryComponent(widget.sessionKey)}&phone=${Uri.encodeQueryComponent(phoneNumber)}',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['ok'] != true) {
          _showSnackBar(
            data['message']?.toString() ?? 'Lookup failed',
            isError: true,
          );
          return;
        }

        setState(() {
          _phoneData = (data['info'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          );
        });
      } else {
        _showSnackBar(
          'Failed to connect to phone lookup service',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFF2C1B5E) : const Color(0xFF2A2A4E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Phone Lookup',
          style: TextStyle(color: Color(0xFF7A5CFF)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF7A5CFF)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2448),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF7A5CFF).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter Phone Number',
                    style: TextStyle(
                      color: Color(0xFF7A5CFF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    style: const TextStyle(color: Color(0xFF7A5CFF)),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter phone number with country code',
                      hintStyle: TextStyle(
                        color: const Color(0xFF7A5CFF).withOpacity(0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF7A5CFF).withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF7A5CFF)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2A2A4E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _lookupPhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A5CFF),
                      foregroundColor: Colors.black,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Lookup Phone'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_phoneData != null) _buildPhoneResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2448),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7A5CFF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phone Information',
            style: TextStyle(
              color: Color(0xFF7A5CFF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_phoneData!.isNotEmpty)
            ..._phoneData!.entries
                .where((entry) => entry.value != 'Not found')
                .map((entry) {
                  return _buildInfoRow(entry.key, entry.value);
                })
                .toList()
          else
            const Text(
              'No information found for this phone number',
              style: TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: const Color(0xFF7A5CFF).withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF7A5CFF), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}






