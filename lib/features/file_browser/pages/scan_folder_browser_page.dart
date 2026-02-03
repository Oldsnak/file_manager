import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

import '../../../core/controllers/file_browser_controller.dart';
import '../components/item_grid.dart';
import '../components/item_tile.dart';
import '../components/sort_sheet.dart';
import '../components/view_toggle.dart';
import 'file_scan_page.dart';

class ScanFolderBrowserPage extends StatefulWidget {
  const ScanFolderBrowserPage({
    super.key,
    required this.title,
    required this.category,
    required this.folderPath,
  });

  final String title;
  final ScanCategory category;
  final String folderPath;

  @override
  State<ScanFolderBrowserPage> createState() => _ScanFolderBrowserPageState();
}

class _ScanFolderBrowserPageState extends State<ScanFolderBrowserPage> {
  late final FileBrowserController c;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    c = Get.find<FileBrowserController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.initForScan(widget.category, folderPath: widget.folderPath);
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
    final dark = THelperFunctions.isDarkMode(context);
    final iconColor = dark ? TColors.textWhite : TColors.textPrimary;

    return Obx(() {
      final inSelection = c.selectionMode.value;
      final selectedCount = c.selectedIds.length;

      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: Text(
            inSelection ? "$selectedCount selected" : widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: dark ? TColors.textWhite : TColors.textPrimary,
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
              IconButton(icon: Icon(Icons.sort, color: iconColor), onPressed: () => showSortSheet(context)),
              const ViewToggle(),
            ] else ...[
              IconButton(icon: Icon(Icons.select_all, color: iconColor), onPressed: c.selectAll),
              IconButton(icon: const Icon(Icons.delete_outline, color: TColors.error), onPressed: c.deleteSelected),
            ],
          ],
        ),
        body: _buildBody(context, dark),
      );
    });
  }

  Widget _buildBody(BuildContext context, bool dark) {
    return Obx(() {
      if (c.isLoading.value) {
        return Center(child: CircularProgressIndicator(color: TColors.primary));
      }
      if (c.items.isEmpty) {
        return const Center(child: Text("No items in this folder"));
      }

      final isGrid = c.viewMode.value == ViewMode.grid;

      return RefreshIndicator(
        onRefresh: c.refresh,
        color: TColors.primary,
        child: Stack(
          children: [
            isGrid
                ? GridView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              separatorBuilder: (_, __) => const SizedBox(height: TSizes.sm),
              itemBuilder: (_, i) => ItemTile(item: c.items[i]),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Obx(() => c.isLoadingMore.value
                  ? Center(child: CircularProgressIndicator(color: TColors.primary))
                  : const SizedBox.shrink()),
            ),
          ],
        ),
      );
    });
  }
}
