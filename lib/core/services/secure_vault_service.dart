// lib/core/services/secure_vault_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/vault_item.dart';

const int _kEncryptedVersion = 0x01;
const String _kVaultKeyStorageKey = 'vault_aes_key_v1';

class SecureVaultService {
  static const String _boxName = "secure_vault_box";
  static const String _itemsKey = "vault_items_v1";

  late final GetStorage _box;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  List<int>? _vaultKey;

  static const String _vaultDirName = "SecureVault";

  Future<void> init() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
    await _ensureVaultDir();
    await _ensureEncryptionKey();
  }

  Future<void> _ensureEncryptionKey() async {
    if (_vaultKey != null) return;
    final existing = await _secureStorage.read(key: _kVaultKeyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      _vaultKey = base64Url.decode(existing);
      if (_vaultKey != null && _vaultKey!.length == 32) return;
    }
    final random = Random.secure();
    _vaultKey = List<int>.generate(32, (_) => random.nextInt(256));
    await _secureStorage.write(
      key: _kVaultKeyStorageKey,
      value: base64Url.encode(_vaultKey!),
    );
  }

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

  Future<void> clearAllVaultData() async {
    try {
      await _box.remove(_itemsKey);
    } catch (_) {}
    try {
      final dir = await _vaultDir();
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
    await _ensureVaultDir();
  }

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

  Future<List<int>> _encryptBytes(List<int> plainBytes) async {
    await _ensureEncryptionKey();
    final key = SecretKey(_vaultKey!);
    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(
      plainBytes,
      secretKey: key,
    );
    final concat = secretBox.concatenation();
    return <int>[_kEncryptedVersion, ...concat];
  }

  Future<List<int>> _decryptBytes(List<int> encryptedBytes) async {
    await _ensureEncryptionKey();
    final algorithm = AesGcm.with256bits();
    if (encryptedBytes.length <= 1 + algorithm.nonceLength + algorithm.macAlgorithm.macLength) {
      throw Exception("Invalid encrypted payload");
    }
    final payload = encryptedBytes.sublist(1);
    final secretBox = SecretBox.fromConcatenation(
      payload,
      nonceLength: algorithm.nonceLength,
      macLength: algorithm.macAlgorithm.macLength,
    );
    final key = SecretKey(_vaultKey!);
    return await algorithm.decrypt(secretBox, secretKey: key);
  }

  bool _isEncryptedVaultFile(List<int> bytes) {
    return bytes.isNotEmpty && bytes.first == _kEncryptedVersion;
  }

  Future<String> getDecryptedTempPath(VaultItem item) async {
    final src = File(item.storedPath);
    if (!await src.exists()) throw Exception("Vault file missing");
    final bytes = await src.readAsBytes();
    final dir = await getTemporaryDirectory();
    final tempPath = "${dir.path}/vault_preview_${DateTime.now().millisecondsSinceEpoch}_${item.name}";
    if (_isEncryptedVaultFile(bytes)) {
      final decrypted = await _decryptBytes(bytes);
      await File(tempPath).writeAsBytes(decrypted);
    } else {
      await src.copy(tempPath);
    }
    return tempPath;
  }

  Future<VaultItem> lockFile(String originalPath) async {
    await _ensureVaultDir();
    await _ensureEncryptionKey();

    final src = File(originalPath);
    if (!await src.exists()) {
      throw Exception("File not found");
    }

    final dir = await _vaultDir();
    final baseName = VaultItem.basename(originalPath);
    final safeFullName = _safeFileName(baseName);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final destPath = "${dir.path}/$stamp-$safeFullName";

    final bytes = await src.readAsBytes();
    final encrypted = await _encryptBytes(bytes);
    final destFile = File(destPath);
    await destFile.writeAsBytes(encrypted);

    try {
      await src.delete();
    } catch (e) {
      try {
        await destFile.delete();
      } catch (_) {}
      throw Exception("Could not remove file from original location: $e");
    }

    final stat = await destFile.stat();
    final item = VaultItem(
      id: destPath,
      name: VaultItem.basename(destPath),
      storedPath: destPath,
      originalPath: originalPath,
      sizeBytes: stat.size,
      modified: stat.modified,
      type: VaultItem.detectType(originalPath),
    );

    final current = loadItems();
    current.removeWhere((x) => x.storedPath == item.storedPath || x.originalPath == originalPath);
    current.insert(0, item);
    await saveItems(current);

    return item;
  }

  Future<VaultItem> lockFileFromBytes({
    required List<int> bytes,
    required String suggestedName,
    String? originalPath,
  }) async {
    await _ensureVaultDir();
    await _ensureEncryptionKey();

    final dir = await _vaultDir();
    final safeFullName = _safeFileName(suggestedName);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final destPath = "${dir.path}/$stamp-$safeFullName";

    final encrypted = await _encryptBytes(bytes);
    final destFile = File(destPath);
    await destFile.writeAsBytes(encrypted);

    final stat = await destFile.stat();
    final item = VaultItem(
      id: destPath,
      name: VaultItem.basename(destPath),
      storedPath: destPath,
      originalPath: originalPath ?? '',
      sizeBytes: stat.size,
      modified: stat.modified,
      type: VaultItem.detectType(suggestedName),
    );

    final current = loadItems();
    current.insert(0, item);
    await saveItems(current);

    return item;
  }

  Future<String> unlockFile(
      VaultItem item, {
        String? restoreDirectory,
      }) async {
    final src = File(item.storedPath);
    if (!await src.exists()) throw Exception("Vault file missing");

    String destPath;
    if (item.originalPath != null && item.originalPath!.trim().isNotEmpty) {
      destPath = _normalizePath(item.originalPath!);
    } else {
      if (restoreDirectory == null || restoreDirectory.trim().isEmpty) {
        throw Exception("No restore directory provided");
      }
      destPath = path.join(restoreDirectory.trim(), item.name);
    }

    await _ensureParentDirsExist(destPath);

    destPath = await _avoidOverwrite(destPath);

    final bytes = await src.readAsBytes();

    if (_isEncryptedVaultFile(bytes)) {
      final decrypted = await _decryptBytes(bytes);
      await File(destPath).writeAsBytes(decrypted);
    } else {
      await src.copy(destPath);
    }

    await src.delete();
    final current = loadItems();
    current.removeWhere((x) => x.id == item.id || x.storedPath == item.storedPath);
    await saveItems(current);

    return destPath;
  }

  String _normalizePath(String p) {
    final unified = p.replaceAll("\\", "/");
    return path.normalize(unified);
  }

  Future<void> _ensureParentDirsExist(String filePath) async {
    final dirPath = path.dirname(filePath);
    if (dirPath.isEmpty || dirPath == "." || dirPath == "..") return;

    final dir = Directory(dirPath);
    if (await dir.exists()) return;

    await dir.create(recursive: true);
  }

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

  String _extension(String pathStr) {
    final p = pathStr.replaceAll("\\", "/");
    final name = p.split("/").last;
    final dot = name.lastIndexOf(".");
    if (dot < 0) return "";
    return name.substring(dot);
  }

  String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), "_");
    return cleaned.trim().isEmpty ? "file" : cleaned.trim();
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
