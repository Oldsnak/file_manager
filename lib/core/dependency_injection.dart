// lib/core/dependency_injection.dart
import 'package:file_manager/core/services/ram_service.dart';
import 'package:file_manager/core/services/secure_vault_service.dart';
import 'package:get/get.dart';

import 'controllers/ram_controller.dart';
import 'controllers/vault_controller.dart';
import 'services/permission_service.dart';
import 'services/storage_stats_service.dart';
import 'services/media_service.dart';
import 'services/file_scan_service.dart';

import 'controllers/dashboard_controller.dart';
import 'controllers/file_browser_controller.dart';

class DependencyInjection {
  static Future<void> init() async {
    Get.put(PermissionService());
    Get.put(StorageStatsService());
    Get.put(MediaService());

    // ✅ MUST be before FileBrowserController
    Get.put(FileScanService());

    Get.put(FileBrowserController());
    Get.put(DashboardController());

    Get.put(RamService());
    Get.put(RamController());

    final vault = SecureVaultService();
    await vault.init();
    Get.put<SecureVaultService>(vault);

    Get.put(VaultController());
  }
}
