// lib/features/secure_vault/widgets/vault_actions_sheet.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/models/vault_item.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

import '../../../core/controllers/vault_controller.dart';

void showVaultActionsSheet(
    BuildContext context,
    VaultItem item, {
      bool showUnlock = true,
      bool showDelete = true,
      bool showDetails = true,
    }) {
  final c = Get.find<VaultController>();
  final bool dark = THelperFunctions.isDarkMode(context);

  final Color bgColor = dark ? TColors.darkContainer : TColors.lightContainer;
  final Color textColor = dark ? TColors.textWhite : TColors.textPrimary;
  final Color subTextColor = dark ? TColors.darkGrey : TColors.textSecondary;
  final Color dividerColor = dark ? TColors.darkGrey : TColors.grey;
  final Color accent = TColors.primary;

  showModalBottomSheet(
    context: context,
    backgroundColor: bgColor,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TSizes.cardRdiusLg),
      ),
    ),
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: TSizes.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---------- INFO HEADER ----------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.defaultSpace,
                  vertical: TSizes.sm,
                ),
                child: Row(
                  children: [
                    _TypeIconBox(
                      type: item.type,
                      accent: accent,
                      dark: dark,
                    ),
                    const SizedBox(width: TSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_labelForType(item.type)} • ${_formatBytes(item.sizeBytes)}",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: subTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: dividerColor),

              // ---------- OPEN ----------
              _ActionTile(
                icon: _openIconForType(item.type),
                iconColor: accent,
                title: item.isVideo ? "Play" : "Open",
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  _openVaultFile(item);
                },
              ),

              // ---------- UNLOCK / RESTORE ----------
              if (showUnlock)
                _ActionTile(
                  icon: Icons.lock_open_rounded,
                  iconColor: accent,
                  title: "Unlock / Restore",
                  textColor: textColor,
                  onTap: () async {
                    Navigator.pop(context);
                    await _confirmAndUnlock(context, c, item);
                  },
                ),

              // ---------- DETAILS ----------
              if (showDetails)
                _ActionTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: subTextColor,
                  title: "Details",
                  textColor: textColor,
                  onTap: () {
                    Navigator.pop(context);
                    _showDetailsDialog(context, item, dark);
                  },
                ),

              // ---------- DELETE ----------
              if (showDelete)
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: TColors.error,
                  title: "Delete from Vault",
                  textColor: textColor,
                  onTap: () async {
                    Navigator.pop(context);
                    final ok = await _confirmDelete(context, dark);
                    if (!ok) return;

                    final success = await c.deleteItem(item);
                    if (success) {
                      THelperFunctions.showSnackBar("Deleted");
                    } else {
                      THelperFunctions.showSnackBar("Delete failed");
                    }
                  },
                ),

              const SizedBox(height: TSizes.xs),
            ],
          ),
        ),
      );
    },
  );
}

// =============================================================
// HELPERS
// =============================================================

Future<void> _openVaultFile(VaultItem item) async {
  try {
    final f = File(item.storedPath);
    if (!await f.exists()) {
      THelperFunctions.showSnackBar("File not found");
      return;
    }

    // Using your existing open_filex dependency.
    // We keep it simple: open by OS registered apps.
    // (No extra service needed; but you can route via a service later.)
    // ignore: depend_on_referenced_packages
    final result = await OpenFilex.open(item.storedPath);
    if (result.type != ResultType.done) {
      // Some devices return "noAppToOpen"
      // ignore it but show message
      // result.message can be empty sometimes
      THelperFunctions.showSnackBar("Can't open file");
    }
  } catch (_) {
    THelperFunctions.showSnackBar("Can't open file");
  }
}

Future<void> _confirmAndUnlock(BuildContext context, VaultController c, VaultItem item) async {
  final bool dark = THelperFunctions.isDarkMode(context);

  final ok = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
        title: Text(
          "Unlock file?",
          style: TextStyle(color: dark ? TColors.textWhite : TColors.textPrimary),
        ),
        content: Text(
          "This will restore the file back to its original location (if available).",
          style: TextStyle(color: dark ? TColors.textWhite : TColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Unlock"),
          ),
        ],
      );
    },
  );

  if (ok != true) return;

  final restored = await c.unlockItem(item);

  if (restored != null && restored.isNotEmpty) {
    THelperFunctions.showSnackBar("Unlocked");
  } else {
    THelperFunctions.showSnackBar("Unlock failed");
  }
}

Future<bool> _confirmDelete(BuildContext context, bool dark) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
        title: Text(
          "Delete from Vault?",
          style: TextStyle(color: dark ? TColors.textWhite : TColors.textPrimary),
        ),
        content: Text(
          "This will permanently delete the file from Secure Vault.",
          style: TextStyle(color: dark ? TColors.textWhite : TColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      );
    },
  );

  return ok == true;
}

void _showDetailsDialog(BuildContext context, VaultItem item, bool dark) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
        title: Text(
          "File details",
          style: TextStyle(color: dark ? TColors.textWhite : TColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv(context, "Name", item.name, dark),
            _kv(context, "Type", _labelForType(item.type), dark),
            _kv(context, "Size", _formatBytes(item.sizeBytes), dark),
            _kv(context, "Modified", item.modified.toString(), dark),
            _kv(context, "Stored Path", item.storedPath, dark),
            if (item.originalPath != null && item.originalPath!.isNotEmpty)
              _kv(context, "Original Path", item.originalPath!, dark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}

Widget _kv(BuildContext context, String k, String v, bool dark) {
  final kStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
    fontWeight: FontWeight.w800,
    color: dark ? TColors.textWhite : TColors.textPrimary,
  );
  final vStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
    fontWeight: FontWeight.w600,
    color: dark ? TColors.darkGrey : TColors.textSecondary,
  );

  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: kStyle),
        const SizedBox(height: 2),
        Text(
          v,
          style: vStyle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

IconData _openIconForType(VaultItemType type) {
  switch (type) {
    case VaultItemType.video:
      return Icons.play_circle_fill_rounded;
    case VaultItemType.audio:
      return Icons.play_arrow_rounded;
    case VaultItemType.image:
      return Icons.open_in_new_rounded;
    case VaultItemType.document:
      return Icons.open_in_new_rounded;
    case VaultItemType.other:
      return Icons.open_in_new_rounded;
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

class _TypeIconBox extends StatelessWidget {
  const _TypeIconBox({
    required this.type,
    required this.accent,
    required this.dark,
  });

  final VaultItemType type;
  final Color accent;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final Color bg = dark ? TColors.darkPrimaryContainer : TColors.lightPrimaryContainer;

    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Icon(_iconForType(type), color: accent),
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

/// ------------------------------------------------------------
/// Reusable action tile (clean & consistent)
/// ------------------------------------------------------------
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TSizes.defaultSpace,
          vertical: TSizes.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: TSizes.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// open_filex import (kept at bottom to avoid clutter)
// =============================================================

// ignore: depend_on_referenced_packages

