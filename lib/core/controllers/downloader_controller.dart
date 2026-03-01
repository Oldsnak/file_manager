// lib/core/controllers/downloader_controller.dart

import 'dart:async';
import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/video_info_model.dart';
import '../models/video_quality_model.dart';
import '../services/downloader_service.dart';
import '../services/social_detector_service.dart';

class DownloaderController extends ChangeNotifier {
  final DownloaderService downloaderService;
  final SocialDetectorService socialDetector;

  /// UI TextField controller (you can attach it without UI redesign)
  final TextEditingController urlController = TextEditingController();

  DownloaderController({
    required this.downloaderService,
    required this.socialDetector,
  }) {
    _restoreActiveJobIfAny();
  }

  // -----------------------
  // State
  // -----------------------
  bool _isChecking = false;
  bool _isFetchingInfo = false;
  bool _isStarting = false;
  bool _isDownloading = false;

  String? _error;
  LinkCheckResult? _checkResult;
  VideoInfoModel? _videoInfo;
  VideoQualityModel? _selectedQuality;

  // Job state
  String? _jobId;
  String? _jobStatus; // queued/downloading/finished/failed
  DownloadProgressVM? _progress;
  String? _publicUrl; // when finished
  String? _jobError;

  /// After job finishes, file is downloaded from API and saved to device.
  String? _lastSavedFilePath;
  String? _lastSaveError;
  String? _saveTriggeredForJobId;
  bool _isSavingToDevice = false;

  StreamSubscription<Map<String, dynamic>>? _sseSub;
  Timer? _pollTimer;

  bool _isPlaylistMode = false;
  final List<PlaylistItemVM> _playlistItems = [];

  // -----------------------
  // Getters for UI
  // -----------------------
  bool get isChecking => _isChecking;
  bool get isPlaylistMode => _isPlaylistMode;
  bool get isFetchingInfo => _isFetchingInfo;
  bool get isStarting => _isStarting;
  bool get isDownloading => _isDownloading;

  String? get error => _error;

  LinkCheckResult? get checkResult => _checkResult;
  VideoInfoModel? get videoInfo => _videoInfo;
  VideoQualityModel? get selectedQuality => _selectedQuality;

  String? get jobId => _jobId;
  String? get jobStatus => _jobStatus;
  DownloadProgressVM? get progress => _progress;
  String? get publicUrl => _publicUrl;
  String? get jobError => _jobError;

  /// 0–1 value derived from [_progress.percent] (0–100) for LinearProgressIndicator.
  double? get progressValue {
    final p = _progress;
    if (p == null || p.percent == null) return null;
    final raw = p.percent!;
    if (raw.isNaN) return null;
    final clamped = raw.clamp(0, 100);
    return (clamped is num ? clamped.toDouble() : 0.0) / 100.0;
  }

  /// Path where the last completed download was saved (e.g. Downloads folder).
  String? get lastSavedFilePath => _lastSavedFilePath;
  /// Error message if saving to device failed.
  String? get lastSaveError => _lastSaveError;
  bool get isSavingToDevice => _isSavingToDevice;

  bool get hasVideoInfo => _videoInfo != null;
  bool get canStartDownload => _videoInfo != null && _selectedQuality != null;

  List<PlaylistItemVM> get playlistItems => List.unmodifiable(_playlistItems);
  bool get hasPlaylist => _playlistItems.isNotEmpty;
  bool get areAllSelected =>
      _playlistItems.isNotEmpty && _playlistItems.every((it) => it.selected);
  bool get hasAnySelected => _playlistItems.any((it) => it.selected);

  /// Call after showing [lastSavedFilePath] or [lastSaveError] in UI so it is not shown again.
  void clearLastSaveResult() {
    _lastSavedFilePath = null;
    _lastSaveError = null;
    notifyListeners();
  }

  // -----------------------
  // Main Actions
  // -----------------------

