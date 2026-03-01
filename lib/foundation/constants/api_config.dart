import 'package:get_storage/get_storage.dart';

/// Central configuration for the video downloader API (Python backend).
///
/// - **Android Emulator**: default [effectiveBaseUrl] is 10.0.2.2:8000.
/// - **Real device**: set the backend URL in the app (e.g. via [setVideoDownloaderBaseUrl])
///   to your PC's LAN IP (e.g. http://192.168.1.10:8000). Ensure the backend is running and
///   the device is on the same network.
class ApiConfig {
  ApiConfig._();

  static const String _storageKeyBaseUrl = 'video_downloader_base_url';

  /// Default base URL.
  /// - Emulator: you can still override via env var.
  /// - Real device: we default to your LAN IP; you can change it from the UI link icon.
  static const String videoDownloaderBaseUrl = String.fromEnvironment(
    'VIDEO_DOWNLOADER_BASE_URL',
    defaultValue: 'http://192.168.0.107:8000',
  );

  /// Base URL used by the app. Reads from storage if set (for real device); otherwise [videoDownloaderBaseUrl].
  static String get effectiveBaseUrl {
    final stored = GetStorage().read<String>(_storageKeyBaseUrl);
    if (stored != null && stored.trim().isNotEmpty) return stored.trim();
    return videoDownloaderBaseUrl;
  }

  /// Save backend base URL (e.g. http://192.168.1.10:8000) for use on a real device.
  static void setVideoDownloaderBaseUrl(String url) {
    GetStorage().write(_storageKeyBaseUrl, url.trim());
  }

  /// Optional API key. If your backend sets API_KEY, set the same value here.
  static const String? videoDownloaderApiKey = String.fromEnvironment(
    'VIDEO_DOWNLOADER_API_KEY',
    defaultValue: '',
  );

  /// Non-empty API key for the service (null if not set).
  static String? get effectiveApiKey {
    final k = videoDownloaderApiKey?.trim();
    return (k != null && k.isNotEmpty) ? k : null;
  }
}
