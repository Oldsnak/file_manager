// lib/features/secure_vault/components/vault_item_thumbnail.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../core/models/vault_item.dart';
import '../../../core/services/secure_vault_service.dart';

/// Decrypts vault file to a temp path, loads image bytes or video frame, deletes temp.
class VaultItemThumbnail extends StatefulWidget {
  const VaultItemThumbnail({
    super.key,
    required this.item,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final VaultItem item;
  final Widget fallback;
  final BoxFit fit;

  @override
  State<VaultItemThumbnail> createState() => _VaultItemThumbnailState();
}

class _VaultItemThumbnailState extends State<VaultItemThumbnail> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(VaultItemThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.storedPath != widget.item.storedPath) {
      _bytes = null;
      _loading = true;
      _load();
    }
  }

  Future<void> _deleteIfExists(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<void> _load() async {
    final v = widget.item;
    if (!v.isImage && !v.isVideo) {
      if (mounted && !_disposed) {
        setState(() => _loading = false);
      }
      return;
    }

    String? tempPath;
    try {
      final vault = Get.find<SecureVaultService>();
      tempPath = await vault.getDecryptedTempPath(v);
      if (_disposed) {
        await _deleteIfExists(tempPath);
        return;
      }

      Uint8List? bytes;
      if (v.isImage) {
        final f = File(tempPath);
        if (await f.exists()) {
          bytes = await f.readAsBytes();
        }
      } else if (v.isVideo) {
        bytes = await VideoThumbnail.thumbnailData(
          video: tempPath,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 400,
          maxHeight: 400,
          quality: 65,
        );
      }

      await _deleteIfExists(tempPath);
      tempPath = null;

      if (_disposed || !mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } catch (_) {
      if (tempPath != null) {
        await _deleteIfExists(tempPath);
      }
      if (_disposed || !mounted) return;
      setState(() {
        _bytes = null;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
          ),
        ),
      );
    }
    if (_bytes != null && _bytes!.isNotEmpty) {
      return Image.memory(
        _bytes!,
        fit: widget.fit,
        width: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => widget.fallback,
      );
    }
    return widget.fallback;
  }
}
