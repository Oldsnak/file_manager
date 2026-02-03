// lib/core/services/file_scan_service.dart
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/file_browser/pages/file_scan_page.dart';
import '../models/browser_item.dart';

/// Folder summary for "Folders view" (like Albums)
class ScanFolder {
  final String path; // full folder path
  final String name; // folder name
  final int count; // number of matched files
  final int totalBytes; // sum of matched files sizes

  const ScanFolder({
    required this.path,
    required this.name,
    required this.count,
    required this.totalBytes,
  });

  double get totalMB => totalBytes / (1024 * 1024);
  double get totalGB => totalBytes / (1024 * 1024 * 1024);
}

class FileScanService {
  /// ✅ in-memory cache (prevents rescanning on every scroll/sort)
  /// key format:
  /// - "cat:<category>"
  /// - "cat:<category>|dir:<folderPath>"
  final Map<String, List<BrowserItem>> _cache = {};
  final Map<String, DateTime> _cacheTime = {};

  /// cache TTL (you can increase later)
  final Duration cacheTTL = const Duration(minutes: 10);

  /// ✅ More practical permissions:
  /// - MANAGE_EXTERNAL_STORAGE (Android 11+) for broad file scanning
  /// - STORAGE fallback
  /// - For Android 13+ audio sometimes needs Permission.audio
  Future<bool> ensureStorageAccess({ScanCategory? category}) async {
    // Try "All files access" first (Android 11+)
    final manage = await Permission.manageExternalStorage.request();
    if (manage.isGranted) return true;

    // Fallback storage (older Androids)
    final storage = await Permission.storage.request();
    if (storage.isGranted) return true;

    // Android 13+ media permission (helps for audio scans on some devices)
    if (category == ScanCategory.audioFiles) {
      final audio = await Permission.audio.request();
      if (audio.isGranted) return true;
    }

    return false;
  }

  // ------------------------------------------------------------
  // ✅ PAGED API (for BrowserPage-like infinite scroll)
  // ------------------------------------------------------------

  /// Main scan (paged): returns BrowserItem list
  /// - page: 0,1,2...
  /// - pageSize: how many items per page
  ///
  /// NOTE: We build cache once, then just slice.
  Future<List<BrowserItem>> scanCategoryPaged(
      ScanCategory category, {
        required int page,
        required int pageSize,
        String? folderPath, // optional for folder drill-down
        int hardLimit = 6000, // prevent too heavy scan
      }) async {
    final ok = await ensureStorageAccess(category: category);
    if (!ok) return [];

    final key = _cacheKey(category, folderPath: folderPath);

    // if cache valid -> slice
    if (_isCacheValid(key)) {
      return _slice(_cache[key]!, page, pageSize);
    }

    // else build full list into cache (once)
    final all = await _scanAndBuildCache(
      category,
      folderPath: folderPath,
      limit: hardLimit,
    );

    _cache[key] = all;
    _cacheTime[key] = DateTime.now();

    return _slice(all, page, pageSize);
  }

  /// Folder view support: grouped by parent directory
  /// This is fast because it uses cached scan result.
  Future<List<ScanFolder>> scanCategoryFolders(
      ScanCategory category, {
        int limitFiles = 6000,
      }) async {
    final ok = await ensureStorageAccess(category: category);
    if (!ok) return [];

    final key = _cacheKey(category);
    List<BrowserItem> items;

    if (_isCacheValid(key)) {
      items = _cache[key]!;
    } else {
      items = await _scanAndBuildCache(category, limit: limitFiles);
      _cache[key] = items;
      _cacheTime[key] = DateTime.now();
    }

    // Group by parent folder path
    final Map<String, ({int count, int bytes})> map = {};

    for (final it in items) {
      final parent = _parentDir(it.path);
      if (parent.isEmpty) continue;

      final current = map[parent];
      if (current == null) {
        map[parent] = (count: 1, bytes: it.sizeBytes);
      } else {
        map[parent] = (count: current.count + 1, bytes: current.bytes + it.sizeBytes);
      }
    }

    final folders = map.entries.map((e) {
      return ScanFolder(
        path: e.key,
        name: e.key.split("/").where((p) => p.isNotEmpty).last,
        count: e.value.count,
        totalBytes: e.value.bytes,
      );
    }).toList();

    // default: largest folders first
    folders.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    return folders;
  }

  /// Folder drill-down (paged)
  Future<List<BrowserItem>> scanFolderItemsPaged(
      String folderPath, {
        required ScanCategory category,
        required int page,
        required int pageSize,
        int hardLimit = 6000,
      }) async {
    return scanCategoryPaged(
      category,
      page: page,
      pageSize: pageSize,
      folderPath: folderPath,
      hardLimit: hardLimit,
    );
  }

  // ------------------------------------------------------------
  // ✅ Actions
  // ------------------------------------------------------------

  Future<void> openFile(String path) async {
    await OpenFilex.open(path);
  }

  /// Multi delete support (selected items)
  Future<int> deleteFiles(List<String> paths, {ScanCategory? category, String? folderPath}) async {
    int deleted = 0;

    for (final p in paths) {
      final ok = await deleteFile(p);
      if (ok) deleted++;
    }

    // invalidate cache so UI refresh shows correct data
    _invalidateCache(category: category, folderPath: folderPath);
    return deleted;
  }

