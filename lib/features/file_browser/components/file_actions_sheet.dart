// lib/features/file_browser/components/file_actions_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/file_browser_controller.dart';
import '../../../core/models/browser_item.dart';
import '../../../core/services/secure_vault_service.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

// ✅ Vault entry (handles: setup OR unlock, then returns true)
import '../../secure_vault/pages/vault_entry_page.dart';

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

              // ✅ MOVE TO SECURE FOLDER (NEW)
              _ActionTile(
                icon: Icons.lock_outline,
                iconColor: accent,
                title: "Move to Secure Folder",
                textColor: textColor,
                onTap: () async {
                  Navigator.pop(context);

                  if (item.path.isEmpty) {
                    THelperFunctions.showSnackBar("File path not available");
                    return;
                  }

                  // 1) Ensure vault is setup/unlocked (VaultEntryPage handles both)
                  final ok = await Get.to<bool>(() => const VaultEntryPage());
                  if (ok != true) return;

                  // 2) Lock file into vault
                  try {
                    final vault = Get.find<SecureVaultService>();
                    await vault.lockFile(item.path);

                    // 3) Remove original from list / gallery
                    if (item.isFromGallery) {
                      // removes from MediaStore (privacy)
                      await c.deleteItem(item);
                    } else {
                      c.items.removeWhere((x) => x.id == item.id);
                      c.selectedIds.remove(item.id);
                      if (c.selectedIds.isEmpty) c.selectionMode.value = false;
                    }

                    THelperFunctions.showSnackBar("Moved to Secure Folder");
                  } catch (_) {
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

              // ---------- RENAME (COMING SOON) ----------
              _ActionTile(
                icon: Icons.drive_file_rename_outline,
                iconColor: subTextColor,
                title: "Rename (Coming soon)",
                textColor: subTextColor,
                onTap: () => Navigator.pop(context),
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
