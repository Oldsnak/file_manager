import 'dart:math';
import 'package:get/get.dart';
import '../services/ram_service.dart';

class RamController extends GetxController {
  final RamService _ram = Get.find<RamService>();

  final isLoading = false.obs;
  final isCleaning = false.obs;

  final totalBytes = 0.obs;
  final usedBytes = 0.obs;
  final usedPercent = 0.0.obs;

  // animation progress 0..1
  final cleanProgress = 0.0.obs;

  /// Shown when [refreshRam] measures less used RAM after cleaning.
  final freedBytesReported = 0.obs;

  /// Android: packages we asked the system to clear from background (not foreground).
  final backgroundAppsTouched = 0.obs;

  @override
  void onInit() {
    super.onInit();
    refreshRam();
  }

  Future<void> refreshRam() async {
    isLoading.value = true;
    final snap = await _ram.getRamSnapshot();
    totalBytes.value = snap.totalBytes;
    usedBytes.value = snap.usedBytes;
    usedPercent.value = snap.usedPercent.clamp(0.0, 1.0);
    isLoading.value = false;
  }

  Future<void> cleanRam() async {
    if (isCleaning.value) return;

    isCleaning.value = true;
    cleanProgress.value = 0.0;
    freedBytesReported.value = 0;
    backgroundAppsTouched.value = 0;

    // start progress animation (pleasant feel)
    for (int i = 1; i <= 30; i++) {
      await Future.delayed(const Duration(milliseconds: 35));
      cleanProgress.value = i / 30;
    }

    final beforeUsed = usedBytes.value;
    final touched = await _ram.cleanRamBestEffort();
    backgroundAppsTouched.value = touched;

    // Let the system reclaim before re-measuring.
    await Future.delayed(const Duration(milliseconds: 400));
    await refreshRam();
    final afterUsed = usedBytes.value;

    final realFreed = max(0, beforeUsed - afterUsed);
    if (realFreed > 0) {
      freedBytesReported.value = realFreed;
    }

    // finish animation
    cleanProgress.value = 1.0;
    await Future.delayed(const Duration(milliseconds: 300));
    isCleaning.value = false;
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) return "0 MB";
    final mb = bytes / (1024 * 1024);
    if (mb >= 1024) return "${(mb / 1024).toStringAsFixed(1)} GB";
    return "${mb.toStringAsFixed(0)} MB";
  }
}