  Future<bool> deleteFile(String path) async {
    try {
      final f = File(path);
      if (!await f.exists()) return false;
      await f.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Manually clear scan cache (optional)
  void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }

  // ------------------------------------------------------------
  // Internals
  // ------------------------------------------------------------

  String _cacheKey(ScanCategory cat, {String? folderPath}) {
    if (folderPath == null || folderPath.trim().isEmpty) return "cat:${cat.name}";
    final normalized = folderPath.replaceAll("\\", "/");
    return "cat:${cat.name}|dir:$normalized";
  }

  bool _isCacheValid(String key) {
    final t = _cacheTime[key];
    final list = _cache[key];
    if (t == null || list == null) return false;
    return DateTime.now().difference(t) <= cacheTTL;
  }

  List<BrowserItem> _slice(List<BrowserItem> all, int page, int pageSize) {
    if (page < 0 || pageSize <= 0) return [];
    final start = page * pageSize;
    if (start >= all.length) return [];
    final end = (start + pageSize).clamp(0, all.length);
    return all.sublist(start, end);
  }

  void _invalidateCache({ScanCategory? category, String? folderPath}) {
    if (category == null) {
      // clear all
      clearCache();
      return;
    }

    final key1 = _cacheKey(category);
    _cache.remove(key1);
    _cacheTime.remove(key1);

    if (folderPath != null && folderPath.trim().isNotEmpty) {
      final key2 = _cacheKey(category, folderPath: folderPath);
      _cache.remove(key2);
      _cacheTime.remove(key2);
    }
  }

  Future<List<BrowserItem>> _scanAndBuildCache(
      ScanCategory category, {
        String? folderPath,
        int limit = 6000,
      }) async {
    final Directory root = Directory("/storage/emulated/0");
    if (!root.existsSync()) return [];

    // if folder drill-down, scan only that folder
    if (folderPath != null && folderPath.trim().isNotEmpty) {
      final dir = Directory(folderPath);
      if (!dir.existsSync()) return [];

      return category == ScanCategory.largeFiles
          ? _scanLargeFilesAsItems(dir, minBytes: 1024 * 1024 * 1024, limit: 1200)
          : _scanDirAsItems(
        dir,
        filter: (p) => _categoryFilter(category, p),
        limit: limit,
      );
    }

    // normal category scan
    final dirs = _categoryDirs(root, category);

    if (category == ScanCategory.largeFiles) {
      return _scanLargeFilesAsItems(root, minBytes: 1024 * 1024 * 1024, limit: 1200);
    }

    return _scanMultipleDirsAsItems(
      dirs,
      filter: (p) => _categoryFilter(category, p),
      limit: limit,
    );
  }

  bool _categoryFilter(ScanCategory category, String path) {
    switch (category) {
      case ScanCategory.downloads:
        return true;
      case ScanCategory.documents:
        return _isDoc(path);
      case ScanCategory.compressed:
        return _isCompressed(path);
      case ScanCategory.largeFiles:
        return true;
      case ScanCategory.otherFiles:
        return _isOther(path);
      case ScanCategory.audioFiles:
        return _isAudio(path);
    }
  }

  List<Directory> _categoryDirs(Directory root, ScanCategory category) {
    final downloads = Directory("${root.path}/Download");
    final documents = Directory("${root.path}/Documents");

    // 🔥 audio common folders (Samsung / Android)
    final music = Directory("${root.path}/Music");
    final ringtones = Directory("${root.path}/Ringtones");
    final notifications = Directory("${root.path}/Notifications");
    final alarms = Directory("${root.path}/Alarms");
    final podcasts = Directory("${root.path}/Podcasts");

    // WhatsApp / Telegram audios (very common)
    final waAudio = Directory("${root.path}/WhatsApp/Media/WhatsApp Audio");
    final waVoice = Directory("${root.path}/WhatsApp/Media/WhatsApp Voice Notes");
    final tgAudio = Directory("${root.path}/Telegram/Telegram Audio");
    final tgVoice = Directory("${root.path}/Telegram/Telegram Voice");

    switch (category) {
      case ScanCategory.downloads:
        return [downloads];

      case ScanCategory.documents:
        return [documents, downloads];

      case ScanCategory.compressed:
        return [downloads, root];

      case ScanCategory.otherFiles:
        return [downloads, documents, root];

      case ScanCategory.audioFiles:
      // ✅ first scan likely places, then root (root last because heavy)
        return [
          music,
          downloads,
          ringtones,
          notifications,
          alarms,
          podcasts,
          waAudio,
          waVoice,
          tgAudio,
          tgVoice,
          root,
        ];

      case ScanCategory.largeFiles:
        return [root];
    }
  }

  bool _shouldSkipPath(String path) {
    final p = path.toLowerCase().replaceAll("\\", "/");

    // Skip heavy / restricted / useless folders
    const skipParts = [
      "/android/data/",
      "/android/obb/",
      "/android/media/",
      "/.trash",
      "/.thumbnails",
      "/cache/",
      "/lost.dir/",
    ];

    for (final s in skipParts) {
      if (p.contains(s)) return true;
    }

    // skip hidden folders (starts with /.  like /storage/emulated/0/.something)
    if (p.split("/").any((seg) => seg.startsWith(".") && seg.length > 1)) {
      return true;
    }

    return false;
  }

  Future<List<BrowserItem>> _scanMultipleDirsAsItems(
      List<Directory> dirs, {
        required bool Function(String path) filter,
        int limit = 3000,
      }) async {
    final List<BrowserItem> out = [];

    for (final d in dirs) {
      if (!d.existsSync()) continue;

      final list = await _scanDirAsItems(
        d,
        filter: filter,
        limit: limit - out.length,
      );
      out.addAll(list);

      if (out.length >= limit) break;
    }

    return out;
  }

  Future<List<BrowserItem>> _scanDirAsItems(
      Directory dir, {
        required bool Function(String path) filter,
        int limit = 2000,
      }) async {
    if (!dir.existsSync()) return [];

    final List<BrowserItem> out = [];

    try {
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (out.length >= limit) break;

        if (e is! File) continue;

        final path = e.path;
        if (_shouldSkipPath(path)) continue;

        if (!filter(path)) continue;

        try {
          final stat = await e.stat();
          final sizeBytes = stat.size;
          final modified = stat.modified;

          out.add(
            BrowserItem(
              id: path, // ✅ unique id for scanned files
              name: _basename(path),
              path: path,
              sizeBytes: sizeBytes,
              modified: modified,
              mimeType: _mimeFromPath(path),
              isImage: _isImage(path),
              isVideo: _isVideo(path),
              isAudio: _isAudio(path),
              isFromGallery: false,
            ),
          );
        } catch (_) {
          // ignore bad files
        }
      }
    } catch (_) {
      // ignore permission/IO errors
    }

    return out;
  }

