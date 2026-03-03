// lib/features/file_browser/components/file_actions_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/file_browser_controller.dart';
import '../../../core/models/browser_item.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

void _showRenameDialog(
  BuildContext context,
  FileBrowserController c,
  BrowserItem item,
  Color textColor,
  Color subTextColor,
  Color accent,
) {
  final controller = TextEditingController(text: item.name);

  showDialog<String?>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text("Rename File"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter new name",
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text("Rename"),
          ),
        ],
      );
    },
  ).then((value) {
    if (value == null) return;
    final newName = value.trim();
    if (newName.isEmpty) {
      THelperFunctions.showSnackBar("Name cannot be empty");
      return;
    }
    if (newName.contains(RegExp(r'[/\\]'))) {
      THelperFunctions.showSnackBar("Name cannot contain / or \\");
      return;
    }
    if (item.isFromGallery) {
      THelperFunctions.showSnackBar("Rename is not available for gallery items");
      return;
    }
    c.renameItem(item, newName).then((ok) {
      if (ok) {
        THelperFunctions.showSnackBar("Renamed to $newName");
      } else {
        THelperFunctions.showSnackBar("Failed to rename file");
      }
    });
  });
}

void showFileActionsSheet(BuildContext context, BrowserItem item) {
  final c = Get.find<FileBrowserController>();
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
              // ---------- FILE INFO ----------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.defaultSpace,
                  vertical: TSizes.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: dark
                            ? TColors.darkPrimaryContainer
                            : TColors.lightPrimaryContainer,
                        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                      ),
                      child: Icon(
                        item.isVideo
                            ? Icons.video_file
                            : item.isImage
                            ? Icons.image
                            : item.isAudio
                            ? Icons.audiotrack
                            : Icons.insert_drive_file,
                        color: accent,
                      ),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.sizeMB >= 1024
                                ? "${(item.sizeMB / 1024).toStringAsFixed(2)} GB"
                                : "${item.sizeMB.toStringAsFixed(2)} MB",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: subTextColor,
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
                icon: Icons.play_arrow,
                iconColor: accent,
                title: "Open / Play",
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  c.openItem(item);
                },
              ),

              // Move to Secure Folder: encrypts and stores in app-private storage
              // (visible only in app's Secure Folder, not in device storage)
              _ActionTile(
                icon: Icons.lock_outline,
                iconColor: accent,
                title: "Move to Secure Folder",
                textColor: textColor,
                onTap: () async {
                  Navigator.pop(context);
                  if (item.path.isEmpty && !item.isFromGallery) {
                    THelperFunctions.showSnackBar("File path not available");
                    return;
                  }
                  final ok = await c.moveToSecureVault(item);
                  if (ok) {
                    THelperFunctions.showSnackBar("Moved to Secure Folder");
                  } else {
                    THelperFunctions.showSnackBar("Failed to move to Secure Folder");
                  }
                },
              ),

              // ---------- DELETE ----------
              _ActionTile(
                icon: Icons.delete_outline,
                iconColor: TColors.error,
                title: "Delete",
                textColor: textColor,
                onTap: () async {
                  Navigator.pop(context);
                  await c.deleteItem(item);
                },
              ),

              // ---------- RENAME ----------
              _ActionTile(
                icon: Icons.drive_file_rename_outline,
                iconColor: accent,
                title: "Rename File",
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, c, item, textColor, subTextColor, accent);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
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
  final Color textColor;
  final VoidCallback onTap;
  final String title;

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
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
