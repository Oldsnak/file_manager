// file_manager/core/services/downloader_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/video_info_model.dart';

class DownloaderService {
  final String baseUrl;
  final String? apiKey;
  final http.Client _client;

  DownloaderService({
    required this.baseUrl,
    this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> _headers({bool jsonBody = true}) {
    final h = <String, String>{
      if (jsonBody) HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };

    final key = apiKey?.trim();
    if (key != null && key.isNotEmpty) {
      h['X-API-KEY'] = key;
    }
    return h;
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  // -------------------------
  // API: /download/check
  // -------------------------
  Future<LinkCheckResult> checkLink(String url) async {
    final resp = await _client.post(
      _u('/api/v1/download/check'),
      headers: _headers(),
      body: jsonEncode({'url': url}),
    );

    if (resp.statusCode != 200) {
      throw ApiException('Check failed', resp.statusCode, resp.body);
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return LinkCheckResult.fromJson(data);
  }

  // -------------------------
  // API: /download/info
  // -------------------------
  Future<VideoInfoModel> getInfo(String url) async {
    final resp = await _client.post(
      _u('/api/v1/download/info'),
      headers: _headers(),
      body: jsonEncode({'url': url}),
    );

    if (resp.statusCode != 200) {
      throw ApiException('Info failed', resp.statusCode, resp.body);
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return VideoInfoModel.fromJson(data);
  }

  // -------------------------
  // API: /download/start
  // -------------------------
  Future<DownloadStartResult> startDownload({
    required String url,
    required String formatId,
    String? filenameHint,
  }) async {
    final payload = <String, dynamic>{
      'url': url,
      'format_id': formatId,
      if (filenameHint != null && filenameHint.trim().isNotEmpty)
        'filename_hint': filenameHint.trim(),
    };

    final resp = await _client.post(
      _u('/api/v1/download/start'),
      headers: _headers(),
      body: jsonEncode(payload),
    );

    if (resp.statusCode != 200) {
      throw ApiException('Start failed', resp.statusCode, resp.body);
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return DownloadStartResult.fromJson(data);
  }

  // -------------------------
  // API: /download/status/{job_id}
  // -------------------------
  Future<JobStatusResult> getStatus(String jobId) async {
    final resp = await _client.get(
      _u('/api/v1/download/status/$jobId'),
      headers: _headers(jsonBody: false),
    );

    if (resp.statusCode != 200) {
      throw ApiException('Status failed', resp.statusCode, resp.body);
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return JobStatusResult.fromJson(data);
  }

  // -------------------------
  // API: SSE /download/stream/{job_id}
  // -------------------------
  Stream<Map<String, dynamic>> streamProgress(String jobId) async* {
    final request = http.Request('GET', _u('/api/v1/download/stream/$jobId'));
    request.headers.addAll(_headers(jsonBody: false));
    request.headers[HttpHeaders.acceptHeader] = 'text/event-stream';

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw ApiException('Stream failed', response.statusCode, body);
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    String? dataLine;

    await for (final line in lines) {
      if (line.startsWith('data:')) {
        dataLine = line.substring(5).trim();
      }

      if (line.isEmpty && dataLine != null && dataLine!.isNotEmpty) {
        try {
          final decoded = jsonDecode(dataLine!) as Map<String, dynamic>;
          yield decoded;
        } catch (e) {
          debugPrint('SSE parse error: $e | data=$dataLine');
        } finally {
          dataLine = null;
        }
      }
    }
  }

  // -------------------------
  // API: /files/{job_id}
  // -------------------------
  Future<Uint8List> downloadFileBytes(String jobId) async {
    final resp = await _client.get(
      _u('/api/v1/files/$jobId'),
      headers: _headers(jsonBody: false),
    );

    if (resp.statusCode != 200) {
      throw ApiException('File download failed', resp.statusCode, resp.body);
    }

    return resp.bodyBytes;
  }

  void dispose() {
    _client.close();
  }
}

// -------------------------
// DTOs for API responses
// -------------------------

class LinkCheckResult {
  final bool valid;
  final String platform;
  final String? normalizedUrl;
  final String? reason;

  LinkCheckResult({
    required this.valid,
    required this.platform,
    this.normalizedUrl,
    this.reason,
  });

  factory LinkCheckResult.fromJson(Map<String, dynamic> json) {
    return LinkCheckResult(
      valid: json['valid'] == true,
      platform: (json['platform'] ?? 'unknown').toString(),
      normalizedUrl: json['normalized_url']?.toString(),
      reason: json['reason']?.toString(),
    );
  }
}

class DownloadStartResult {
  final String jobId;
  final String status;
  final String statusUrl;
  final String streamUrl;
  final String? fileUrl;

  DownloadStartResult({
    required this.jobId,
    required this.status,
    required this.statusUrl,
    required this.streamUrl,
    this.fileUrl,
  });

  factory DownloadStartResult.fromJson(Map<String, dynamic> json) {
    return DownloadStartResult(
      jobId: (json['job_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      statusUrl: (json['status_url'] ?? '').toString(),
      streamUrl: (json['stream_url'] ?? '').toString(),
      fileUrl: json['file_url']?.toString(),
    );
  }
}

class JobStatusResult {
  final String jobId;
  final String status;
  final String platform;
  final String sourceUrl;

  final String? formatId;
  final String? quality;

  final int downloadedBytes;
  final int? totalBytes;
  final double? speedBps;
  final int? etaSec;
  final double? percent;

  final String? publicUrl;
  final String? error;

  JobStatusResult({
    required this.jobId,
    required this.status,
    required this.platform,
    required this.sourceUrl,
    required this.downloadedBytes,
    this.totalBytes,
    this.speedBps,
    this.etaSec,
    this.percent,
    this.formatId,
    this.quality,
    this.publicUrl,
    this.error,
  });

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static int? _asNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _asNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory JobStatusResult.fromJson(Map<String, dynamic> json) {
    final dynamic progRaw = json['progress'];
    Map<String, dynamic>? progress;
    if (progRaw is Map<String, dynamic>) {
      progress = progRaw;
    } else if (progRaw is Map) {
      progress = progRaw.map((k, v) => MapEntry(k.toString(), v));
    } else {
      progress = null;
    }

    final downloaded = _asInt(progress?['downloaded_bytes'], fallback: 0);
    final total = _asNullableInt(progress?['total_bytes']);
    final speed = _asNullableDouble(progress?['speed_bps']);
    final eta = _asNullableInt(progress?['eta_sec']);
    final pct = _asNullableDouble(progress?['percent']);

    return JobStatusResult(
      jobId: (json['job_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      platform: (json['platform'] ?? 'unknown').toString(),
      sourceUrl: (json['source_url'] ?? '').toString(),
      formatId: json['format_id']?.toString(),
      quality: json['quality']?.toString(),
      downloadedBytes: downloaded,
      totalBytes: total,
      speedBps: speed,
      etaSec: eta,
      percent: pct,
      publicUrl: json['public_url']?.toString(),
      error: json['error']?.toString(),
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String body;

  ApiException(this.message, this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $message | $body';
}
