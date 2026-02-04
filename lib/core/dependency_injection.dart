// lib/core/dependency_injection.dart

import 'package:get/get.dart';

import 'controllers/dashboard_controller.dart';
import 'controllers/file_browser_controller.dart';
import 'controllers/ram_controller.dart';
import 'controllers/vault_controller.dart';

import 'services/file_scan_service.dart';
import 'services/media_service.dart';
import 'services/permission_service.dart';
import 'services/ram_service.dart';
import 'services/secure_vault_service.dart';
import 'services/storage_stats_service.dart';
import 'services/vault_auth_service.dart';

class DependencyInjection {
  static Future<void> init() async {
    // ---------------- Core services ----------------
    Get.put(PermissionService());
    Get.put(StorageStatsService());
    Get.put(MediaService());

    // ✅ MUST be before FileBrowserController (scan depends on it)
    Get.put(FileScanService());

    // ---------------- Secure Vault services (REGISTER EARLY ✅) ----------------
    // ✅ VaultAuthService (no init required)
    Get.put<VaultAuthService>(VaultAuthService(), permanent: true);

    // ✅ SecureVaultService needs init (GetStorage + folder ensure)
    final vault = SecureVaultService();
    await vault.init();
    Get.put<SecureVaultService>(vault, permanent: true);

    // ---------------- Controllers ----------------
    // (If FileBrowserController uses SecureVaultService, it's now available ✅)
    Get.put(FileBrowserController(), permanent: true);
    Get.put(DashboardController(), permanent: true);

    // ---------------- RAM ----------------
    Get.put(RamService(), permanent: true);
    Get.put(RamController(), permanent: true);

    // ---------------- Vault Controller ----------------
    Get.put(VaultController(), permanent: true);
  }
}
