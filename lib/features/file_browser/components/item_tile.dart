// lib/features/file_browser/components/item_tile.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/file_browser_controller.dart';
import '../../../core/models/browser_item.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';
import 'file_actions_sheet.dart';

class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item});

  final BrowserItem item;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FileBrowserController>();
    final dark = THelperFunctions.isDarkMode(context);

    final Color tileBg = dark ? TColors.darkContainer : TColors.lightContainer;
    final Color borderIdle = dark ? TColors.darkerGrey : TColors.grey;
    final Color titleColor = dark ? TColors.textWhite : TColors.textPrimary;
    final Color subtitleColor = dark ? TColors.darkGrey : TColors.textSecondary;
    final Color iconColor = dark ? TColors.darkPrimary : TColors.primary;

    IconData getIcon() {
      if (item.isVideo) return Icons.video_file;
      if (item.isAudio) return Icons.audiotrack;
      return Icons.image;
    }

    return Obx(() {
      final selected = c.selectedIds.contains(item.id);
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
                child: Icon(getIcon(), color: iconColor),
              ),

              if (inSelection)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Icon(
                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? TColors.primary : borderIdle,
                  ),
                ),
            ],
          ),

          title: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
          ),

          subtitle: Text(
            "${item.sizeMB.toStringAsFixed(2)} MB",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: subtitleColor,
            ),
          ),

          // ✅ Tap: selection mode me toggle, otherwise open
          onTap: () {
            if (inSelection) {
              c.toggleSelection(item.id);
            } else {
              c.openItem(item);
            }
          },

          onLongPress: () {
            if (!inSelection) {
              c.startSelection(item.id);
            } else {
              c.toggleSelection(item.id);
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
            onPressed: () => showFileActionsSheet(context, item),
          ),
        ),
      );
    });
  }
}
