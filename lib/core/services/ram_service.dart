// lib/core/services/ram_service.dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:system_info_plus/system_info_plus.dart';

class RamSnapshot {
  final int totalBytes;
  final int freeBytes;

  const RamSnapshot({
    required this.totalBytes,
    required this.freeBytes,
  });

  int get usedBytes => (totalBytes - freeBytes).clamp(0, totalBytes);

  double get usedPercent {
    if (totalBytes <= 0) return 0.0;
    return usedBytes / totalBytes;
  }
}

class RamService {
  static const MethodChannel _channel = MethodChannel("ram_cleaner");

  /// ✅ Returns REAL total + free (when native side implemented)
  /// Fallback: total from system_info_plus, free from native (if available) else 0.
  Future<RamSnapshot> getRamSnapshot() async {
    try {
      // system_info_plus returns in MB (as you mentioned)
      final int? totalMb = await SystemInfoPlus.physicalMemory;
      final int totalBytes = (totalMb ?? 0) * 1024 * 1024;

      // Try native for freeBytes (Android / iOS)
      int freeBytes = 0;

      // Only call channel on real devices/platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final dynamic res = await _channel.invokeMethod("getRam");
          // Expected native response:
          // { "totalBytes": long, "freeBytes": long }
          if (res is Map) {
            final dynamic t = res["totalBytes"];
            final dynamic f = res["freeBytes"];

            final int nativeTotal = _toIntSafe(t);
            final int nativeFree = _toIntSafe(f);

            // Use native total if it exists & looks valid
            final int finalTotal = nativeTotal > 0 ? nativeTotal : totalBytes;
            final int finalFree = nativeFree.clamp(0, finalTotal);

            return RamSnapshot(totalBytes: finalTotal, freeBytes: finalFree);
          }
        } catch (_) {
          // ignore and fallback below
        }
      }

      // Fallback (will show used=total if freeBytes=0)
      return RamSnapshot(totalBytes: totalBytes, freeBytes: freeBytes);
    } catch (_) {
      return const RamSnapshot(totalBytes: 0, freeBytes: 0);
    }
  }

  /// ✅ "Cleaner" (best effort)
  /// NOTE: Actual cleaning is limited on Android for 3rd party apps.
  /// We clear Flutter caches and ask native to trim memory.
  Future<void> cleanRamBestEffort() async {
    try {
      // Flutter memory pressure hint
      WidgetsBinding.instance.handleMemoryPressure();

      // Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Ask native side to trim (if implemented)
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _channel.invokeMethod("trimMemory");
      }
    } catch (_) {
      // ignore silently
    }
  }

  int _toIntSafe(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
