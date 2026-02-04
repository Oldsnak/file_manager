// lib/core/services/media_service.dart

import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../models/browser_item.dart';

class MediaService {
  // ✅ Small in-memory caches (avoid re-fetching albums and "All" path repeatedly)
  final Map<RequestType, List<AssetPathEntity>> _albumsCache = {};
  final Map<RequestType, AssetPathEntity?> _allAlbumCache = {};

  /// Get albums/folders for given type
  Future<List<AssetPathEntity>> loadAlbums({
    required RequestType type,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _albumsCache.containsKey(type)) {
      return _albumsCache[type]!;
    }

    // onlyAll: false => return albums
    final paths = await PhotoManager.getAssetPathList(
      type: type,
      onlyAll: false,
    );

    _albumsCache[type] = paths;
    return paths;
  }

  /// Load media from "All" (onlyAll=true) - paged
  Future<List<BrowserItem>> loadAllMediaPaged({
    required RequestType type,
    bool newestFirst = true,
    required int page,
    int pageSize = 200,
  }) async {
    // cache "All" album entity (fast, prevents repeated getAssetPathList)
    AssetPathEntity? allAlbum;
    if (_allAlbumCache.containsKey(type)) {
      allAlbum = _allAlbumCache[type];
    } else {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: type,
        onlyAll: true,
        // ordering is applied when we read assets; but keeping filterOption here is fine
        filterOption: FilterOptionGroup(
          orders: [
            OrderOption(type: OrderOptionType.createDate, asc: !newestFirst),
          ],
        ),
      );

      allAlbum = paths.isEmpty ? null : paths.first;
      _allAlbumCache[type] = allAlbum;
    }

    if (allAlbum == null) return [];

    return _loadFromAlbumPaged(
      album: allAlbum,
      newestFirst: newestFirst,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Load media from a specific album - paged
  Future<List<BrowserItem>> loadAlbumMediaPaged({
    required AssetPathEntity album,
    bool newestFirst = true,
    required int page,
    int pageSize = 200,
  }) async {
    return _loadFromAlbumPaged(
      album: album,
      newestFirst: newestFirst,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<BrowserItem>> _loadFromAlbumPaged({
    required AssetPathEntity album,
    required bool newestFirst,
    required int page,
    required int pageSize,
  }) async {
    // ✅ Use proper ordering for this request
    // Note: photo_manager ordering is governed by album's filterOption at creation time,
    // but we can still request sorted via FilterOptionGroup by re-fetching path list.
    // Keeping current behavior stable: we page from album and use its order.
    final List<AssetEntity> assets = await album.getAssetListPaged(
      page: page,
      size: pageSize,
    );

    final List<BrowserItem> items = [];

    for (final a in assets) {
      // Some assets don't resolve to a file path (cloud-only / restricted)
      final File? file = await a.file;

      int sizeBytes = 0;
      String path = '';
      if (file != null) {
        path = file.path;
        try {
          sizeBytes = await file.length();
        } catch (_) {
          sizeBytes = 0;
        }
      }

      items.add(
        BrowserItem(
          id: a.id,
          name: a.title ?? 'Unknown',
          path: path,
          sizeBytes: sizeBytes,
          modified: a.createDateTime,
          mimeType: a.mimeType ?? '',
          isImage: a.type == AssetType.image,
          isVideo: a.type == AssetType.video,
          isAudio: a.type == AssetType.audio,
          isFromGallery: true,
        ),
      );
    }

    // ✅ If user wants oldestFirst but album order is newestFirst (or vice versa),
    // we can safely reverse just this page. This keeps UI consistent with sort option.
    if (!newestFirst && items.length > 1) {
      items.sort((a, b) => a.modified.compareTo(b.modified));
    } else if (newestFirst && items.length > 1) {
      items.sort((a, b) => b.modified.compareTo(a.modified));
    }

    return items;
  }

  Future<bool> deleteMediaByIds(List<String> ids) async {
    if (ids.isEmpty) return false;
    final List<String> deleted = await PhotoManager.editor.deleteWithIds(ids);

    // Optional: after delete, caches still valid (albums list doesn't change usually)
    return deleted.isNotEmpty;
  }

  Future<List<int>?> getThumbnailBytes(String assetId, {int size = 200}) async {
    final AssetEntity? a = await AssetEntity.fromId(assetId);
    if (a == null) return null;
    return a.thumbnailDataWithSize(ThumbnailSize(size, size));
  }

  /// Optional helper if you ever want to clear caches manually
  void clearCache() {
    _albumsCache.clear();
    _allAlbumCache.clear();
  }
}
