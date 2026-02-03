// lib/core/services/media_service.dart

import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../models/browser_item.dart';

class MediaService {
  /// Get albums/folders for given type
  Future<List<AssetPathEntity>> loadAlbums({
    required RequestType type,
  }) async {
    // onlyAll: false => return albums
    final paths = await PhotoManager.getAssetPathList(
      type: type,
      onlyAll: false,
    );

    // "Recent/All" album alag se add karna ho to:
    // But we will show actual albums in folder view.
    return paths;
  }

  /// Load media from "All" (onlyAll=true) - paged
  Future<List<BrowserItem>> loadAllMediaPaged({
    required RequestType type,
    bool newestFirst = true,
    required int page,
    int pageSize = 200,
  }) async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: type,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [
          OrderOption(type: OrderOptionType.createDate, asc: !newestFirst),
        ],
      ),
    );

    if (paths.isEmpty) return [];
    return _loadFromAlbumPaged(
      album: paths.first,
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
    // Album already exists; just page it
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
    final List<AssetEntity> assets = await album.getAssetListPaged(
      page: page,
      size: pageSize,
    );

    final List<BrowserItem> items = [];

    for (final a in assets) {
      final File? file = await a.file;
      final int sizeBytes = file != null ? await file.length() : 0;

      items.add(
        BrowserItem(
          id: a.id,
          name: a.title ?? 'Unknown',
          path: file?.path ?? '',
          sizeBytes: sizeBytes,
          modified: a.createDateTime,
          mimeType: a.mimeType ?? '',
          isImage: a.type == AssetType.image,
          isVideo: a.type == AssetType.video,
          isAudio: a.type == AssetType.audio,
          isFromGallery: true, // ✅ add
        ),
      );
    }

    return items;
  }

  Future<bool> deleteMediaByIds(List<String> ids) async {
    if (ids.isEmpty) return false;
    final List<String> deleted = await PhotoManager.editor.deleteWithIds(ids);
    return deleted.isNotEmpty;
  }

  Future<List<int>?> getThumbnailBytes(String assetId, {int size = 200}) async {
    final AssetEntity? a = await AssetEntity.fromId(assetId);
    if (a == null) return null;
    return a.thumbnailDataWithSize(ThumbnailSize(size, size));
  }
}