  /// Call this when user presses the "arrow button" near paste input.
  /// It will:
  /// - normalize URL
  /// - check allowlist (/check)
  /// - fetch formats (/info)
  Future<void> fetchVideoInfo() async {
    final raw = urlController.text.trim();
    if (raw.isEmpty) {
      _setError("Please paste a link first.");
      return;
    }

    _clearError();
    _resetJobState();

    final normalized = socialDetector.normalizeUrl(raw);

    // quick client-side allowlist (optional)
    final platform = socialDetector.detectPlatform(normalized);
    if (platform == 'unknown') {
      // still allow backend to decide, but show hint
      // don't block
    }

    _isChecking = true;
    notifyListeners();

    try {
      final check = await downloaderService.checkLink(normalized);
      _checkResult = check;

      if (!check.valid) {
        _setError(check.reason ?? "Invalid link.");
        _isChecking = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      _setError("Link check failed: $e");
      _isChecking = false;
      notifyListeners();
      return;
    } finally {
      _isChecking = false;
      notifyListeners();
    }

    _isFetchingInfo = true;
    notifyListeners();

    try {
      final info = await downloaderService.getInfo(normalized);
      _videoInfo = info;

      // pick best quality by default
      _selectedQuality = info.bestQuality;

      notifyListeners();
    } catch (e) {
      _setError("Failed to fetch video info: $e");
      notifyListeners();
    } finally {
      _isFetchingInfo = false;
      notifyListeners();
    }
  }

  void selectQuality(VideoQualityModel q) {
    _selectedQuality = q;
    notifyListeners();
  }

  void setPlaylistMode(bool value) {
    if (_isPlaylistMode == value) return;
    _isPlaylistMode = value;
    _playlistItems.clear();
    if (value) {
      // entering playlist mode – clear single-video state
      _videoInfo = null;
      _selectedQuality = null;
    }
    notifyListeners();
  }

  Future<void> fetchPlaylistInfo() async {
    final raw = urlController.text.trim();
    if (raw.isEmpty) {
      _setError("Please paste a playlist link first.");
      return;
    }

    _clearError();
    _resetJobState();
    _playlistItems.clear();

    final normalized = socialDetector.normalizeUrl(raw);

    _isFetchingInfo = true;
    notifyListeners();

    try {
      final playlist = await downloaderService.getPlaylistInfo(normalized);
      _playlistItems.clear();
      for (final v in playlist.videos) {
        _playlistItems.add(
          PlaylistItemVM(
            info: v,
            selected: true,
            selectedQuality: v.bestQuality,
          ),
        );
      }
    } catch (e) {
      _setError("Failed to fetch playlist info: $e");
    } finally {
      _isFetchingInfo = false;
      notifyListeners();
    }
  }

  void toggleSelectAll(bool value) {
    for (final item in _playlistItems) {
      item.selected = value;
    }
    notifyListeners();
  }

  void toggleItemSelected(String id, bool value) {
    final item = _playlistItems.firstWhere(
      (it) => it.id == id,
      orElse: () => throw ArgumentError('Playlist item not found: $id'),
    );
    item.selected = value;
    notifyListeners();
  }

  void selectQualityForItem(String id, VideoQualityModel q) {
    final item = _playlistItems.firstWhere(
      (it) => it.id == id,
      orElse: () => throw ArgumentError('Playlist item not found: $id'),
    );
    item.selectedQuality = q;
    notifyListeners();
  }

  Future<void> startPlaylistDownload() async {
    if (!hasAnySelected) {
      _setError("Please select at least one video from the playlist.");
      return;
    }

    _clearError();

    // Sequentially start backend jobs for selected videos.
    for (final item in _playlistItems.where((it) => it.selected)) {
      _videoInfo = item.info;
      _selectedQuality = item.selectedQuality ?? item.info.bestQuality;
      if (_videoInfo == null || _selectedQuality == null) continue;
      await startDownload();
    }
  }

  /// Call this when user presses final download button.
  Future<void> startDownload() async {
    if (!canStartDownload) {
      _setError("Please fetch video info and select a quality first.");
      return;
    }

    final url = _videoInfo!.sourceUrl;
    final formatId = _selectedQuality!.formatId;

    _clearError();
    _jobError = null;
    _publicUrl = null;

    _isStarting = true;
    notifyListeners();

    try {
      final started = await downloaderService.startDownload(
        url: url,
        formatId: formatId,
        filenameHint: _safeFileName(_videoInfo!.title),
      );

      _jobId = started.jobId;
      _jobStatus = started.status;
      _isDownloading = true;

      // persist active job id so we can restore after app restart
      try {
        GetStorage().write(_activeJobStorageKey, {'job_id': _jobId});
      } catch (_) {}

      notifyListeners();

      // Start SSE progress stream
      _startSse(jobId: started.jobId);

      // Also start polling as fallback (if SSE drops)
      _startPolling(jobId: started.jobId);
    } catch (e) {
      _setError("Failed to start download: $e");
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  // -----------------------
  // SSE + Polling
  // -----------------------

  void _startSse({required String jobId}) {
    _sseSub?.cancel();
    _sseSub = downloaderService.streamProgress(jobId).listen(
          (event) {
        // event format expected:
        // { job_id, status, progress: {...}, public_url, error }
        final status = (event['status'] ?? '').toString();
        if (status.isNotEmpty) _jobStatus = status;

        final prog = event['progress'];
        if (prog is Map) {
          final map = prog.map((k, v) => MapEntry(k.toString(), v));
          _progress = DownloadProgressVM.fromJson(map);
        }

        if (event['public_url'] != null) {
          _publicUrl = event['public_url'].toString();
        }
        if (event['error'] != null) {
          _jobError = event['error'].toString();
        }

        // Stop conditions
        if (_jobStatus == 'finished') {
          _isDownloading = false;
          _stopPolling();
          _sseSub?.cancel();
          final id = _jobId;
          if (id != null) _onJobFinished(id);
        } else if (_jobStatus == 'failed') {
          _isDownloading = false;
          _stopPolling();
          _sseSub?.cancel();
        }

        notifyListeners();
      },
      onError: (err) {
        // SSE can fail due to network; polling will keep running.
        debugPrint("SSE error: $err");
      },
      cancelOnError: false,
    );
  }

  void _startPolling({required String jobId}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final st = await downloaderService.getStatus(jobId);

        _jobStatus = st.status;
        _publicUrl = st.publicUrl ?? _publicUrl;
        _jobError = st.error ?? _jobError;

        _progress = DownloadProgressVM(
          downloadedBytes: st.downloadedBytes,
          totalBytes: st.totalBytes,
          speedBps: st.speedBps,
          etaSec: st.etaSec,
          percent: st.percent,
        );

        if (_jobStatus == 'finished' || _jobStatus == 'failed') {
          _isDownloading = false;
          _stopPolling();
          if (_jobStatus == 'finished' && jobId != null) _onJobFinished(jobId);
        }

        notifyListeners();
      } catch (e) {
        // ignore polling errors, keep trying
        debugPrint("Polling error: $e");
      }
    });
  }

