import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String apkUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
        version: json['version'] as String,
        buildNumber: json['build_number'] as int,
        apkUrl: json['apk_url'] as String,
        releaseNotes: json['release_notes'] as String? ?? '',
      );
}

class UpdateService {
  static final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));

  static Future<UpdateInfo?> checkForUpdate() async {
    if (AppConfig.updateCheckUrl.isEmpty) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>(AppConfig.updateCheckUrl);
      if (response.data == null) return null;
      final info = UpdateInfo.fromJson(response.data!);
      final pkg = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;
      return info.buildNumber > currentBuild ? info : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String> _apkPath() async {
    final dir = await getApplicationCacheDirectory();
    return '${dir.path}/lovelink_update.apk';
  }

  static Future<void> clearOldApk() async {
    final f = File(await _apkPath());
    if (f.existsSync()) f.deleteSync();
  }

  static Future<void> downloadAndInstall(
    UpdateInfo info, {
    required void Function(double progress) onProgress,
    required void Function(String? error) onDone,
  }) async {
    try {
      final path = await _apkPath();

      // Clear any old cached APK before downloading
      final old = File(path);
      if (old.existsSync()) old.deleteSync();

      await _dio.download(
        info.apkUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );

      final result = await OpenFilex.open(path, type: 'application/vnd.android.package-archive');
      if (result.type != ResultType.done) {
        onDone(result.message);
      } else {
        onDone(null);
      }
    } catch (e) {
      onDone(e.toString());
    }
  }
}
