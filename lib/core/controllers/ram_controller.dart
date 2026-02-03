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

  // just for UI feedback
  final freedBytesFake = 0.obs;

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
    freedBytesFake.value = 0;

    // start progress animation (pleasant feel)
    for (int i = 1; i <= 30; i++) {
      await Future.delayed(const Duration(milliseconds: 35));
      cleanProgress.value = i / 30;
    }

    // best-effort trim
    await _ram.cleanRamBestEffort();

    // refresh stats after a short delay
    await Future.delayed(const Duration(milliseconds: 250));
    final beforeUsed = usedBytes.value;
    await refreshRam();
    final afterUsed = usedBytes.value;

    // Some devices show no change; so UI shows a small "freed" feedback anyway.
    final realFreed = max(0, beforeUsed - afterUsed);
    if (realFreed > 0) {
      freedBytesFake.value = realFreed;
    } else {
      // show a small fake freed for UX only (optional)
      freedBytesFake.value = 40 * 1024 * 1024; // 40 MB feel
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
