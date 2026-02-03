// lib/core/controllers/dashboard_controller.dart

import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/storage_info.dart';
import '../services/storage_stats_service.dart';
import '../services/media_service.dart';

class DashboardController extends GetxController {
  final StorageStatsService _storage = Get.find<StorageStatsService>();
  final MediaService _media = Get.find<MediaService>();

  final storageInfo = Rxn<StorageInfo>();
  final isLoading = false.obs;

  // Category sizes (GB)
  final videoGB = 0.0.obs;
  final imageGB = 0.0.obs;
  final audioGB = 0.0.obs;

  // placeholders (later: docs/apps/system/duplicates etc)
  final docsGB = 0.0.obs;
  final appsGB = 0.0.obs;
  final systemGB = 0.0.obs;
  final compressedGB = 0.0.obs;
  final largeFilesGB = 0.0.obs;
  final duplicateGB = 0.0.obs;
  final otherGB = 0.0.obs;
  final recycleGB = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    await refreshStorage();
    await refreshMediaSizes();
    isLoading.value = false;
  }

  Future<void> refreshStorage() async {
    storageInfo.value = await _storage.getInternalStorage();
  }

  /// NOTE:
  /// ye "All" gallery se sum karta hai (images/videos/audios).
  /// Bahut zyada media ho to time lag sakta hai — later we can optimize caching.
  Future<void> refreshMediaSizes() async {
    // make sure permission is granted
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) return;

    videoGB.value = await _sumAllMediaGB(RequestType.video);
    imageGB.value = await _sumAllMediaGB(RequestType.image);
    audioGB.value = await _sumAllMediaGB(RequestType.audio);
  }

  Future<double> _sumAllMediaGB(RequestType type) async {
    // load all assets by paging
    int page = 0;
    const int pageSize = 200;
    int totalBytes = 0;

    while (true) {
      final data = await _media.loadAllMediaPaged(
        type: type,
        newestFirst: true,
        page: page,
        pageSize: pageSize,
      );

      if (data.isEmpty) break;

      for (final it in data) {
        totalBytes += it.sizeBytes;
      }

      if (data.length < pageSize) break;
      page++;
    }

    return totalBytes / (1024 * 1024 * 1024);
  }
}
