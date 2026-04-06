import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class UpdateInfo {
  final String version;
  final int build;
  final String url;
  final String notes;
  final String minVersion;
  final bool force;

  UpdateInfo({
    required this.version,
    required this.build,
    required this.url,
    required this.notes,
    required this.minVersion,
    required this.force,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: (json['version'] ?? '0.0.0').toString(),
      build: int.tryParse((json['build'] ?? '0').toString()) ?? 0,
      url: (json['url'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      minVersion: (json['minVersion'] ?? '0.0.0').toString(),
      force: json['force'] == true,
    );
  }
}

class UpdateService {
  static const String updateEndpoint =
      "http://tirz.panel.jserver.web.id:2001/api/app/update";

  static Future<UpdateInfo?> fetchLatest() async {
    final res = await http.get(Uri.parse(updateEndpoint));
    if (res.statusCode != 200) return null;
    final data = _tryDecodeJson(res.body);
    if (data == null || data['ok'] != true) return null;
    if ((data['url'] ?? '').toString().trim().isEmpty) return null;
    return UpdateInfo.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<bool> hasUpdate(UpdateInfo info) async {
    final pkg = await PackageInfo.fromPlatform();
    final currentVersion = pkg.version;
    final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;

    final versionCmp = _compareVersions(info.version, currentVersion);
    if (versionCmp > 0) return true;
    if (versionCmp < 0) return false;

    return info.build > currentBuild;
  }

  static Future<String> downloadApk(
    String url, {
    required void Function(double progress) onProgress,
  }) async {
    final dir =
        (await getExternalStorageDirectory()) ??
        await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/update.apk";
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }

    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);
    final total = response.contentLength ?? 0;

    final sink = file.openWrite();
    int received = 0;
    await for (final chunk in response.stream) {
      received += chunk.length;
      sink.add(chunk);
      if (total > 0) {
        onProgress(received / total);
      }
    }
    await sink.flush();
    await sink.close();
    return filePath;
  }

  static Future<void> installApk(String filePath) async {
    await OpenFilex.open(
      filePath,
      type: "application/vnd.android.package-archive",
    );
  }

  static Map<String, dynamic>? _tryDecodeJson(String raw) {
    try {
      return Map<String, dynamic>.from(
        jsonDecodeSafe(raw) as Map<dynamic, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  static Object? jsonDecodeSafe(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (int i = 0; i < len; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }
}
