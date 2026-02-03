// lib/features/file_browser/pages/album_browser_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/controllers/file_browser_controller.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';
import '../components/item_grid.dart';
import '../components/item_tile.dart';
import '../components/sort_sheet.dart';
import '../components/view_toggle.dart';

class AlbumBrowserPage extends StatefulWidget {
  const AlbumBrowserPage({
    super.key,
    required this.album,
    required this.type,
    required this.title,
  });

  final AssetPathEntity album;
  final RequestType type;
  final String title;

  @override
  State<AlbumBrowserPage> createState() => _AlbumBrowserPageState();
}

class _AlbumBrowserPageState extends State<AlbumBrowserPage> {
  late final FileBrowserController c;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    c = Get.find<FileBrowserController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.initForMedia(widget.type, album: widget.album);
    });

    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        c.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = THelperFunctions.isDarkMode(context);

    // ✅ theme-based colors
    final Color iconColor = dark ? TColors.textWhite : TColors.textPrimary;
    final Color titleColor = dark ? TColors.textWhite : TColors.textPrimary;
    final Color dividerColor = dark ? TColors.darkGrey : TColors.grey;
    final Color accent = TColors.primary;

    return Obx(() {
      final inSelection = c.selectionMode.value;
      final selectedCount = c.selectedIds.length;

      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,

          title: inSelection
              ? Text(
            "$selectedCount selected",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
          )
              : Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
          ),

          leading: inSelection
              ? IconButton(
            icon: Icon(Icons.close, color: iconColor),
            onPressed: c.clearSelection,
          )
              : null,

          actions: [
            if (!inSelection) ...[
              IconButton(
                icon: Icon(Icons.sort, color: iconColor),
                onPressed: () => showSortSheet(context),
              ),
              const ViewToggle(),
            ] else ...[
              IconButton(
                icon: Icon(Icons.select_all, color: iconColor),
                onPressed: c.selectAll,
                tooltip: "Select All",
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: TColors.error),
                onPressed: c.deleteSelected,
                tooltip: "Delete Selected",
              ),
            ],
          ],
        ),

        body: Obx(() {
          if (c.isLoading.value) {
            return Center(child: CircularProgressIndicator(color: accent));
          }

          if (c.items.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(TSizes.md),
                margin: const EdgeInsets.all(TSizes.defaultSpace),
                decoration: BoxDecoration(
                  color: dark ? TColors.darkContainer : TColors.lightContainer,
                  borderRadius: BorderRadius.circular(TSizes.cardRdiusLg),
                  border: Border.all(
                    color: dark ? TColors.darkGrey : TColors.grey,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open, size: 48, color: accent),
                    const SizedBox(height: TSizes.sm),
                    Text(
                      "No items in this folder",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: dark ? TColors.textWhite : TColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: TSizes.md),
                    ElevatedButton(
                      onPressed: c.refresh,
                      child: const Text("Refresh"),
                    ),
                  ],
                ),
              ),
            );
          }

          final isGrid = c.viewMode.value == ViewMode.grid;

          return RefreshIndicator(
            color: accent,
            backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
            onRefresh: c.refresh,
            child: Stack(
              children: [
                isGrid
                    ? GridView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(TSizes.md),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: TSizes.sm,
                    mainAxisSpacing: TSizes.sm,
                  ),
                  itemCount: c.items.length,
                  itemBuilder: (_, i) => ItemGrid(item: c.items[i]),
                )
                    : ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.all(TSizes.md),
                  itemCount: c.items.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: TSizes.sm,),
                  itemBuilder: (_, i) => ItemTile(item: c.items[i]),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: TSizes.sm,
                  child: Obx(
                        () => c.isLoadingMore.value
                        ? Center(child: CircularProgressIndicator(color: accent))
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          );
        }),
      );
    });
  }
}
