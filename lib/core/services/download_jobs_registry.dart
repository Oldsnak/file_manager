// lib/core/services/download_jobs_registry.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// Persisted list of video download jobs for the library UI and quick-action badge.
class DownloadJobsRegistry extends ChangeNotifier {
  DownloadJobsRegistry._();
  static final DownloadJobsRegistry instance = DownloadJobsRegistry._();

  static const String _storageKey = 'download_jobs_registry_v1';

  final List<DownloadJobRecord> _jobs = [];

  List<DownloadJobRecord> get jobs => List.unmodifiable(_jobs);

  bool get showActiveIndicator =>
      _jobs.any((j) => j.phase == DownloadPhase.downloading || j.phase == DownloadPhase.saving);

  void load() {
    _jobs.clear();
    try {
      final raw = GetStorage().read(_storageKey);
      if (raw is String && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final e in list) {
          if (e is Map) {
            final m = e.map((k, v) => MapEntry(k.toString(), v));
            _jobs.add(DownloadJobRecord.fromJson(m));
          }
        }
      }
    } catch (e) {
      debugPrint('DownloadJobsRegistry.load: $e');
    }
    notifyListeners();
  }

  void _persist() {
    try {
      final encoded = jsonEncode(_jobs.map((j) => j.toJson()).toList());
      GetStorage().write(_storageKey, encoded);
    } catch (e) {
      debugPrint('DownloadJobsRegistry._persist: $e');
    }
    notifyListeners();
  }

  DownloadJobRecord? findByJobId(String jobId) {
    try {
      return _jobs.firstWhere((j) => j.jobId == jobId);
    } catch (_) {
      return null;
    }
  }

  void upsertJob(DownloadJobRecord record) {
    final i = _jobs.indexWhere((j) => j.jobId == record.jobId);
    if (i >= 0) {
      _jobs[i] = record;
    } else {
      _jobs.insert(0, record);
    }
    _persist();
  }

  void updateJob(
    String jobId, {
    DownloadPhase? phase,
    double? percent,
    String? localPath,
    String? error,
  }) {
    final i = _jobs.indexWhere((j) => j.jobId == jobId);
    if (i < 0) return;
    final old = _jobs[i];
    _jobs[i] = old.copyWith(
      phase: phase,
      percent: percent,
      localPath: localPath,
      error: error,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _persist();
  }

  /// Mark job as finished on server and saved locally (or failed).
  void applyCompletion({
    required String jobId,
    required String? localPath,
    required String? error,
  }) {
    updateJob(
      jobId,
      phase: error != null && error.isNotEmpty
          ? DownloadPhase.failed
          : DownloadPhase.completed,
      localPath: localPath,
      error: error,
      percent: error != null ? null : 100,
    );
  }
}

enum DownloadPhase {
  downloading,
  saving,
  completed,
  failed,
}

@immutable
class DownloadJobRecord {
  const DownloadJobRecord({
    required this.jobId,
    required this.title,
    required this.sourceUrl,
    this.thumbnailUrl,
    required this.phase,
    this.percent,
    this.localPath,
    this.error,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String jobId;
  final String title;
  final String sourceUrl;
  final String? thumbnailUrl;
  final DownloadPhase phase;
  final double? percent;
  final String? localPath;
  final String? error;
  final int createdAtMs;
  final int updatedAtMs;

  DownloadJobRecord copyWith({
    DownloadPhase? phase,
    double? percent,
    String? localPath,
    String? error,
    int? updatedAtMs,
  }) {
    return DownloadJobRecord(
      jobId: jobId,
      title: title,
      sourceUrl: sourceUrl,
      thumbnailUrl: thumbnailUrl,
      phase: phase ?? this.phase,
      percent: percent ?? this.percent,
      localPath: localPath ?? this.localPath,
      error: error ?? this.error,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'job_id': jobId,
        'title': title,
        'source_url': sourceUrl,
        'thumbnail_url': thumbnailUrl,
        'phase': phase.name,
        'percent': percent,
        'local_path': localPath,
        'error': error,
        'created_at_ms': createdAtMs,
        'updated_at_ms': updatedAtMs,
      };

  factory DownloadJobRecord.fromJson(Map<String, dynamic> json) {
    DownloadPhase parsePhase(String? s) {
      switch (s) {
        case 'saving':
          return DownloadPhase.saving;
        case 'completed':
          return DownloadPhase.completed;
        case 'failed':
          return DownloadPhase.failed;
        case 'downloading':
        default:
          return DownloadPhase.downloading;
      }
    }

    return DownloadJobRecord(
      jobId: (json['job_id'] ?? '').toString(),
      title: (json['title'] ?? 'Video').toString(),
      sourceUrl: (json['source_url'] ?? '').toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      phase: parsePhase(json['phase']?.toString()),
      percent: (json['percent'] as num?)?.toDouble(),
      localPath: json['local_path']?.toString(),
      error: json['error']?.toString(),
      createdAtMs: (json['created_at_ms'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      updatedAtMs: (json['updated_at_ms'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
