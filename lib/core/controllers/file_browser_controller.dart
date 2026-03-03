// lib/core/controllers/file_browser_controller.dart

import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../features/file_browser/pages/file_scan_page.dart';
import '../../features/file_browser/pages/in_app_audio_player_page.dart';
import '../../features/file_browser/pages/in_app_image_viewer_page.dart';
import '../../features/file_browser/pages/in_app_pdf_viewer_page.dart';
import '../../features/file_browser/pages/in_app_video_player_page.dart';
import '../../features/secure_vault/pages/vault_entry_page.dart';
import '../models/browser_item.dart';
import '../services/media_service.dart';
import '../services/file_scan_service.dart';
import '../services/permission_service.dart';
import '../services/secure_vault_service.dart';

enum ViewMode { list, grid }

enum SortOption {
  dateNewToOld,
  dateOldToNew,
  nameAZ,
  nameZA,
  sizeSmallToLarge,
  sizeLargeToSmall,
}

enum _SourceType { media, scan }

class FileBrowserController extends GetxController {
  // -------------------- services --------------------
  final PermissionService _permissionService = Get.find<PermissionService>();
  final MediaService _mediaService = Get.find<MediaService>();
  final FileScanService _scanService = Get.find<FileScanService>();

  // ✅ vault service (for move-to-secure)
  final SecureVaultService _vault = Get.find<SecureVaultService>();

  // -------------------- UI state --------------------
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final totalCount = 0.obs;

  final items = <BrowserItem>[].obs;

  final viewMode = ViewMode.list.obs;
  final sortOption = SortOption.dateNewToOld.obs;

  // Selection
  final selectionMode = false.obs;
  final selectedIds = <String>{}.obs;

  // -------------------- context --------------------
  _SourceType _source = _SourceType.media;

  // Media context
  RequestType? _mediaType;
  AssetPathEntity? _album; // null => All

  // Scan context
  ScanCategory? _scanCategory;
  String? _scanFolderPath; // null => root scan

  // Paging
  int _page = 0;
  final int _pageSize = 200;
  bool _hasMore = true;

  // ==================================================
  // INIT
  // ==================================================

  Future<void> initForMedia(RequestType type, {AssetPathEntity? album}) async {
    _source = _SourceType.media;
    _mediaType = type;
    _album = album;

    // reset scan context
    _scanCategory = null;
    _scanFolderPath = null;

    // ✅ total count for card
    try {
      totalCount.value = await _mediaService.getTotalCount(type);
    } catch (_) {
      totalCount.value = 0;
    }

    await refresh();
  }

  Future<void> initForScan(
      ScanCategory category, {
        String? folderPath,
      }) async {
    _source = _SourceType.scan;
    _scanCategory = category;
    _scanFolderPath = folderPath;

    // reset media context
    _mediaType = null;
    _album = null;

    await refresh();
  }

  // ==================================================
  // FETCH / PAGING
  // ==================================================

  Future<void> refresh() async {
    isLoading.value = true;
    isLoadingMore.value = false;

    _page = 0;
    _hasMore = true;

    items.clear();
    clearSelection();

    final firstPage = await _loadPage(page: _page);

    // local sort (keeps UI consistent in both sources)
    items.assignAll(_applySort(firstPage));

    if (firstPage.length < _pageSize) {
      _hasMore = false;
    }

    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value || isLoading.value) return;

    isLoadingMore.value = true;
    _page++;

    final next = await _loadPage(page: _page);

    if (next.isEmpty) {
      _hasMore = false;
      isLoadingMore.value = false;
      return;
    }

    // merge & sort again (works like BrowserPage)
    final merged = [...items, ...next];
    items.assignAll(_applySort(merged));

    if (next.length < _pageSize) {
      _hasMore = false;
    }

