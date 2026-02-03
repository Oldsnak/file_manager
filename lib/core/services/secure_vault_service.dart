// lib/core/services/secure_vault_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../models/vault_item.dart';


class SecureVaultService {
  // Metadata storage (GetStorage)
  static const String _boxName = "secure_vault_box";
  static const String _itemsKey = "vault_items_v1";

  late final GetStorage _box;

  // internal vault directory name
  static const String _vaultDirName = "SecureVault";

  /// Init must be called once in DependencyInjection before controllers.
  Future<void> init() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
    await _ensureVaultDir();
  }

  /// Internal app-only directory:
  /// - Android: /data/user/0/<pkg>/app_flutter/SecureVault
  /// - iOS: .../Documents/SecureVault
  Future<Directory> _vaultDir() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory("${base.path}/$_vaultDirName");
  }

  Future<void> _ensureVaultDir() async {
    final dir = await _vaultDir();
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
  }

  // =========================================================
  // METADATA
  // =========================================================

  List<VaultItem> loadItems() {
    final raw = _box.read(_itemsKey);
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((m) => VaultItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveItems(List<VaultItem> items) async {
    final list = items.map((e) => e.toJson()).toList();
    await _box.write(_itemsKey, jsonEncode(list));
  }

  // =========================================================
  // LIST / REFRESH
  // =========================================================

  /// Load from metadata and also drop broken entries (deleted files)
  Future<List<VaultItem>> getVaultItemsCleaned() async {
    final items = loadItems();
    if (items.isEmpty) return [];

    final cleaned = <VaultItem>[];
    for (final it in items) {
      if (it.storedPath.isEmpty) continue;
      final f = File(it.storedPath);
      if (await f.exists()) {
        cleaned.add(it);
      }
    }

    if (cleaned.length != items.length) {
      await saveItems(cleaned);
    }
    return cleaned;
  }

  // =========================================================
  // LOCK / UNLOCK
  // =========================================================

  /// Lock a file by moving it into app private directory (vault).
  /// This removes it from public storage so it won't appear in Gallery/Files apps.
  ///
  /// Returns created VaultItem.
  Future<VaultItem> lockFile(String originalPath) async {
    await _ensureVaultDir();

    final src = File(originalPath);
    if (!await src.exists()) {
      throw Exception("File not found");
    }

    final dir = await _vaultDir();
    final ext = _extension(originalPath);
    final baseName = VaultItem.basename(originalPath);

    // Unique name to avoid collisions
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = _safeFileName(baseName);
    final destPath = "${dir.path}/$stamp-$safeName$ext";

    // Move file (rename is fastest, but may fail across storage volumes)
    File moved;
    try {
      moved = await src.rename(destPath);
    } catch (_) {
      // fallback copy+delete
      moved = await src.copy(destPath);
      await src.delete();
    }

    final stat = await moved.stat();
    final item = VaultItem(
      id: moved.path,
      name: VaultItem.basename(moved.path),
      storedPath: moved.path,
      originalPath: originalPath,
      sizeBytes: stat.size,
      modified: stat.modified,
      type: VaultItem.detectType(originalPath),
    );

    final current = loadItems();
    current.insert(0, item);
    await saveItems(current);

    return item;
  }

  /// Unlock (restore) the file back to its original path if possible.
  /// If originalPath is missing, you must pass a restoreDirectory.
  Future<String> unlockFile(
      VaultItem item, {
        String? restoreDirectory,
      }) async {
    final src = File(item.storedPath);
    if (!await src.exists()) throw Exception("Vault file missing");

    // decide destination
    String destPath;
    if (item.originalPath != null && item.originalPath!.isNotEmpty) {
      destPath = item.originalPath!;
    } else {
      if (restoreDirectory == null || restoreDirectory.isEmpty) {
        throw Exception("No restore directory provided");
      }
      destPath = "$restoreDirectory/${item.name}";
    }

    // ensure parent directory exists
    final parent = Directory(_parentDir(destPath));
    if (!parent.existsSync()) {
      await parent.create(recursive: true);
    }

    // if exists, make unique
    destPath = await _avoidOverwrite(destPath);

    File restored;
    try {
      restored = await src.rename(destPath);
    } catch (_) {
      restored = await src.copy(destPath);
      await src.delete();
    }

    // remove from metadata
    final current = loadItems();
    current.removeWhere((x) => x.id == item.id || x.storedPath == item.storedPath);
    await saveItems(current);

    return restored.path;
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> deleteVaultItem(VaultItem item) async {
    final f = File(item.storedPath);
    if (await f.exists()) {
      await f.delete();
    }
    final current = loadItems();
    current.removeWhere((x) => x.id == item.id || x.storedPath == item.storedPath);
    await saveItems(current);
  }

  Future<int> deleteMany(List<VaultItem> items) async {
    int count = 0;
    for (final it in items) {
      try {
        await deleteVaultItem(it);
        count++;
      } catch (_) {}
    }
    return count;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String _extension(String path) {
    final p = path.replaceAll("\\", "/");
    final name = p.split("/").last;
    final dot = name.lastIndexOf(".");
    if (dot < 0) return "";
    return name.substring(dot); // includes dot
  }

  String _safeFileName(String name) {
    // Keep it simple for filesystem safety
    final cleaned = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), "_");
    return cleaned.trim().isEmpty ? "file" : cleaned.trim();
  }

  String _parentDir(String path) {
    final norm = path.replaceAll("\\", "/");
    final idx = norm.lastIndexOf("/");
    if (idx <= 0) return "/";
    return norm.substring(0, idx);
  }

  Future<String> _avoidOverwrite(String destPath) async {
    final f = File(destPath);
    if (!await f.exists()) return destPath;

    final ext = _extension(destPath);
    final base = destPath.substring(0, destPath.length - ext.length);
    int i = 1;

    while (await File("$base ($i)$ext").exists()) {
      i++;
      if (i > 9999) break;
    }
    return "$base ($i)$ext";
  }

  @visibleForTesting
  Future<Directory> debugVaultDir() => _vaultDir();
}
