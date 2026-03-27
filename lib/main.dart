// lib/main.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'core/dependency_injection.dart';
import 'core/services/download_jobs_registry.dart';
import 'features/file_browser/services/pdf_audio_notification.dart';
import 'features/file_browser/services/pdf_speech_notification_handlers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  DownloadJobsRegistry.instance.load();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.file_manager.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: PdfAudioNotification.channelKey,
        channelName: 'PDF reader',
        channelDescription: 'Listen to PDFs with text-to-speech',
        importance: NotificationImportance.Low,
        defaultPrivacy: NotificationPrivacy.Private,
        playSound: false,
        enableVibration: false,
      ),
    ],
    debug: false,
  );
  await AwesomeNotifications().setListeners(
    onActionReceivedMethod: PdfSpeechNotificationHandlers.onActionReceived,
    onDismissActionReceivedMethod: PdfSpeechNotificationHandlers.onDismissReceived,
  );
  await DependencyInjection.init();
  runApp(const MyApp());
}