    isLoadingMore.value = false;
  }

  Future<List<BrowserItem>> _loadPage({required int page}) async {
    // ---------------- MEDIA ----------------
    if (_source == _SourceType.media) {
      final ok = await _permissionService.requestMediaPermission();
      if (!ok || _mediaType == null) return [];

      // For media we can request newest/oldest by query itself
      final newestFirst = sortOption.value == SortOption.dateNewToOld;

      if (_album != null) {
        return _mediaService.loadAlbumMediaPaged(
          album: _album!,
          newestFirst: newestFirst,
          page: page,
          pageSize: _pageSize,
        );
      }

      return _mediaService.loadAllMediaPaged(
        type: _mediaType!,
        newestFirst: newestFirst,
        page: page,
        pageSize: _pageSize,
      );
    }

    // ---------------- FILE SCAN (PAGED) ----------------
    if (_scanCategory == null) return [];

    // ✅ use paged APIs (service builds cache once, then slices)
    if (_scanFolderPath == null || _scanFolderPath!.trim().isEmpty) {
      return _scanService.scanCategoryPaged(
        _scanCategory!,
        page: page,
        pageSize: _pageSize,
      );
    }

    return _scanService.scanFolderItemsPaged(
      _scanFolderPath!,
      category: _scanCategory!,
      page: page,
      pageSize: _pageSize,
    );
  }

  // ==================================================
  // VIEW / SORT
  // ==================================================

  void toggleViewMode() {
    viewMode.value = viewMode.value == ViewMode.list ? ViewMode.grid : ViewMode.list;
  }

  /// ✅ Important:
  /// Scan mode me sorting tabhi properly "global" feel degi jab enough items loaded hon.
  /// Is liye scan mode me sort change par hum jaldi se pages pull karke "load all" kar dete hain.
  Future<void> setSort(SortOption option) async {
    sortOption.value = option;

    // media: current items ko sort kar do
    if (_source == _SourceType.media) {
      items.assignAll(_applySort(items));
      return;
    }

    // scan: ensure "enough" items loaded so sort looks correct
    await _ensureAllScanItemsLoadedForSorting();
    items.assignAll(_applySort(items));
  }

  List<BrowserItem> _applySort(List<BrowserItem> data) {
    final list = [...data];

    switch (sortOption.value) {
      case SortOption.dateNewToOld:
        list.sort((a, b) => b.modified.compareTo(a.modified));
        break;
      case SortOption.dateOldToNew:
        list.sort((a, b) => a.modified.compareTo(b.modified));
        break;
      case SortOption.nameAZ:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameZA:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortOption.sizeSmallToLarge:
        list.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
        break;
      case SortOption.sizeLargeToSmall:
        list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
    }

    return list;
  }

  /// ✅ Scan mode sort ko “BrowserPage jaisa” banane ke liye:
  /// - quickly pull more pages until no more (or safe cap)
  Future<void> _ensureAllScanItemsLoadedForSorting() async {
    if (_source != _SourceType.scan) return;
    if (!_hasMore) return;

    // small safety cap (avoid endless scanning)
    const int maxExtraPages = 30; // 30*200 = 6000 items max
    int pagesFetched = 0;

    while (_hasMore && pagesFetched < maxExtraPages) {
      final nextPage = await _loadPage(page: _page + 1);
      if (nextPage.isEmpty) {
        _hasMore = false;
        break;
      }

      _page++;
      items.addAll(nextPage);

      if (nextPage.length < _pageSize) {
        _hasMore = false;
        break;
      }

      pagesFetched++;
    }
  }

  // ==================================================
  // OPEN / DELETE
  // ==================================================

  Future<void> openItem(BrowserItem item) async {
    if (selectionMode.value) {
      toggleSelection(item.id);
      return;
    }
    if (item.path.isEmpty) return;

    final isPdf = item.name.toLowerCase().endsWith('.pdf') ||
        (item.mimeType.isNotEmpty && item.mimeType.toLowerCase().contains('pdf'));

    if (item.isVideo) {
      final playlist = items.where((i) => i.isVideo && i.path.isNotEmpty).toList();
      Get.to(() => InAppVideoPlayerPage(initialItem: item, playlist: playlist));
      return;
    }
    if (item.isAudio) {
      final playlist = items.where((i) => i.isAudio && i.path.isNotEmpty).toList();
      Get.to(() => InAppAudioPlayerPage(initialItem: item, playlist: playlist));
      return;
    }
    if (item.isImage) {
      final playlist = items.where((i) => i.isImage && i.path.isNotEmpty).toList();
      Get.to(() => InAppImageViewerPage(initialItem: item, playlist: playlist));
      return;
    }
    if (isPdf) {
      Get.to(() => InAppPdfViewerPage(item: item));
      return;
    }

    await _scanService.openFile(item.path);
  }

  Future<void> deleteItem(BrowserItem item) async {
    if (_source == _SourceType.media) {
      final ok = await _mediaService.deleteMediaByIds([item.id]);
      if (!ok) return;
    } else {
      final ok = await _scanService.deleteFile(item.path);
      if (!ok) return;
    }

    items.removeWhere((x) => x.id == item.id);
    selectedIds.remove(item.id);
    if (selectedIds.isEmpty) selectionMode.value = false;
  }

  /// Rename a file (scan mode only). Returns true if renamed, false otherwise.
  Future<bool> renameItem(BrowserItem item, String newName) async {
    if (_source != _SourceType.scan) return false;
    if (item.path.isEmpty || newName.trim().isEmpty) return false;
    final newPath = await _scanService.renameFile(item.path, newName.trim());
    if (newPath == null) return false;
    final idx = items.indexWhere((x) => x.id == item.id);
    if (idx >= 0) {
      items[idx] = item.copyWith(
        id: newPath,
        name: newName.trim(),
        path: newPath,
      );
    }
    return true;
  }

  Future<void> deleteSelected() async {
    if (selectedIds.isEmpty) return;

    if (_source == _SourceType.media) {
      final ok = await _mediaService.deleteMediaByIds(selectedIds.toList());
      if (!ok) return;

      items.removeWhere((x) => selectedIds.contains(x.id));
      clearSelection();
      return;
    }

    // ✅ Scan mode: delete by PATHS (not ids blindly)
    final selectedPaths = items
        .where((x) => selectedIds.contains(x.id))
        .map((x) => x.path)
        .where((p) => p.isNotEmpty)
        .toList();

    if (selectedPaths.isEmpty) return;

    await _scanService.deleteFiles(
      selectedPaths,
      category: _scanCategory,
      folderPath: _scanFolderPath,
    );

    items.removeWhere((x) => selectedIds.contains(x.id));
    clearSelection();
  }

  // ==================================================
  // ✅ MOVE TO SECURE VAULT
  // (single + multi, keeps existing features working)
  // ==================================================

  /// Single item to vault (used by actions sheet)
  Future<bool> moveToSecureVault(BrowserItem item) async {
    if (item.isFromGallery) {
      if (item.id.isEmpty) return false;
    } else {
      if (item.path.isEmpty) return false;
    }

    final ok = await Get.to<bool>(() => VaultEntryPage(returnToCaller: true));
    if (ok != true) return false;

    try {
      if (item.isFromGallery) {
        final bytes = await _mediaService.getFileBytes(item.id);
        if (bytes == null || bytes.isEmpty) return false;
        await _vault.lockFileFromBytes(
          bytes: bytes,
          suggestedName: item.name,
          originalPath: item.path.isNotEmpty ? item.path : null,
        );
        await _mediaService.deleteMediaByIds([item.id]);
      } else {
        await _vault.lockFile(item.path);
      }

      items.removeWhere((x) => x.id == item.id);
      selectedIds.remove(item.id);
      if (selectedIds.isEmpty) selectionMode.value = false;

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Multi selected items to vault
  Future<int> moveSelectedToSecureVault() async {
    if (selectedIds.isEmpty) return 0;

    final ok = await Get.to<bool>(() => VaultEntryPage(returnToCaller: true));
    if (ok != true) return 0;

    int moved = 0;
    final selectedItems = items.where((x) => selectedIds.contains(x.id)).toList();

    for (final it in selectedItems) {
      try {
        if (it.isFromGallery) {
          if (it.id.isEmpty) continue;
          final bytes = await _mediaService.getFileBytes(it.id);
          if (bytes == null || bytes.isEmpty) continue;
          await _vault.lockFileFromBytes(
            bytes: bytes,
            suggestedName: it.name,
            originalPath: it.path.isNotEmpty ? it.path : null,
          );
          await _mediaService.deleteMediaByIds([it.id]);
        } else {
          if (it.path.isEmpty) continue;
          await _vault.lockFile(it.path);
        }
        moved++;
        items.removeWhere((x) => x.id == it.id);
        selectedIds.remove(it.id);
      } catch (_) {}
    }

    if (selectedIds.isEmpty) selectionMode.value = false;
    return moved;
  }

  // ==================================================
  // SELECTION
  // ==================================================

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

  // ==================================================
  // FOLDERS
  // ==================================================

  // Media folders (albums)
  Future<List<AssetPathEntity>> loadAlbums(RequestType type) async {
    final ok = await _permissionService.requestMediaPermission();
    if (!ok) return [];
    return _mediaService.loadAlbums(type: type);
  }

  // Scan folders (grouped by parent directory)
  Future<List<ScanFolder>> loadScanFolders(ScanCategory category) async {
    return _scanService.scanCategoryFolders(category);
  }
}
