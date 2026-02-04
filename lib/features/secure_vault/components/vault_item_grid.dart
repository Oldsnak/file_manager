// lib/features/secure_vault/widgets/vault_item_grid.dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/models/vault_item.dart';

class VaultItemGrid extends StatelessWidget {
  const VaultItemGrid({
    super.key,
    required this.item,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final VaultItem item;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withOpacity(0.65),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(
              item: item,
              isSelected: isSelected,
              selectionMode: selectionMode,
            ),
            const SizedBox(height: 10),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _TypeChip(type: item.type),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatBytes(item.sizeBytes),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.80),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.item,
    required this.isSelected,
    required this.selectionMode,
  });

  final VaultItem item;
  final bool isSelected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: theme.colorScheme.primary.withOpacity(0.08),
              child: _buildPreview(theme),
            ),
          ),
        ),

        // Selection check (top-right)
        if (selectionMode)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              height: 26,
              width: 26,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor.withOpacity(0.7),
                ),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.circle_outlined,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.textTheme.bodyMedium?.color?.withOpacity(0.70),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme) {
    if (item.isImage && item.storedPath.isNotEmpty) {
      final f = File(item.storedPath);
      if (f.existsSync()) {
        return Image.file(
          f,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(theme),
        );
      }
    }

    // For videos/docs/audios/others we show icons
    return _fallbackIcon(theme);
  }

  Widget _fallbackIcon(ThemeData theme) {
    return Center(
      child: Icon(
        _iconForType(item.type),
        size: 42,
        color: theme.colorScheme.primary.withOpacity(0.85),
      ),
    );
  }

  IconData _iconForType(VaultItemType type) {
    switch (type) {
      case VaultItemType.image:
        return Icons.image_rounded;
      case VaultItemType.video:
        return Icons.play_circle_fill_rounded;
      case VaultItemType.audio:
        return Icons.music_note_rounded;
      case VaultItemType.document:
        return Icons.description_rounded;
      case VaultItemType.other:
        return Icons.insert_drive_file_rounded;
    }
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final VaultItemType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final label = switch (type) {
      VaultItemType.image => "Image",
      VaultItemType.video => "Video",
      VaultItemType.audio => "Audio",
      VaultItemType.document => "Doc",
      VaultItemType.other => "File",
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.primary.withOpacity(0.12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return "0 B";
  const k = 1024.0;
  final kb = bytes / k;
  if (kb < 1) return "$bytes B";
  final mb = kb / k;
  if (mb < 1) return "${kb.toStringAsFixed(0)} KB";
  final gb = mb / k;
  if (gb < 1) return "${mb.toStringAsFixed(1)} MB";
  final tb = gb / k;
  if (tb < 1) return "${gb.toStringAsFixed(2)} GB";
  return "${tb.toStringAsFixed(2)} TB";
}