  Future<List<BrowserItem>> _scanLargeFilesAsItems(
      Directory dir, {
        required int minBytes,
        int limit = 1200,
      }) async {
    final List<BrowserItem> out = [];
    if (!dir.existsSync()) return out;

    try {
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (out.length >= limit) break;

        if (e is! File) continue;

        final path = e.path;
        if (_shouldSkipPath(path)) continue;

        try {
          final stat = await e.stat();
          final sizeBytes = stat.size;
          if (sizeBytes < minBytes) continue;

          out.add(
            BrowserItem(
              id: path,
              name: _basename(path),
              path: path,
              sizeBytes: sizeBytes,
              modified: stat.modified,
              mimeType: _mimeFromPath(path),
              isImage: _isImage(path),
              isVideo: _isVideo(path),
              isAudio: _isAudio(path),
              isFromGallery: false,
            ),
          );
        } catch (_) {}
      }
    } catch (_) {}

    return out;
  }

  String _basename(String path) {
    final parts = path.split(RegExp(r"[\/\\]"));
    return parts.isEmpty ? path : parts.last;
  }

  String _parentDir(String path) {
    final norm = path.replaceAll("\\", "/");
    final idx = norm.lastIndexOf("/");
    if (idx <= 0) return "";
    return norm.substring(0, idx);
  }

  // ---- Type checks ----

  bool _isAudio(String path) {
    final p = path.toLowerCase();
    const exts = [".mp3", ".m4a", ".wav", ".aac", ".flac", ".ogg", ".opus", ".amr"];
    return exts.any((e) => p.endsWith(e));
  }

  bool _isVideo(String path) {
    final p = path.toLowerCase();
    const exts = [".mp4", ".mkv", ".mov", ".avi", ".webm", ".3gp"];
    return exts.any((e) => p.endsWith(e));
  }

  bool _isImage(String path) {
    final p = path.toLowerCase();
    const exts = [".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".heic"];
    return exts.any((e) => p.endsWith(e));
  }

  bool _isDoc(String path) {
    final p = path.toLowerCase();
    const exts = [
      ".pdf",
      ".doc",
      ".docx",
      ".ppt",
      ".pptx",
      ".xls",
      ".xlsx",
      ".txt",
      ".rtf",
      ".csv",
      ".md",
    ];
    return exts.any((e) => p.endsWith(e));
  }

  bool _isCompressed(String path) {
    final p = path.toLowerCase();
    const exts = [".zip", ".rar", ".7z", ".tar", ".gz", ".bz2"];
    return exts.any((e) => p.endsWith(e));
  }

  bool _isOther(String path) {
    final p = path.toLowerCase();

    // exclude media + docs + compressed
    if (_isDoc(p) || _isCompressed(p)) return false;
    if (_isImage(p) || _isVideo(p) || _isAudio(p)) return false;

    return true;
  }

  String _mimeFromPath(String path) {
    final p = path.toLowerCase();

    if (_isImage(p)) return "image/*";
    if (_isVideo(p)) return "video/*";
    if (_isAudio(p)) return "audio/*";
    if (_isDoc(p)) return "application/*";
    if (_isCompressed(p)) return "application/zip";

    return "application/octet-stream";
  }
}
