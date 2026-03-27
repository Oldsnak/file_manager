// lib/features/file_browser/services/pdf_audio_notification.dart

import 'package:awesome_notifications/awesome_notifications.dart';

/// Local notification while PDF text-to-speech is playing.
class PdfAudioNotification {
  PdfAudioNotification._();

  static const String channelKey = 'pdf_reader_tts';
  static const int notificationId = 91002;

  static Future<void> show({required String title}) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: channelKey,
        title: 'Reading PDF',
        body: title,
        category: NotificationCategory.Service,
        autoDismissible: true,
        locked: false,
        wakeUpScreen: false,
        displayOnForeground: true,
        displayOnBackground: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'STOP',
          label: 'Stop',
          actionType: ActionType.SilentAction,
          autoDismissible: true,
          showInCompactView: true,
        ),
      ],
    );
  }

  static Future<void> cancel() async {
    await AwesomeNotifications().cancel(notificationId);
  }
}
