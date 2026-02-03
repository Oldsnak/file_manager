// lib/core/services/permission_service.dart

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class PermissionService {
  /// Media permissions:
  /// - Android 13+: photos/videos/audio runtime permissions
  /// - Android <=12: storage permission OR photo_manager flow
  Future<bool> requestMediaPermission() async {
    // photo_manager already handles different Android versions properly
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth;
  }

  /// Optional: Storage permission for file scanning (Documents/Downloads via SAF or legacy).
  /// For now we keep it simple; SAF approach later won’t require broad storage permission.
  Future<bool> requestStoragePermissionIfNeeded() async {
    if (!Platform.isAndroid) return true;

    // For Android 10+ you usually avoid broad storage permission (use SAF)
    // But if you still want basic storage permission:
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Open app settings if user permanently denied permissions
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
