// file_manager/core/models/video_quality_model.dart

import 'package:flutter/foundation.dart';

@immutable
class VideoQualityModel {
  final String formatId;
  final String quality; // e.g. "360p", "720p"
  final String ext; // e.g. "mp4"
  final int? filesizeBytes;
  final String? filesizeHuman;
  final int? fps;
  final String? vcodec;
  final String? acodec;

  const VideoQualityModel({
    required this.formatId,
    required this.quality,
    required this.ext,
    this.filesizeBytes,
    this.filesizeHuman,
    this.fps,
    this.vcodec,
    this.acodec,
  });

  // -------- Safe parsing helpers --------

  static String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static String? _asNullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _asNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory VideoQualityModel.fromJson(Map<String, dynamic> json) {
    return VideoQualityModel(
      formatId: _asString(json['format_id'], fallback: '').trim(),
      quality: _asString(json['quality'], fallback: 'unknown').trim(),
      ext: _asString(json['ext'], fallback: 'mp4').trim(),
      filesizeBytes: _asNullableInt(json['filesize_bytes']),
      filesizeHuman: _asNullableString(json['filesize_human']),
      fps: _asNullableInt(json['fps']),
      vcodec: _asNullableString(json['vcodec']),
      acodec: _asNullableString(json['acodec']),
    );
  }

  Map<String, dynamic> toJson() => {
    'format_id': formatId,
    'quality': quality,
    'ext': ext,
    'filesize_bytes': filesizeBytes,
    'filesize_human': filesizeHuman,
    'fps': fps,
    'vcodec': vcodec,
    'acodec': acodec,
  };

  /// Example: "720p • 159 MB • mp4"
  /// If filesizeHuman missing, fallback to raw bytes.
  String get displayLabel {
    final size = filesizeHuman ?? _bytesFallback(filesizeBytes);
    final parts = <String>[
      quality,
      if (size != null && size.trim().isNotEmpty) size.trim(),
      if (ext.trim().isNotEmpty) ext.trim(),
    ];
    return parts.join(' • ');
  }

  String? _bytesFallback(int? bytes) {
    if (bytes == null) return null;
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024.0;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024.0;
    return '${gb.toStringAsFixed(2)} GB';
  }

  /// Used for sorting qualities (360p < 720p < 1080p)
  /// Handles: "1080p", "1080P", "720p60", "720p (hd)", etc.
  int get qualityRank {
    final q = quality.toLowerCase().trim();

    // Find first number group in the string
    final match = RegExp(r'(\d{3,4})').firstMatch(q);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }

    // Some fallbacks if a platform returns non-standard labels
    if (q.contains('4k')) return 2160;
    if (q.contains('2k')) return 1440;
    if (q.contains('hd')) return 720;
    if (q.contains('sd')) return 480;

    return 0;
  }
}
