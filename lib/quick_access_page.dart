import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _baseUrl = "http://tirz.panel.jserver.web.id:2001";

class QuickAccessPage extends StatefulWidget {
  final String sessionKey;

  const QuickAccessPage({super.key, required this.sessionKey});

  @override
  State<QuickAccessPage> createState() => _QuickAccessPageState();
}

class _QuickAccessPageState extends State<QuickAccessPage> {
  bool _loading = true;
  String _message = "";
  int _memberCount = 0;
  int _resellerCount = 0;
  int _vipCount = 0;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _resellers = [];
  List<Map<String, dynamic>> _vips = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _message = "";
    });

    try {
      final uri = Uri.parse("$_baseUrl/api/tools/quick-access?key=${Uri.encodeQueryComponent(widget.sessionKey)}");
      final res = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && data["ok"] == true) {
        final stats = (data["stats"] as Map<String, dynamic>? ?? {});
        final users = (data["users"] as Map<String, dynamic>? ?? {});

        setState(() {
          _memberCount = (stats["member"] as num? ?? 0).toInt();
          _resellerCount = (stats["reseller"] as num? ?? 0).toInt();
          _vipCount = (stats["vip"] as num? ?? 0).toInt();
          _members = ((users["member"] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _resellers = ((users["reseller"] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _vips = ((users["vip"] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      } else {
        setState(() {
          _message = data["message"]?.toString() ?? "Gagal mengambil data.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error: $e";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _extendUser(String username) async {
    final uri = Uri.parse(
      "$_baseUrl/editUser?key=${Uri.encodeQueryComponent(widget.sessionKey)}&username=${Uri.encodeQueryComponent(username)}&addDays=7",
    );
    final res = await http.get(uri);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final ok = data["edited"] == true || data["valid"] == true && data["authorized"] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? "Masa aktif $username ditambah 7 hari." : (data["message"]?.toString() ?? "Gagal edit user."))),
    );
    if (ok) _loadData();
  }

  Future<void> _deleteUser(String username) async {
    final uri = Uri.parse(
      "$_baseUrl/deleteUser?key=${Uri.encodeQueryComponent(widget.sessionKey)}&username=${Uri.encodeQueryComponent(username)}",
    );
    final res = await http.get(uri);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final ok = data["deleted"] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? "User $username dihapus." : (data["message"]?.toString() ?? "Gagal hapus user."))),
    );
    if (ok) _loadData();
  }

  Widget _statCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Text("$count", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _userSection(String title, List<Map<String, dynamic>> users) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      subtitle: Text("${users.length} akun", style: const TextStyle(color: Colors.white54)),
      children: users.isEmpty
          ? [
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text("Tidak ada data.", style: TextStyle(color: Colors.white54)),
              ),
            ]
          : users.map((u) {
              final username = (u["username"] ?? "-").toString();
              final expired = (u["expiredDate"] ?? "-").toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  title: Text(username, style: const TextStyle(color: Colors.white)),
                  subtitle: Text("Expired: $expired", style: const TextStyle(color: Colors.white60)),
                  trailing: PopupMenuButton<String>(
                    color: const Color(0xFF120A2B),
                    onSelected: (value) {
                      if (value == "extend") _extendUser(username);
                      if (value == "delete") _deleteUser(username);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: "extend", child: Text("Tambah 7 hari")),
                      PopupMenuItem(value: "delete", child: Text("Hapus akun")),
                    ],
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                  ),
                ),
              );
            }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070317),
      appBar: AppBar(
        title: const Text("Quick Access"),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Owner Control",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Lihat dan kontrol akun member, reseller, VIP",
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _statCard("Member", _memberCount, const Color(0xFF4DA3FF)),
                      const SizedBox(width: 8),
                      _statCard("Reseller", _resellerCount, const Color(0xFF7A5CFF)),
                      const SizedBox(width: 8),
                      _statCard("VIP", _vipCount, const Color(0xFF6B8CFF)),
                    ],
                  ),
                  if (_message.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_message, style: const TextStyle(color: const Color(0xFF4DA3FF))),
                  ],
                  const SizedBox(height: 16),
                  _userSection("Member", _members),
                  _userSection("Reseller", _resellers),
                  _userSection("VIP", _vips),
                ],
              ),
            ),
    );
  }
}







