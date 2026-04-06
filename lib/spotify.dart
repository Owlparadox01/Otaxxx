//JANGAN LU MALING
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SpotifyPage extends StatefulWidget {
  final String sessionKey;
  const SpotifyPage({super.key, required this.sessionKey});

  @override
  State<SpotifyPage> createState() => _SpotifyPageState();
}

class _SpotifyPageState extends State<SpotifyPage> {
  static const String _spotifyClientId = String.fromEnvironment(
    'SPOTIFY_CLIENT_ID',
  );
  static const String _spotifyClientSecret = String.fromEnvironment(
    'SPOTIFY_CLIENT_SECRET',
  );
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _hasSearchResult = false;
  Map<String, dynamic>? _trackData;

  Future<void> _searchTrack() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearchResult = false;
      _trackData = null;
    });

    try {
      final query = _searchController.text.trim();
      final result =
          await _searchViaSpotifyOfficial(query) ??
          await _searchViaITunes(query);

      if (result != null) {
        setState(() {
          _trackData = result;
          _hasSearchResult = true;
        });
      } else {
        _showError('Track tidak ditemukan / server sedang gangguan');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _searchViaSpotifyOfficial(String query) async {
    if (_spotifyClientId.isEmpty || _spotifyClientSecret.isEmpty) return null;
    try {
      final token = await _getSpotifyAccessToken();
      if (token == null || token.isEmpty) return null;
      final response = await http
          .get(
            Uri.parse(
              'https://api.spotify.com/v1/search?q=${Uri.encodeQueryComponent(query)}&type=track&limit=1&market=ID',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>;
      final tracks = data['tracks'];
      if (tracks is! Map) return null;
      final items = tracks['items'];
      if (items is! List || items.isEmpty) return null;

      final row = Map<String, dynamic>.from(items.first as Map);
      final artists = (row['artists'] is List)
          ? (row['artists'] as List)
                .whereType<Map>()
                .map((e) => (e['name'] ?? '').toString())
                .where((e) => e.isNotEmpty)
                .join(', ')
          : '';

      String cover = '';
      final album = row['album'];
      if (album is Map) {
        final images = album['images'];
        if (images is List && images.isNotEmpty) {
          final first = images.first;
          if (first is Map) {
            cover = (first['url'] ?? '').toString();
          }
        }
      }

      return {
        "dlink": (row["preview_url"] ?? "").toString(),
        "searchUrl":
            ((row["external_urls"] is Map)
                    ? (row["external_urls"] as Map)['spotify']
                    : "")
                .toString(),
        "metadata": {
          "title": (row["name"] ?? "Unknown Title").toString(),
          "artist": artists.isEmpty ? "Unknown Artist" : artists,
          "duration": _millisToDuration(row["duration_ms"]),
          "cover": cover,
        },
      };
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getSpotifyAccessToken() async {
    try {
      final basic = base64Encode(
        utf8.encode('$_spotifyClientId:$_spotifyClientSecret'),
      );
      final response = await http
          .post(
            Uri.parse('https://accounts.spotify.com/api/token'),
            headers: {
              'Authorization': 'Basic $basic',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'grant_type': 'client_credentials'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>;
      return (data['access_token'] ?? '').toString();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _searchViaITunes(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://itunes.apple.com/search?term=${Uri.encodeQueryComponent(query)}&entity=song&limit=1',
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'];
      if (results is! List || results.isEmpty) return null;
      final row = Map<String, dynamic>.from(results.first as Map);

      return {
        "dlink": (row["previewUrl"] ?? "").toString(),
        "metadata": {
          "title": (row["trackName"] ?? "Unknown Title").toString(),
          "artist": (row["artistName"] ?? "Unknown Artist").toString(),
          "duration": _millisToDuration(row["trackTimeMillis"]),
          "cover": (row["artworkUrl100"] ?? "").toString(),
        },
        "searchUrl": (row["trackViewUrl"] ?? "").toString(),
      };
    } catch (_) {
      return null;
    }
  }

  String _millisToDuration(dynamic millis) {
    final n = int.tryParse("${millis ?? 0}") ?? 0;
    if (n <= 0) return "--:--";
    final totalSec = n ~/ 1000;
    final min = totalSec ~/ 60;
    final sec = totalSec % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  Future<void> _openTrack() async {
    final dlink = _trackData?['dlink']?.toString() ?? "";
    final searchUrl = _trackData?['searchUrl']?.toString() ?? "";
    final target = searchUrl.isNotEmpty ? searchUrl : dlink;
    if (target.isEmpty) {
      _showError("Link audio tidak tersedia");
      return;
    }
    final uri = Uri.tryParse(target);
    if (uri == null) {
      _showError("Link audio invalid");
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      _showError("Gagal membuka audio");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: const Color(0xFF7A5CFF), content: Text(message)),
    );
  }

  String _safeMeta(String key, {String fallback = "-"}) {
    final meta = Map<String, dynamic>.from(_trackData?['metadata'] ?? {});
    final v = meta[key];
    return (v == null || v.toString().trim().isEmpty) ? fallback : v.toString();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070317),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070317),
        title: const Text(
          'Spotify Play',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cari lagu...',
                      hintStyle: const TextStyle(color: const Color(0xFF6B66A6)),
                      filled: true,
                      fillColor: const Color(0xFF120A2B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _searchTrack(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B4CFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search, color: Colors.white),
                    onPressed: _isLoading ? null : _searchTrack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_hasSearchResult && _trackData != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF120A2B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _safeMeta('cover'),
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 200,
                                  height: 200,
                                  color: const Color(0xFF101E3C),
                                  child: const Icon(
                                    Icons.music_note,
                                    color: const Color(0xFF6B66A6),
                                    size: 60,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _safeMeta('title', fallback: 'Unknown Title'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _safeMeta('artist', fallback: 'Unknown Artist'),
                              style: const TextStyle(
                                color: const Color(0xFF6B66A6),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _safeMeta('duration', fallback: '--:--'),
                              style: TextStyle(
                                color: const Color(0xFFC7CEFF),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openTrack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B4CFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Play / Open Audio"),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF5B4CFF)),
                      const SizedBox(height: 16),
                      Text(
                        'Mencari lagu...',
                        style: TextStyle(color: const Color(0xFFC7CEFF)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        color: const Color(0xFF6B66A6),
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cari lagu favoritmu',
                        style: TextStyle(
                          color: const Color(0xFFC7CEFF),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan judul lagu atau nama artis',
                        style: TextStyle(
                          color: const Color(0xFF6B66A6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}




