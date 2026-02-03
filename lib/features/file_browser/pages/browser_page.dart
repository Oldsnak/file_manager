// lib/features/file_browser/pages/browser_page.dart

import 'package:file_manager/foundation/constants/colors.dart';
import 'package:file_manager/foundation/constants/sizes.dart';
import 'package:file_manager/foundation/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/controllers/file_browser_controller.dart';
import '../components/item_grid.dart';
import '../components/item_tile.dart';
import '../components/sort_sheet.dart';
import '../components/view_toggle.dart';
import 'folders_page.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({
    super.key,
    required this.title,
    required this.type,
  });

  final String title;
  final RequestType type;

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final FileBrowserController c;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    c = Get.find<FileBrowserController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.initForMedia(widget.type);
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
    final Color accent = TColors.primary; // your brand accent

    return Obx(() {
      final inSelection = c.selectionMode.value;
      final selectedCount = c.selectedIds.length;

      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,

          // ✅ no fixed foregroundColor; we set icon/text explicitly
          title: inSelection
              ? Text(
            "$selectedCount selected",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: titleColor, fontWeight: FontWeight.w600),
          )
              : Text(
            widget.title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: titleColor, fontWeight: FontWeight.w600),
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
                icon: Icon(Icons.folder, color: iconColor),
                tooltip: "Folders",
                onPressed: () => Get.to(
                      () => FoldersPage(
                    title: "${widget.title} Folders",
                    type: widget.type,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.sort, color: iconColor),
                onPressed: () => showSortSheet(context),
              ),
              const ViewToggle(),
            ] else ...[
              IconButton(
                icon: Icon(Icons.select_all, color: iconColor),
                tooltip: "Select All",
                onPressed: c.selectAll,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: TColors.error),
                tooltip: "Delete Selected",
                onPressed: c.deleteSelected,
              ),
            ]
          ],
        ),
        body: _buildBody(context, dividerColor, accent, dark),
      );
    });
  }

  Widget _buildBody(
      BuildContext context,
      Color dividerColor,
      Color accent,
      bool dark,
      ) {
    return Obx(() {
      if (c.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(
            color: accent,
          ),
        );
      }

      if (c.items.isEmpty) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? TColors.darkContainer : TColors.lightContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark ? TColors.darkGrey : TColors.grey,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open, size: 48, color: accent),
                const SizedBox(height: 8),
                Text(
                  "No files found",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: dark ? TColors.textWhite : TColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
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
              padding: const EdgeInsets.all(12),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: c.items.length,
              itemBuilder: (_, i) => ItemGrid(item: c.items[i]),
            )
                : ListView.separated(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: c.items.length,
              separatorBuilder: (_, __) => SizedBox(height: TSizes.sm,),
              itemBuilder: (_, i) => ItemTile(item: c.items[i]),
            ),

            // Loading more indicator
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Obx(
                    () => c.isLoadingMore.value
                    ? Center(
                  child: CircularProgressIndicator(color: accent),
                )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      );
    });
  }
}
