import 'package:disk_space_2/disk_space_2.dart';
import '../models/storage_info.dart';

class StorageStatsService {
  Future<StorageInfo> getInternalStorage() async {
    final double totalRaw = (await DiskSpace.getTotalDiskSpace) ?? 0; // plugin output
    final double freeRaw  = (await DiskSpace.getFreeDiskSpace) ?? 0;

    // ✅ Heuristic:
    // If number is very large (e.g., 5939) it is almost surely MB, not GB.
    // Typical phone total in GB: 64, 128, 256, 512, 1024...
    // Emulator often returns MB.
    final bool isMB = totalRaw > 2000;

    final int totalBytes = isMB
        ? (totalRaw * 1024 * 1024).toInt()       // MB -> bytes
        : (totalRaw * 1024 * 1024 * 1024).toInt(); // GB -> bytes

    final int freeBytes = isMB
        ? (freeRaw * 1024 * 1024).toInt()
        : (freeRaw * 1024 * 1024 * 1024).toInt();

    final int usedBytes = (totalBytes - freeBytes).clamp(0, totalBytes);

    return StorageInfo(
      totalBytes: totalBytes,
      freeBytes: freeBytes,
      usedBytes: usedBytes,
    );
  }
}
