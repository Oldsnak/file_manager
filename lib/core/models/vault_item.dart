// lib/features/secure_vault/models/vault_item.dart

import 'dart:io';

enum VaultItemType { image, video, audio, document, other }

class VaultItem {
  /// Unique id (we’ll use storedPath as unique id)
  final String id;

  /// File name shown in UI
  final String name;

  /// Where the file is stored INSIDE vault (internal/private path)
  final String storedPath;

  /// Optional: original path (for restore / unlock)
  final String? originalPath;

  /// File size in bytes
  final int sizeBytes;

  /// Last modified time
  final DateTime modified;

  /// Type for icon/preview decisions
  final VaultItemType type;

  const VaultItem({
    required this.id,
    required this.name,
    required this.storedPath,
    required this.sizeBytes,
    required this.modified,
    required this.type,
    this.originalPath,
  });

  bool get exists => File(storedPath).existsSync();

  bool get isImage => type == VaultItemType.image;
  bool get isVideo => type == VaultItemType.video;
  bool get isAudio => type == VaultItemType.audio;

  double get sizeMB => sizeBytes / (1024 * 1024);

  static VaultItemType detectType(String path) {
    final p = path.toLowerCase();

    const imageExt = [".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".heic"];
    const videoExt = [".mp4", ".mkv", ".mov", ".avi", ".webm", ".3gp"];
    const audioExt = [".mp3", ".m4a", ".wav", ".aac", ".flac", ".ogg", ".opus"];
    const docExt = [
      ".pdf",
      ".doc",
      ".docx",
      ".ppt",
      ".pptx",
      ".xls",
      ".xlsx",
      ".txt",
      ".rtf",
      ".csv",
      ".md",
    ];

    if (imageExt.any(p.endsWith)) return VaultItemType.image;
    if (videoExt.any(p.endsWith)) return VaultItemType.video;
    if (audioExt.any(p.endsWith)) return VaultItemType.audio;
    if (docExt.any(p.endsWith)) return VaultItemType.document;
    return VaultItemType.other;
  }

  static String basename(String path) {
    final parts = path.split(RegExp(r"[\/\\]"));
    return parts.isEmpty ? path : parts.last;
  }

  /// Build a VaultItem from a file stored in vault.
  /// NOTE: we keep [originalPath] optional (depends on how we store metadata).
  static Future<VaultItem> fromStoredFile(
      File file, {
        String? originalPath,
      }) async {
    final stat = await file.stat();
    final name = basename(file.path);

    return VaultItem(
      id: file.path,
      name: name,
      storedPath: file.path,
      originalPath: originalPath,
      sizeBytes: stat.size,
      modified: stat.modified,
      type: detectType(file.path),
    );
  }

  VaultItem copyWith({
    String? id,
    String? name,
    String? storedPath,
    String? originalPath,
    int? sizeBytes,
    DateTime? modified,
    VaultItemType? type,
  }) {
    return VaultItem(
      id: id ?? this.id,
      name: name ?? this.name,
      storedPath: storedPath ?? this.storedPath,
      originalPath: originalPath ?? this.originalPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modified: modified ?? this.modified,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "storedPath": storedPath,
    "originalPath": originalPath,
    "sizeBytes": sizeBytes,
    "modified": modified.toIso8601String(),
    "type": type.name,
  };

  static VaultItem fromJson(Map<String, dynamic> json) {
    final typeStr = (json["type"] ?? "other").toString();
    final t = VaultItemType.values.firstWhere(
          (e) => e.name == typeStr,
      orElse: () => VaultItemType.other,
    );

    return VaultItem(
      id: (json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      storedPath: (json["storedPath"] ?? "").toString(),
      originalPath: json["originalPath"]?.toString(),
      sizeBytes: (json["sizeBytes"] ?? 0) as int,
      modified: DateTime.tryParse((json["modified"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      type: t,
    );
  }
}
