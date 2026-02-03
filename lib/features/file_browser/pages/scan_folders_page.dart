import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/file_scan_service.dart';
import '../../../core/controllers/file_browser_controller.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';
import 'file_scan_page.dart';

class ScanFoldersPage extends StatefulWidget {
  const ScanFoldersPage({
    super.key,
    required this.title,
    required this.category,
  });

  final String title;
  final ScanCategory category;

  @override
  State<ScanFoldersPage> createState() => _ScanFoldersPageState();
}

class _ScanFoldersPageState extends State<ScanFoldersPage> {
  final c = Get.find<FileBrowserController>();

  final loading = true.obs;
  final folders = <ScanFolder>[].obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    final data = await c.loadScanFolders(widget.category);
    folders.assignAll(data);
    loading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: dark ? TColors.textWhite : TColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Obx(() {
        if (loading.value) {
          return Center(
            child: CircularProgressIndicator(color: TColors.primary),
          );
        }

        if (folders.isEmpty) {
          return const Center(child: Text("No folders found"));
        }

        return RefreshIndicator(
          onRefresh: _load,
          color: TColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            itemCount: folders.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: dark ? TColors.darkGrey : TColors.grey,
            ),
            itemBuilder: (_, i) {
              final f = folders[i];
              return ListTile(
                leading: Icon(Icons.folder, color: TColors.primary),
                title: Text(
                  f.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: dark ? TColors.textWhite : TColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  "${f.count} items",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: TColors.textSecondary),
                ),
                trailing: Icon(Icons.arrow_forward_ios_outlined,
                    size: 14, color: dark ? TColors.textWhite : TColors.textPrimary),
                onTap: () {
                  Get.to(() => ScanFolderItemsPage(
                    title: f.name,
                    category: widget.category,
                    folderPath: f.path,
                  ));
                },
              );
            },
          ),
        );
      }),
    );
  }
}

class ScanFolderItemsPage extends StatefulWidget {
  const ScanFolderItemsPage({
    super.key,
    required this.title,
    required this.category,
    required this.folderPath,
  });

  final String title;
  final ScanCategory category;
  final String folderPath;

  @override
  State<ScanFolderItemsPage> createState() => _ScanFolderItemsPageState();
}

class _ScanFolderItemsPageState extends State<ScanFolderItemsPage> {
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
    // reuse same FileScanPage UI/behavior
    return FileScanPage(title: widget.title, category: widget.category);
  }
}