  /// Called once when job reaches "finished". Downloads file from API and saves to device.
  Future<void> _onJobFinished(String jobId) async {
    if (_saveTriggeredForJobId == jobId) return;
    _saveTriggeredForJobId = jobId;
    // clear persisted active job
    try {
      GetStorage().remove(_activeJobStorageKey);
    } catch (_) {}
    await _saveDownloadToDevice(jobId);
  }

  /// App folder name at root of internal storage (e.g. /storage/emulated/0/FileManager).
  static const String _appDownloadFolderName = 'FileManager';

  static const String _activeJobStorageKey = 'downloader_active_job';

  Future<void> _restoreActiveJobIfAny() async {
    try {
      final box = GetStorage();
      final data = box.read(_activeJobStorageKey);
      if (data is! Map) return;
      final jobId = data['job_id']?.toString();
      if (jobId == null || jobId.isEmpty) return;

      final st = await downloaderService.getStatus(jobId);
      _jobId = jobId;
      _jobStatus = st.status;

      if (st.status == 'downloading') {
        _isDownloading = true;
        _startSse(jobId: jobId);
        _startPolling(jobId: jobId);
      } else if (st.status == 'finished') {
        await _onJobFinished(jobId);
      }

      notifyListeners();
    } catch (_) {
      // best-effort restore only
    }
  }

  Future<void> _saveDownloadToDevice(String jobId) async {
    _lastSavedFilePath = null;
    _lastSaveError = null;
    _isSavingToDevice = true;
    notifyListeners();

    try {
      if (Platform.isAndroid) {
        final PermissionStatus status = await _requestStoragePermission();
        if (!status.isGranted) {
          _lastSaveError = 'Storage permission required. Enable in app settings.';
          _isSavingToDevice = false;
          notifyListeners();
          return;
        }
      }

      final String dirPath = await _getAppDownloadDirectoryPath();
      if (dirPath.isEmpty) {
        _lastSaveError = 'Storage folder not available. Grant storage permission.';
        _isSavingToDevice = false;
        notifyListeners();
        return;
      }

      final dir = Directory(dirPath);
      if (!await dir.exists()) await dir.create(recursive: true);

      final file = await downloaderService.downloadFile(jobId);
      final safeName = _safeFileName(file.filename) ?? '$jobId.mp4';
      final outFile = File(path.join(dirPath, safeName));
      await outFile.writeAsBytes(file.bytes);

      if (Platform.isAndroid) {
        try {
          await MediaScanner.loadMedia(path: outFile.path);
        } catch (e) {
          debugPrint('MediaScanner failed (video still saved): $e');
        }
      }

      _lastSavedFilePath = outFile.path;
      _lastSaveError = null;
    } catch (e) {
      _lastSaveError = 'Save failed: $e';
      debugPrint('Save download to device failed: $e');
    } finally {
      _isSavingToDevice = false;
      notifyListeners();
    }
  }

