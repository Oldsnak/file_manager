// lib/core/models/storage_info.dart

class StorageInfo {
  final int totalBytes;
  final int freeBytes;
  final int usedBytes;

  StorageInfo({
    required this.totalBytes,
    required this.freeBytes,
    required this.usedBytes,
  });

  double get usedPercent => totalBytes == 0 ? 0 : (usedBytes / totalBytes);
}
