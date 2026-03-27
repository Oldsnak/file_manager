// lib/core/services/device_video_save_service.dart

import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'downloader_service.dart';

/// Saves a completed API job to the same public folder the UI downloader uses.
class DeviceVideoSaveService {
  DeviceVideoSaveService._();

  static const String appDownloadFolderName = 'FileManager';

  static final RegExp _nonAllowedStemChars = RegExp(r'[^a-zA-Z0-9#\$_\-]');
  static const int _maxSaveStemLength = 200;

  static const Set<String> _knownVideoExtensions = {
    '.mp4',
    '.mkv',
    '.webm',
    '.m4a',
    '.mov',
    '.avi',
    '.opus',
    '.3gp',
    '.mpeg',
    '.mpg',
  };

  static bool _isKnownVideoExt(String extLower) =>
      _knownVideoExtensions.contains(extLower.toLowerCase());

  static String _sanitizeStemSegment(String stem, int maxLength) {
    var s = stem.replaceAll(_nonAllowedStemChars, '_');
    s = s.replaceAll(RegExp(r'_+'), '_');
    s = s.replaceAll(RegExp(r'^_+|_+$'), '');
    if (s.isEmpty) s = 'video';
    if (s.length > maxLength) {
      s = s.substring(0, maxLength);
      s = s.replaceAll(RegExp(r'_+$'), '');
    }
    if (s.isEmpty) s = 'video';
    return s;
  }

  static String saveBasenamePreservingExtension(String? filename, String jobId) {
    final fallback = '$jobId.mp4';
    if (filename == null || filename.trim().isEmpty) return fallback;

    var base = path.basename(filename.trim());
    if (base.isEmpty) return fallback;

    var ext = path.extension(base);
    var stem = path.basenameWithoutExtension(base);

    if (ext.isEmpty || !_isKnownVideoExt(ext)) {
      ext = '.mp4';
    } else {
      ext = ext.toLowerCase();
    }

    stem = _sanitizeStemSegment(stem, _maxSaveStemLength);
    if (stem.isEmpty) stem = jobId;

    return '$stem$ext';
  }

  static Future<PermissionStatus> requestStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return PermissionStatus.granted;
    }
    if (await Permission.storage.isGranted) {
      return PermissionStatus.granted;
    }
    final manage = await Permission.manageExternalStorage.request();
    if (manage.isGranted) return PermissionStatus.granted;
    final storage = await Permission.storage.request();
    return storage;
  }

  static Future<String> getAppDownloadDirectoryPath() async {
    if (Platform.isAndroid) {
      try {
        final String publicDownload = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOAD,
        );
        if (publicDownload.trim().isNotEmpty) {
          return path.join(publicDownload.trim(), appDownloadFolderName);
        }
      } catch (e) {
        debugPrint('ExternalPath getExternalStoragePublicDirectory failed: $e');
      }
      try {
        final List<String>? roots = await ExternalPath.getExternalStorageDirectories();
        if (roots != null && roots.isNotEmpty && roots.first.trim().isNotEmpty) {
          return path.join(roots.first.trim(), appDownloadFolderName);
        }
      } catch (e) {
        debugPrint('ExternalPath getExternalStorageDirectories failed: $e');
      }
    }
    final dir = await getDownloadsDirectory();
    if (dir != null) return dir.path;
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, appDownloadFolderName);
  }

  /// Downloads bytes from [service] and writes next to other FileManager videos.
  /// Returns local path or null with [errorMessage].
  static Future<({String? path, String? error})> saveJobToDevice({
    required String jobId,
    required DownloaderService service,
  }) async {
    try {
      if (Platform.isAndroid) {
        final PermissionStatus status = await requestStoragePermission();
        if (!status.isGranted) {
          return (path: null, error: 'Storage permission required.');
        }
      }

      final String dirPath = await getAppDownloadDirectoryPath();
      if (dirPath.isEmpty) {
        return (path: null, error: 'Storage folder not available.');
      }

      final dir = Directory(dirPath);
      if (!await dir.exists()) await dir.create(recursive: true);

      final file = await service.downloadFile(jobId);
      final safeName = saveBasenamePreservingExtension(file.filename, jobId);
      final outFile = File(path.join(dirPath, safeName));
      await outFile.writeAsBytes(file.bytes);

      if (Platform.isAndroid) {
        try {
          await MediaScanner.loadMedia(path: outFile.path);
        } catch (e) {
          debugPrint('MediaScanner failed (video still saved): $e');
        }
      }

      return (path: outFile.path, error: null);
    } catch (e) {
      debugPrint('DeviceVideoSaveService.saveJobToDevice failed: $e');
      return (path: null, error: 'Save failed: $e');
    }
  }
}