  Future<PermissionStatus> _requestStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) return PermissionStatus.granted;
    if (await Permission.storage.isGranted) return PermissionStatus.granted;
    final manage = await Permission.manageExternalStorage.request();
    if (manage.isGranted) return PermissionStatus.granted;
    final storage = await Permission.storage.request();
    return storage;
  }

  /// Returns path to app folder in user-visible storage:
  /// Android: Download/FileManager (e.g. /storage/emulated/0/Download/FileManager).
  /// Falls back to app-specific dir if public path is not available.
  Future<String> _getAppDownloadDirectoryPath() async {
    if (Platform.isAndroid) {
      try {
        // Prefer public Download folder so files are visible in Files app and can be scanned to gallery
        final String publicDownload = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOAD,
        );
        if (publicDownload.trim().isNotEmpty) {
          return path.join(publicDownload.trim(), _appDownloadFolderName);
        }
      } catch (e) {
        debugPrint('ExternalPath getExternalStoragePublicDirectory failed: $e');
      }
      try {
        final List<String>? roots = await ExternalPath.getExternalStorageDirectories();
        if (roots != null && roots.isNotEmpty && roots.first.trim().isNotEmpty) {
          return path.join(roots.first.trim(), _appDownloadFolderName);
        }
      } catch (e) {
        debugPrint('ExternalPath getExternalStorageDirectories failed: $e');
      }
    }
    final dir = await getDownloadsDirectory();
    if (dir != null) return dir.path;
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, _appDownloadFolderName);
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // -----------------------
  // Helpers
  // -----------------------

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _resetJobState() {
    _jobId = null;
    _jobStatus = null;
    _progress = null;
    _publicUrl = null;
    _jobError = null;
    _isDownloading = false;
    _lastSavedFilePath = null;
    _lastSaveError = null;
    _saveTriggeredForJobId = null;

    _sseSub?.cancel();
    _sseSub = null;

    _stopPolling();
  }

  String? _safeFileName(String? title) {
    if (title == null) return null;
    var s = title.trim();
    if (s.isEmpty) return null;

    // remove illegal filename characters (Windows-friendly)
    s = s.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.length > 80) s = s.substring(0, 80).trim();
    return s.isEmpty ? null : s;
  }

  // -----------------------
  // Dispose
  // -----------------------
  @override
  void dispose() {
    urlController.dispose();
    _sseSub?.cancel();
    _stopPolling();
    super.dispose();
  }
}

/// Simple progress view model for UI
@immutable
class DownloadProgressVM {
  final int downloadedBytes;
  final int? totalBytes;
  final double? speedBps;
  final int? etaSec;
  final double? percent;

  const DownloadProgressVM({
    required this.downloadedBytes,
    this.totalBytes,
    this.speedBps,
    this.etaSec,
    this.percent,
  });

  factory DownloadProgressVM.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    int? _asNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    double? _asNullableDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return DownloadProgressVM(
      downloadedBytes: _asInt(json['downloaded_bytes'], fallback: 0),
      totalBytes: _asNullableInt(json['total_bytes']),
      speedBps: _asNullableDouble(json['speed_bps']),
      etaSec: _asNullableInt(json['eta_sec']),
      percent: _asNullableDouble(json['percent']),
    );
  }

  /// Human helpers (optional – for your UI text)
  String get downloadedHuman => _bytesToHuman(downloadedBytes);
  String? get totalHuman => totalBytes == null ? null : _bytesToHuman(totalBytes!);
  String? get speedHuman => speedBps == null ? null : '${_bytesToHuman(speedBps!.toInt())}/s';

  static String _bytesToHuman(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024.0;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024.0;
    return '${gb.toStringAsFixed(2)} GB';
  }
}

@immutable
class PlaylistItemVM {
  final VideoInfoModel info;
  bool selected;
  VideoQualityModel? selectedQuality;

  PlaylistItemVM({
    required this.info,
    this.selected = true,
    this.selectedQuality,
  });

  String get id => info.sourceUrl;
  String get title => info.title ?? 'Untitled';
  String? get thumbnail => info.thumbnail;
  List<VideoQualityModel> get qualities => info.formats;
}
