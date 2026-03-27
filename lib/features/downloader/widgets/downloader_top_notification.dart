import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

enum DownloaderNoticeKind { success, error, warning }

/// Strips ANSI codes and pulls a readable `detail` from JSON when present.
String humanizeDownloaderNoticeMessage(String raw) {
  var s = raw.trim();
  s = s.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
  final start = s.lastIndexOf('{');
  if (start != -1) {
    try {
      final decoded = jsonDecode(s.substring(start));
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          s = detail.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '').trim();
        }
      }
    } catch (_) {}
  }
  s = s.replaceFirst(
    RegExp(r'^Failed to fetch video info:\s*ApiException\([^)]*\):\s*Info failed\s*\|\s*'),
    '',
  );
  s = s.replaceFirst(RegExp(r'^ERROR:\s*', caseSensitive: false), '');
  if (s.length > 360) {
    s = '${s.substring(0, 357)}…';
  }
  return s.isEmpty ? raw.trim() : s;
}

String _clipBody(String s, int maxChars) {
  final t = s.trim();
  if (t.length <= maxChars) return t;
  return '${t.substring(0, maxChars - 1)}…';
}

/// Short success line: file name + parent folder name (no full path).
String _successBody(String fullPath) {
  final norm = fullPath.trim();
  if (norm.isEmpty) return 'Download saved.';
  final name = p.basename(norm);
  final parent = p.basename(p.dirname(norm));
  final shortName = name.length > 44 ? '${name.substring(0, 41)}…' : name;
  if (parent.isEmpty || parent == '.' || parent == '/') {
    return 'Saved as $shortName';
  }
  return 'Saved as $shortName\nFolder: $parent';
}

void showDownloaderGetSnackbar({
  required DownloaderNoticeKind kind,
  required String detail,
}) {
  if (Get.isSnackbarOpen) {
    Get.closeAllSnackbars();
  }

  final String title = switch (kind) {
    DownloaderNoticeKind.success => 'Success',
    DownloaderNoticeKind.error => 'Error',
    DownloaderNoticeKind.warning => 'Warning',
  };

  final String message = switch (kind) {
    DownloaderNoticeKind.success => _successBody(detail),
    DownloaderNoticeKind.error => _clipBody(humanizeDownloaderNoticeMessage(detail), 220),
    DownloaderNoticeKind.warning => _clipBody(humanizeDownloaderNoticeMessage(detail), 220),
  };

  final Color backgroundColor = switch (kind) {
    DownloaderNoticeKind.success => Colors.green.withOpacity(0.7),
    DownloaderNoticeKind.error => Colors.red.withOpacity(0.7),
    DownloaderNoticeKind.warning => Colors.orange.withOpacity(0.7),
  };

  final Color borderColor = switch (kind) {
    DownloaderNoticeKind.success => Colors.green,
    DownloaderNoticeKind.error => Colors.red,
    DownloaderNoticeKind.warning => Colors.orange,
  };

  final IconData iconData = switch (kind) {
    DownloaderNoticeKind.success => Icons.check_circle_outline_rounded,
    DownloaderNoticeKind.error => Icons.error_outline_rounded,
    DownloaderNoticeKind.warning => Icons.warning_amber_rounded,
  };

  /// Top margin is 0: [GetSnackBar] already applies [SafeArea] for [SnackPosition.TOP],
  /// so adding status-bar padding here was doubling the gap.
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    duration: const Duration(seconds: 4),
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
    borderRadius: 12,
    borderColor: borderColor,
    borderWidth: 1.5,
    barBlur: 0,
    overlayBlur: 0,
    backgroundColor: backgroundColor,
    colorText: Colors.white,
    icon: Icon(iconData, color: Colors.white, size: 22),
    shouldIconPulse: false,
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
    snackStyle: SnackStyle.FLOATING,
    titleText: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    ),
    messageText: Text(
      message,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.92),
        fontWeight: FontWeight.w400,
        fontSize: 13,
        height: 1.35,
      ),
    ),
  );
}
