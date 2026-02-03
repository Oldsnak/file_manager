import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../models/vault_item.dart';
import '../services/secure_vault_service.dart';

enum VaultViewMode { list, grid }

enum VaultSortOption {
  dateNewToOld,
  dateOldToNew,
  nameAZ,
  nameZA,
  sizeSmallToLarge,
  sizeLargeToSmall,
}

class VaultController extends GetxController {
  final SecureVaultService _vault = Get.find<SecureVaultService>();

  // UI state
  final isLoading = false.obs;
  final viewMode = VaultViewMode.grid.obs;
  final sortOption = VaultSortOption.dateNewToOld.obs;

  // Items
  final items = <VaultItem>[].obs;

  // Selection
  final selectionMode = false.obs;
  final selectedIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    refreshVault();
  }

  // =========================================================
  // LOAD / REFRESH
  // =========================================================

  Future<void> refreshVault() async {
    isLoading.value = true;
    try {
      final data = await _vault.getVaultItemsCleaned();
      items.assignAll(_applySort(data));
    } catch (_) {
      items.clear();
    }
    clearSelection();
    isLoading.value = false;
  }

  // =========================================================
  // PICK & LOCK (NEW ✅)
  // =========================================================

  /// Pick files from device and lock them into Secure Vault
  Future<void> pickAndLockFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      isLoading.value = true;

      for (final f in result.files) {
        final path = f.path;
        if (path == null || path.isEmpty) continue;

        try {
          await _vault.lockFile(path);
        } catch (_) {
          // ignore individual file failure
        }
      }

      final data = await _vault.getVaultItemsCleaned();
      items.assignAll(_applySort(data));
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================
  // VIEW / SORT
  // =========================================================

  void toggleViewMode() {
    viewMode.value =
    viewMode.value == VaultViewMode.list ? VaultViewMode.grid : VaultViewMode.list;
  }

  void setSort(VaultSortOption option) {
    sortOption.value = option;
    items.assignAll(_applySort(items));
  }

  List<VaultItem> _applySort(List<VaultItem> data) {
    final list = [...data];

    switch (sortOption.value) {
      case VaultSortOption.dateNewToOld:
        list.sort((a, b) => b.modified.compareTo(a.modified));
        break;
      case VaultSortOption.dateOldToNew:
        list.sort((a, b) => a.modified.compareTo(b.modified));
        break;
      case VaultSortOption.nameAZ:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case VaultSortOption.nameZA:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case VaultSortOption.sizeSmallToLarge:
        list.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
        break;
      case VaultSortOption.sizeLargeToSmall:
        list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
    }

    return list;
  }

  // =========================================================
  // SELECTION
  // =========================================================

  void startSelection(String firstId) {
    selectionMode.value = true;
    selectedIds.add(firstId);
  }

  void toggleSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
      if (selectedIds.isEmpty) selectionMode.value = false;
    } else {
      selectedIds.add(id);
      selectionMode.value = true;
    }
  }

  void selectAll() {
    selectedIds.clear();
    for (final it in items) {
      selectedIds.add(it.id);
    }
    if (selectedIds.isNotEmpty) selectionMode.value = true;
  }

  void clearSelection() {
    selectionMode.value = false;
    selectedIds.clear();
  }

  // =========================================================
  // UNLOCK / DELETE
  // =========================================================

  Future<String?> unlockItem(VaultItem item, {String? restoreDirectory}) async {
    isLoading.value = true;
    try {
      final restoredPath =
      await _vault.unlockFile(item, restoreDirectory: restoreDirectory);

      items.removeWhere((x) => x.id == item.id || x.storedPath == item.storedPath);
      selectedIds.remove(item.id);
      if (selectedIds.isEmpty) selectionMode.value = false;

      return restoredPath;
    } catch (_) {
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteItem(VaultItem item) async {
    isLoading.value = true;
    try {
      await _vault.deleteVaultItem(item);

      items.removeWhere((x) => x.id == item.id || x.storedPath == item.storedPath);
      selectedIds.remove(item.id);
      if (selectedIds.isEmpty) selectionMode.value = false;

      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<int> deleteSelected() async {
    if (selectedIds.isEmpty) return 0;

    isLoading.value = true;
    try {
      final toDelete = items.where((x) => selectedIds.contains(x.id)).toList();
      final count = await _vault.deleteMany(toDelete);

      items.removeWhere((x) => selectedIds.contains(x.id));
      clearSelection();

      return count;
    } catch (_) {
      return 0;
    } finally {
      isLoading.value = false;
    }
  }
}
