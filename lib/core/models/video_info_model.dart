// file_manager/core/models/video_info_model.dart

import 'package:flutter/foundation.dart';

import 'video_quality_model.dart';

@immutable
class VideoInfoModel {
  final String? title;
  final int? durationSec;
  final String? thumbnail;
  final String platform;
  final String sourceUrl;
  final List<VideoQualityModel> formats;

  const VideoInfoModel({
    required this.platform,
    required this.sourceUrl,
    required this.formats,
    this.title,
    this.durationSec,
    this.thumbnail,
  });

  /// -------- Helpers (safe parsing) --------

  static String? _asNullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    final s = v.toString();
    return s.isEmpty ? fallback : s;
  }

  static int? _asNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static List<Map<String, dynamic>> _asListOfMap(dynamic v) {
    // Backend ideally returns List<Map>, but sometimes parsing gives List<dynamic>
    if (v == null) return const [];

    if (v is List) {
      final out = <Map<String, dynamic>>[];
      for (final item in v) {
        if (item is Map<String, dynamic>) {
          out.add(item);
        } else if (item is Map) {
          // Convert Map<dynamic,dynamic> -> Map<String,dynamic>
          out.add(item.map((k, val) => MapEntry(k.toString(), val)));
        }
      }
      return out;
    }

    return const [];
  }

  factory VideoInfoModel.fromJson(Map<String, dynamic> json) {
    // formats
    final formatsRaw = _asListOfMap(json['formats']);
    final formats = formatsRaw
        .map((e) => VideoQualityModel.fromJson(e))
        .where((f) => f.formatId.trim().isNotEmpty) // skip invalid
        .toList();

    // Sort low->high quality (UI dropdown etc.)
    formats.sort((a, b) => a.qualityRank.compareTo(b.qualityRank));

    return VideoInfoModel(
      title: _asNullableString(json['title']),
      durationSec: _asNullableInt(json['duration_sec']),
      thumbnail: _asNullableString(json['thumbnail']),
      platform: _asString(json['platform'], fallback: 'unknown'),
      sourceUrl: _asString(json['source_url'], fallback: ''),
      formats: formats,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'duration_sec': durationSec,
    'thumbnail': thumbnail,
    'platform': platform,
    'source_url': sourceUrl,
    'formats': formats.map((e) => e.toJson()).toList(),
  };

  /// Better default selection:
  /// Prefer formats with filesize known, then highest quality.
  VideoQualityModel? get bestQuality {
    if (formats.isEmpty) return null;

    // Copy list so we don't mutate original
    final list = List<VideoQualityModel>.from(formats);

    list.sort((a, b) {
      final aKnown = (a.filesizeBytes ?? 0) > 0 ? 1 : 0;
      final bKnown = (b.filesizeBytes ?? 0) > 0 ? 1 : 0;

      // Known filesize first
      final knownCmp = bKnown.compareTo(aKnown);
      if (knownCmp != 0) return knownCmp;

      // Then higher quality first
      return b.qualityRank.compareTo(a.qualityRank);
    });

    return list.first;
  }
}
