import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

import '../../../core/controllers/file_browser_controller.dart';
import '../../../core/models/browser_item.dart';
import '../../../core/services/media_service.dart';
import 'file_actions_sheet.dart';

class ItemGrid extends StatefulWidget {
  const ItemGrid({super.key, required this.item});
  final BrowserItem item;

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
    // ✅ thumbnails only for gallery items
    if (!widget.item.isFromGallery) return;

    final media = Get.find<MediaService>();
    final bytes = await media.getThumbnailBytes(widget.item.id, size: 250);
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

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FileBrowserController>();
    final dark = THelperFunctions.isDarkMode(context);

    final Color cardBg = dark ? TColors.darkContainer : TColors.lightContainer;
    final Color borderIdle = dark ? TColors.darkerGrey : TColors.grey;
    final Color borderSelected = TColors.primary;
    final Color iconColor = dark ? TColors.textWhite : TColors.textPrimary;

    return Obx(() {
      final selected = c.selectedIds.contains(widget.item.id);
      final inSelection = c.selectionMode.value;

      return GestureDetector(
        onTap: () {
          // ✅ IMPORTANT UX FIX
          if (inSelection) {
            c.toggleSelection(widget.item.id);
          } else {
            c.openItem(widget.item);
          }
        },
        onLongPress: () {
          if (!inSelection) {
            c.startSelection(widget.item.id);
          } else {
            c.toggleSelection(widget.item.id);
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
                      borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                      child: thumb != null
                          ? Image.memory(
                        thumb!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                          : Center(
                        child: Icon(
                          _iconForItem(widget.item),
                          size: 34,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: TSizes.xs),
                  Text(
                    widget.item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // ✅ Selection indicator
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

              // ✅ Quick actions (only when NOT selecting)
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
                        showFileActionsSheet(context, widget.item),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
