import 'package:get/get.dart';

import '../../core/controllers/dashboard_controller.dart';
import '../../core/controllers/file_browser_controller.dart';

import '../../core/services/file_scan_service.dart';
import '../../core/services/media_service.dart';
import '../../core/services/storage_stats_service.dart';
import '../../core/services/permission_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut(() => PermissionService(), fenix: true);
    Get.lazyPut(() => StorageStatsService(), fenix: true);
    Get.lazyPut(() => MediaService(), fenix: true);
    Get.lazyPut(() => FileScanService(), fenix: true);

    // Controllers
    Get.lazyPut(() => FileBrowserController(), fenix: true);
    Get.lazyPut(() => DashboardController(), fenix: true);
  }
}
