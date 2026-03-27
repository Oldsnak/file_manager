// lib/core/controllers/downloader_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart' as path;

import '../models/video_info_model.dart';
import '../models/video_quality_model.dart';
import '../services/device_video_save_service.dart';
import '../services/download_jobs_registry.dart';
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
  });

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
  final Set<String> _saveTriggeredJobIds = {};
  bool _isSavingToDevice = false;

  /// When true, the single-video preview card is hidden (after download starts).
  bool _previewCardDismissed = false;

  StreamSubscription<Map<String, dynamic>>? _sseSub;
  Timer? _pollTimer;

  bool _isPlaylistMode = false;
  final List<PlaylistItemVM> _playlistItems = [];
  bool _cancelRequested = false;
  String? _currentDownloadingSourceUrl;
  final Set<String> _completedPlaylistSourceUrls = {};
  int _completedPlaylistCount = 0;
  bool _playlistDownloadCompleted = false;

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
    return raw.clamp(0, 100) / 100.0;
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

  int get selectedPlaylistCount => _playlistItems.where((it) => it.selected).length;
  int get completedPlaylistCount => _completedPlaylistCount;
  String? get currentDownloadingSourceUrl => _currentDownloadingSourceUrl;
  bool get playlistDownloadCompleted => _playlistDownloadCompleted;
  bool isPlaylistItemCompleted(String sourceUrl) => _completedPlaylistSourceUrls.contains(sourceUrl);

  /// Single-video card visible only before user starts a download for the current preview.
  bool get shouldShowSingleVideoCard =>
      !_isPlaylistMode &&
      _videoInfo != null &&
      _selectedQuality != null &&
      !_previewCardDismissed;

  /// Load registry, restore active job from storage, sync pending saves (e.g. after app restart).
  Future<void> bootstrap() async {
    DownloadJobsRegistry.instance.load();
    await _restoreActiveJobIfAny();
    await syncPendingJobsFromRegistry();
  }

  /// Call when app returns to foreground.
  Future<void> onAppResumed() async {
    await _restoreActiveJobIfAny();
    await syncPendingJobsFromRegistry();
  }

  /// Finish any jobs that completed on the server while the UI was away.
  Future<void> syncPendingJobsFromRegistry() async {
    DownloadJobsRegistry.instance.load();
    for (final j in DownloadJobsRegistry.instance.jobs) {
      if (j.phase != DownloadPhase.downloading && j.phase != DownloadPhase.saving) {
        continue;
      }
      if (j.localPath != null && j.localPath!.isNotEmpty) continue;
      try {
        final st = await downloaderService.getStatus(j.jobId);
        if (st.status == 'finished') {
          await _onJobFinished(j.jobId);
        } else if (st.status == 'failed') {
          DownloadJobsRegistry.instance.applyCompletion(
            jobId: j.jobId,
            localPath: null,
            error: st.error ?? 'Download failed',
          );
        }
      } catch (_) {}
    }
  }

  void _touchRegistryProgress() {
    final id = _jobId;
    if (id == null) return;
    final p = progressValue;
    DownloadJobsRegistry.instance.updateJob(
      id,
      phase: DownloadPhase.downloading,
      percent: p != null ? p * 100 : null,
    );
  }

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
    _previewCardDismissed = false;

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
    _previewCardDismissed = false;
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
    _previewCardDismissed = false;

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
    _cancelRequested = false;
    _completedPlaylistCount = 0;
    _completedPlaylistSourceUrls.clear();
    _playlistDownloadCompleted = false;
    _currentDownloadingSourceUrl = null;
    notifyListeners();

    final selected = _playlistItems.where((it) => it.selected).toList();
    for (final item in selected) {
      if (_cancelRequested) break;

      _currentDownloadingSourceUrl = item.id;
      _videoInfo = item.info;
      _selectedQuality = item.selectedQuality ?? item.info.bestQuality;
      if (_videoInfo == null || _selectedQuality == null) continue;

      await startDownload();

      while (_isDownloading && !_cancelRequested) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (_cancelRequested) break;

      _completedPlaylistSourceUrls.add(item.id);
      _completedPlaylistCount++;
      notifyListeners();
    }

    _currentDownloadingSourceUrl = null;
    _playlistDownloadCompleted = true;
    notifyListeners();
  }

  void cancelDownload() {
    _cancelRequested = true;
    final jid = _jobId;
    _sseSub?.cancel();
    _sseSub = null;
    _stopPolling();
    try {
      GetStorage().remove(_activeJobStorageKey);
    } catch (_) {}
    if (jid != null) {
      DownloadJobsRegistry.instance.applyCompletion(
        jobId: jid,
        localPath: null,
        error: 'Cancelled',
      );
    }
    _isDownloading = false;
    _jobId = null;
    _jobStatus = null;
    _progress = null;
    _previewCardDismissed = false;
    notifyListeners();
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
        filenameHint: _filenameHintFromTitle(_videoInfo!.title),
      );

      _jobId = started.jobId;
      _jobStatus = started.status;
      _isDownloading = true;

      // persist active job id so we can restore after app restart
      try {
        GetStorage().write(_activeJobStorageKey, {'job_id': _jobId});
      } catch (_) {}

      _previewCardDismissed = true;
      final now = DateTime.now().millisecondsSinceEpoch;
      DownloadJobsRegistry.instance.upsertJob(
        DownloadJobRecord(
          jobId: started.jobId,
          title: _videoInfo!.title ?? 'Video',
          sourceUrl: _videoInfo!.sourceUrl,
          thumbnailUrl: _videoInfo!.thumbnail,
          phase: DownloadPhase.downloading,
          percent: 0,
          localPath: null,
          error: null,
          createdAtMs: now,
          updatedAtMs: now,
        ),
      );
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
          if (id != null) unawaited(_onJobFinished(id));
        } else if (_jobStatus == 'failed') {
          _isDownloading = false;
          _stopPolling();
          _sseSub?.cancel();
          final id = _jobId;
          if (id != null) {
            DownloadJobsRegistry.instance.applyCompletion(
              jobId: id,
              localPath: null,
              error: _jobError ?? 'Download failed',
            );
          }
        } else {
          _touchRegistryProgress();
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
          if (_jobStatus == 'finished') {
            unawaited(_onJobFinished(jobId));
          } else {
            DownloadJobsRegistry.instance.applyCompletion(
              jobId: jobId,
              localPath: null,
              error: _jobError ?? 'Download failed',
            );
          }
        } else {
          _touchRegistryProgress();
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
    if (_saveTriggeredJobIds.contains(jobId)) return;
    _saveTriggeredJobIds.add(jobId);
    // clear persisted active job
    try {
      GetStorage().remove(_activeJobStorageKey);
    } catch (_) {}
    await _saveDownloadToDevice(jobId);
  }

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
    DownloadJobsRegistry.instance.updateJob(jobId, phase: DownloadPhase.saving);
    notifyListeners();

    try {
      final r = await DeviceVideoSaveService.saveJobToDevice(jobId: jobId, service: downloaderService);
      if (r.path != null) {
        _lastSavedFilePath = r.path;
        _lastSaveError = null;
        DownloadJobsRegistry.instance.applyCompletion(jobId: jobId, localPath: r.path, error: null);
      } else {
        _lastSaveError = r.error;
        DownloadJobsRegistry.instance.applyCompletion(jobId: jobId, localPath: null, error: r.error);
      }
    } catch (e) {
      _lastSaveError = 'Save failed: $e';
      debugPrint('Save download to device failed: $e');
      DownloadJobsRegistry.instance.applyCompletion(jobId: jobId, localPath: null, error: _lastSaveError);
    } finally {
      _isSavingToDevice = false;
      notifyListeners();
    }
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

  /// Clears [error] after the UI has shown it (e.g. MaterialBanner), so rebuilds do not re-queue notices.
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
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

    _sseSub?.cancel();
    _sseSub = null;

    _stopPolling();
  }

  /// Characters allowed in the title stem (before extension). Everything else → '_'.
  static final RegExp _nonAllowedStemChars = RegExp(r'[^a-zA-Z0-9#\$_\-]');

  static const int _maxHintStemLength = 100;

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

  /// Hint sent to API (server appends random digits + job id + extension).
  String? _filenameHintFromTitle(String? title) {
    if (title == null) return null;
    var stem = title.trim();
    if (stem.isEmpty) return null;
    final ext = path.extension(stem);
    if (ext.isNotEmpty && _isKnownVideoExt(ext)) {
      stem = path.basenameWithoutExtension(stem);
    }
    stem = _sanitizeStemSegment(stem, _maxHintStemLength);
    return stem.isEmpty ? null : stem;
  }

  /// Sanitize stem only: allowed charset, collapse '_', cap length. Never touches extension.
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
