// lib/core/services/background_audio_service.dart

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Service used to play video/audio in background (e.g. when user closes video player
/// with "Play in background" on). Uses just_audio + just_audio_background for
/// media notifications (play, pause, next, prev, progress, stop).
class BackgroundAudioService extends GetxService {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  Future<void> playInBackground({
    required String filePath,
    required String title,
    String id = '',
    Duration? position,
    bool loop = false,
  }) async {
    try {
      await _player.stop();
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.file(filePath),
          tag: MediaItem(
            id: id.isNotEmpty ? id : filePath,
            title: title,
            album: 'File Manager',
          ),
        ),
      );
      if (position != null && position > Duration.zero) {
        await _player.seek(position);
      }
      await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await _player.play();
    } catch (_) {
      // Ignore; file may be invalid
    }
  }

  void stop() {
    _player.stop();
  }

  void pause() {
    _player.pause();
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
