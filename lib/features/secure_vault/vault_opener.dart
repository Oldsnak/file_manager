// lib/features/secure_vault/vault_opener.dart
// Opens a vault item in the app's in-app viewers (video, image, audio, PDF).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/models/browser_item.dart';
import '../../core/models/vault_item.dart';
import '../../core/services/secure_vault_service.dart';
import '../../features/file_browser/pages/in_app_audio_player_page.dart';
import '../../features/file_browser/pages/in_app_image_viewer_page.dart';
import '../../features/file_browser/pages/in_app_pdf_viewer_page.dart';
import '../../features/file_browser/pages/in_app_video_player_page.dart';
import '../../foundation/helpers/helper_functions.dart';

/// Opens a [VaultItem] in the appropriate in-app viewer (video, image, audio, PDF).
/// Decrypts to a temp path and pushes the viewer. For unsupported types, does nothing.
Future<void> openVaultItemInApp(BuildContext context, VaultItem item) async {
  try {
    final vault = Get.find<SecureVaultService>();
    final tempPath = await vault.getDecryptedTempPath(item);
    final browserItem = _browserItemFromVault(item, tempPath);

    switch (item.type) {
      case VaultItemType.video:
        Get.to(() => InAppVideoPlayerPage(
              initialItem: browserItem,
              playlist: [browserItem],
            ));
        break;
      case VaultItemType.image:
        Get.to(() => InAppImageViewerPage(
              initialItem: browserItem,
              playlist: [browserItem],
            ));
        break;
      case VaultItemType.audio:
        Get.to(() => InAppAudioPlayerPage(
              initialItem: browserItem,
              playlist: [browserItem],
            ));
        break;
      case VaultItemType.document:
        if (_isPdf(item.name)) {
          Get.to(() => InAppPdfViewerPage(item: browserItem));
        } else {
          THelperFunctions.showSnackBar("Open from Secure Folder menu for other apps");
        }
        break;
      case VaultItemType.other:
        THelperFunctions.showSnackBar("Open from Secure Folder menu for other apps");
        break;
    }
  } catch (_) {
    THelperFunctions.showSnackBar("Could not open file");
  }
}

bool _isPdf(String name) {
  return name.toLowerCase().endsWith('.pdf');
}

BrowserItem _browserItemFromVault(VaultItem item, String path) {
  String mimeType = 'application/octet-stream';
  if (item.isImage) mimeType = 'image/*';
  if (item.isVideo) mimeType = 'video/*';
  if (item.isAudio) mimeType = 'audio/*';
  if (_isPdf(item.name)) mimeType = 'application/pdf';

  return BrowserItem(
    id: path,
    name: item.name,
    path: path,
    sizeBytes: item.sizeBytes,
    modified: item.modified,
    mimeType: mimeType,
    isImage: item.isImage,
    isVideo: item.isVideo,
    isAudio: item.isAudio,
    isFromGallery: false,
  );
}
