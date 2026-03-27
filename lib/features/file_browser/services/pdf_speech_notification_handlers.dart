// lib/features/file_browser/services/pdf_speech_notification_handlers.dart

import 'package:awesome_notifications/awesome_notifications.dart';

import 'pdf_audio_notification.dart';
import 'pdf_speech_coordinator.dart';

/// Awesome Notifications callbacks (may run from background entry points).
class PdfSpeechNotificationHandlers {
  @pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction action) async {
    if (action.channelKey != PdfAudioNotification.channelKey) {
      return;
    }
    if (action.buttonKeyPressed == 'STOP') {
      await PdfSpeechCoordinator.stop();
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onDismissReceived(ReceivedAction action) async {
    if (action.channelKey != PdfAudioNotification.channelKey) {
      return;
    }
    await PdfSpeechCoordinator.stop();
  }
}
