import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

import '../../../core/controllers/file_browser_controller.dart';
import '../../../core/models/browser_item.dart';
import '../../../core/models/vault_item.dart';
import '../../../core/services/media_service.dart';
import '../../secure_vault/components/vault_actions_sheet.dart';
import '../../secure_vault/vault_opener.dart';
import '../../../core/controllers/vault_controller.dart';
import 'file_actions_sheet.dart';

class ItemGrid extends StatefulWidget {
  const ItemGrid({
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

  @override
  State<ItemGrid> createState() => _ItemGridState();
}

class _ItemGridState extends State<ItemGrid> {
  Uint8List? thumb;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  Future<void> _loadThumb() async {
    if (widget._isVaultMode) return;
    final it = widget.item!;
    if (!it.isFromGallery) return;

    final media = Get.find<MediaService>();
    final bytes = await media.getThumbnailBytes(it.id, size: 250);
    if (!mounted) return;
    if (bytes != null) {
      setState(() => thumb = Uint8List.fromList(bytes));
    }
  }

  IconData _iconForItem(BrowserItem it) {
    if (it.isVideo) return Icons.videocam;
    if (it.isAudio) return Icons.audiotrack;
    if (it.isImage) return Icons.image;
    return Icons.insert_drive_file;
  }

  IconData _iconForVaultItem(VaultItem it) {
    switch (it.type) {
      case VaultItemType.video:
        return Icons.videocam;
      case VaultItemType.audio:
        return Icons.audiotrack;
      case VaultItemType.image:
        return Icons.image;
      case VaultItemType.document:
      case VaultItemType.other:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    final Color cardBg = dark ? TColors.darkContainer : TColors.lightContainer;
    final Color borderIdle = dark ? TColors.darkerGrey : TColors.grey;
    final Color borderSelected = TColors.primary;
    final Color iconColor = dark ? TColors.textWhite : TColors.textPrimary;

    if (widget._isVaultMode) {
      final v = widget.vaultItem!;
      final vc = Get.find<VaultController>();
      return Obx(() {
        final selected = vc.selectedIds.contains(v.id);
        final inSelection = vc.selectionMode.value;

        return GestureDetector(
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(TSizes.cardRdiusMd),
              border: Border.all(
                width: selected ? 2 : 1,
                color: selected ? borderSelected : borderIdle,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: TColors.primary.withOpacity(0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(TSizes.borderRadiusMd),
                        child: Center(
                          child: Icon(
                            _iconForVaultItem(v),
                            size: 34,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (inSelection)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 22,
                      color: selected ? TColors.primary : borderIdle,
                    ),
                  ),
                if (!inSelection)
                  Positioned(
                    top: -6,
                    left: -6,
                    child: IconButton(
                      splashRadius: 20,
                      icon: Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: iconColor,
                      ),
                      onPressed: () =>
                          showVaultActionsSheet(context, v),
                    ),
                  ),
              ],
            ),
          ),
        );
      });
    }

    final c = Get.find<FileBrowserController>();
    final it = widget.item!;
    return Obx(() {
      final selected = c.selectedIds.contains(it.id);
      final inSelection = c.selectionMode.value;

      return GestureDetector(
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(TSizes.sm),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(TSizes.cardRdiusMd),
            border: Border.all(
              width: selected ? 2 : 1,
              color: selected ? borderSelected : borderIdle,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: TColors.primary.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(TSizes.borderRadiusMd),
                      child: thumb != null
                          ? Image.memory(
                              thumb!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Center(
                              child: Icon(
                                _iconForItem(it),
                                size: 34,
                                color: iconColor,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              if (inSelection)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 22,
                    color: selected ? TColors.primary : borderIdle,
                  ),
                ),
              if (!inSelection)
                Positioned(
                  top: -6,
                  left: -6,
                  child: IconButton(
                    splashRadius: 20,
                    icon: Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: iconColor,
                    ),
                    onPressed: () =>
                        showFileActionsSheet(context, it),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
