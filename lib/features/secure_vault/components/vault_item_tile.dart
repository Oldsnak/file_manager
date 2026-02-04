// lib/features/secure_vault/widgets/vault_item_tile.dart
import 'package:flutter/material.dart';

import '../../../core/models/vault_item.dart';

class VaultItemTile extends StatelessWidget {
  const VaultItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    this.onMore,
  });

  final VaultItem item;
  final bool isSelected;
  final bool selectionMode;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// optional 3-dots action (bottom sheet etc.)
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color bg = theme.colorScheme.surfaceContainerHighest.withOpacity(0.55);
    final Color borderIdle = theme.dividerColor.withOpacity(0.70);
    final Color borderActive = theme.colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? borderActive : borderIdle,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            _LeadingIcon(
              type: item.type,
              isSelected: isSelected,
              selectionMode: selectionMode,
            ),
            const SizedBox(width: 12),

            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _labelForType(item.type),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatBytes(item.sizeBytes),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // trailing
            if (selectionMode)
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor.withOpacity(0.8),
              )
            else
              IconButton(
                splashRadius: 20,
                icon: Icon(
                  Icons.more_vert,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                ),
                onPressed: onMore,
                tooltip: "More",
              ),
          ],
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.type,
    required this.isSelected,
    required this.selectionMode,
  });

  final VaultItemType type;
  final bool isSelected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color bg = theme.colorScheme.primary.withOpacity(0.10);
    final Color iconColor = theme.colorScheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.18),
            ),
          ),
          child: Icon(_iconForType(type), color: iconColor),
        ),

        // small check badge on selection mode
        if (selectionMode)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              height: 22,
              width: 22,
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
                size: 14,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.textTheme.bodyMedium?.color?.withOpacity(0.65),
              ),
            ),
          ),
      ],
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

String _labelForType(VaultItemType type) {
  switch (type) {
    case VaultItemType.image:
      return "Image";
    case VaultItemType.video:
      return "Video";
    case VaultItemType.audio:
      return "Audio";
    case VaultItemType.document:
      return "Document";
    case VaultItemType.other:
      return "File";
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
