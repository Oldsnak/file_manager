// lib/core/controllers/downloader_controller.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  StreamSubscription<Map<String, dynamic>>? _sseSub;
  Timer? _pollTimer;

  // -----------------------
  // Getters for UI
  // -----------------------
  bool get isChecking => _isChecking;
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

  bool get hasVideoInfo => _videoInfo != null;
  bool get canStartDownload => _videoInfo != null && _selectedQuality != null;

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
        }

        notifyListeners();
      } catch (e) {
        // ignore polling errors, keep trying
        debugPrint("Polling error: $e");
      }
    });
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
