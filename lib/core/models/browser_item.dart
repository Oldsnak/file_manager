// lib/core/models/browser_item.dart

import 'package:flutter/foundation.dart';

/// A single file/media item shown in File Browser (List/Grid).
/// Works for: images, videos, audios, documents, downloads, etc.
@immutable
class BrowserItem {
  /// For media store items (photo_manager), id is required.
  /// For normal files, you can generate id = path or a hash later.
  final String id;

  final String name;

  /// For MediaStore assets, path can be empty if not resolved yet.
  final String path;

  /// File size in bytes (0 if unknown).
  final int sizeBytes;

  /// Modified/created date (best effort).
  final DateTime modified;

  /// Example: "image/jpeg", "video/mp4"
  final String mimeType;

  /// Category flags (makes UI easy)
  final bool isImage;
  final bool isVideo;
  final bool isAudio;

  final bool isFromGallery;


  const BrowserItem({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.modified,
    required this.mimeType,
    this.isImage = false,
    this.isVideo = false,
    this.isAudio = false,
    this.isFromGallery = false,
  });

  /// Convenience getters
  bool get isMedia => isImage || isVideo || isAudio;

  /// Convert bytes to MB quickly (UI usage)
  double get sizeMB => sizeBytes / (1024 * 1024);

  /// Convert bytes to GB quickly (UI usage)
  double get sizeGB => sizeBytes / (1024 * 1024 * 1024);

  BrowserItem copyWith({
    String? id,
    String? name,
    String? path,
    int? sizeBytes,
    DateTime? modified,
    String? mimeType,
    bool? isImage,
    bool? isVideo,
    bool? isAudio,
  }) {
    return BrowserItem(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modified: modified ?? this.modified,
      mimeType: mimeType ?? this.mimeType,
      isImage: isImage ?? this.isImage,
      isVideo: isVideo ?? this.isVideo,
      isAudio: isAudio ?? this.isAudio,
    );
  }

  @override
  String toString() =>
      'BrowserItem(id: $id, name: $name, path: $path, sizeBytes: $sizeBytes, modified: $modified, mimeType: $mimeType)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrowserItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
