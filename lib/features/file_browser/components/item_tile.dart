// lib/features/file_browser/components/item_tile.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/file_browser_controller.dart';
import '../../../core/controllers/vault_controller.dart';
import '../../../core/models/browser_item.dart';
import '../../../core/models/vault_item.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';
import '../../secure_vault/components/vault_actions_sheet.dart';
import '../../secure_vault/vault_opener.dart';
import 'file_actions_sheet.dart';

class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    this.item,
    this.vaultItem,
  }) : assert(
          (item == null) != (vaultItem == null),
          'Provide exactly one of item or vaultItem',
        );

  final BrowserItem? item;
  final VaultItem? vaultItem;

  bool get _isVaultMode => vaultItem != null;

  IconData _iconForVault(VaultItem v) {
    switch (v.type) {
      case VaultItemType.video:
        return Icons.video_file;
      case VaultItemType.audio:
        return Icons.audiotrack;
      case VaultItemType.image:
        return Icons.image;
      case VaultItemType.document:
      case VaultItemType.other:
        return Icons.insert_drive_file;
    }
  }

  IconData _iconForBrowser(BrowserItem it) {
    if (it.isVideo) return Icons.video_file;
    if (it.isAudio) return Icons.audiotrack;
    return Icons.image;
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    final Color tileBg = dark ? TColors.darkContainer : TColors.lightContainer;
    final Color borderIdle = dark ? TColors.darkerGrey : TColors.grey;
    final Color titleColor = dark ? TColors.textWhite : TColors.textPrimary;
    final Color subtitleColor = dark ? TColors.darkGrey : TColors.textSecondary;
    final Color iconColor = dark ? TColors.darkPrimary : TColors.primary;

    if (_isVaultMode) {
      final v = vaultItem!;
      final vc = Get.find<VaultController>();
      return Obx(() {
        final selected = vc.selectedIds.contains(v.id);
        final inSelection = vc.selectionMode.value;

        return Container(
          margin: const EdgeInsets.only(bottom: TSizes.xs),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(TSizes.cardRdiusMd),
            border: Border.all(
              width: selected ? 2 : 1,
              color: selected ? TColors.primary : borderIdle,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: TColors.primary.withOpacity(0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TSizes.md,
              vertical: TSizes.xs,
            ),
            leading: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: dark
                        ? TColors.darkOptionalContainer
                        : TColors.lightOptionalContainer,
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                  ),
                  child: Icon(_iconForVault(v), color: iconColor),
                ),
                if (inSelection)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: selected ? TColors.primary : borderIdle,
                    ),
                  ),
              ],
            ),
            title: Text(
              v.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            subtitle: Text(
              "${v.sizeMB.toStringAsFixed(2)} MB",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: subtitleColor,
                  ),
            ),
            onTap: () {
              if (inSelection) {
                vc.toggleSelection(v.id);
              } else {
                openVaultItemInApp(context, v);
              }
            },
            onLongPress: () {
              if (!inSelection) {
                vc.startSelection(v.id);
              } else {
                vc.toggleSelection(v.id);
              }
            },
            trailing: inSelection
                ? null
                : IconButton(
                    splashRadius: 20,
                    icon: Icon(
                      Icons.more_vert,
                      color: dark ? TColors.textWhite : TColors.textPrimary,
                    ),
                    onPressed: () => showVaultActionsSheet(context, v),
                  ),
          ),
        );
      });
    }

    final it = item!;
    final c = Get.find<FileBrowserController>();
    return Obx(() {
      final selected = c.selectedIds.contains(it.id);
      final inSelection = c.selectionMode.value;

      return Container(
        margin: const EdgeInsets.only(bottom: TSizes.xs),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(TSizes.cardRdiusMd),
          border: Border.all(
            width: selected ? 2 : 1,
            color: selected ? TColors.primary : borderIdle,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: TColors.primary.withOpacity(0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: TSizes.md,
            vertical: TSizes.xs,
          ),
          leading: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: dark
                      ? TColors.darkOptionalContainer
                      : TColors.lightOptionalContainer,
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                ),
                child: Icon(_iconForBrowser(it), color: iconColor),
              ),
              if (inSelection)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? TColors.primary : borderIdle,
                  ),
                ),
            ],
          ),
          title: Text(
            it.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Text(
            "${it.sizeMB.toStringAsFixed(2)} MB",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                ),
          ),
          onTap: () {
            if (inSelection) {
              c.toggleSelection(it.id);
            } else {
              c.openItem(it);
            }
          },
          onLongPress: () {
            if (!inSelection) {
              c.startSelection(it.id);
            } else {
              c.toggleSelection(it.id);
            }
          },
          trailing: inSelection
              ? null
              : IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    Icons.more_vert,
                    color: dark ? TColors.textWhite : TColors.textPrimary,
                  ),
                  onPressed: () => showFileActionsSheet(context, it),
                ),
        ),
      );
    });
  }
}
