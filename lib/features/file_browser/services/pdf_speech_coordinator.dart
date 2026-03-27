// lib/features/file_browser/services/pdf_speech_coordinator.dart

import 'package:flutter_tts/flutter_tts.dart';

import 'pdf_audio_notification.dart';

/// Shared TTS + notification stop for PDF read-aloud (notification callbacks use this).
class PdfSpeechCoordinator {
  PdfSpeechCoordinator._();

  static final FlutterTts _tts = FlutterTts();
  static bool _configured = false;
  static bool _speaking = false;

  static bool get isSpeaking => _speaking;

  static Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }
    _configured = true;
    await _tts.awaitSpeakCompletion(true);
    try {
      await _tts.setLanguage('en-US');
    } catch (_) {}
  }

  /// Stops speech, clears queue, removes the PDF reader notification.
  static Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
    await PdfAudioNotification.cancel();
  }

  /// Speaks [text] in chunks; shows notification; [onFinished] when done or stopped.
  static Future<void> speakWithNotification({
    required String text,
    required String title,
    void Function()? onFinished,
  }) async {
    await stop();
    await _ensureConfigured();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      onFinished?.call();
      return;
    }

    await PdfAudioNotification.show(title: title);
    _speaking = true;

    final chunks = _chunkText(trimmed, 3200);
    if (chunks.isEmpty) {
      _speaking = false;
      await PdfAudioNotification.cancel();
      onFinished?.call();
      return;
    }
    try {
      for (final chunk in chunks) {
        if (!_speaking) {
          break;
        }
        await _tts.speak(chunk);
      }
    } finally {
      _speaking = false;
      await PdfAudioNotification.cancel();
      onFinished?.call();
    }
  }

  static List<String> _chunkText(String input, int maxLen) {
    if (input.length <= maxLen) {
      return [input];
    }
    final out = <String>[];
    var start = 0;
    while (start < input.length) {
      var end = start + maxLen;
      if (end >= input.length) {
        out.add(input.substring(start));
        break;
      }
      var cut = input.lastIndexOf('\n\n', end);
      if (cut <= start) {
        cut = input.lastIndexOf('. ', end);
      }
      if (cut <= start) {
        cut = input.lastIndexOf(' ', end);
      }
      if (cut <= start) {
        cut = end;
      }
      out.add(input.substring(start, cut).trim());
      start = cut;
    }
    return out.where((s) => s.isNotEmpty).toList();
  }
}
