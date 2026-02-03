// lib/features/file_browser/pages/folders_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/controllers/file_browser_controller.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';
import 'album_browser_page.dart';

class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key, required this.title, required this.type});
  final String title;
  final RequestType type;

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  final c = Get.find<FileBrowserController>();
  final albums = <AssetPathEntity>[].obs;
  final loading = true.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    final data = await c.loadAlbums(widget.type);
    albums.assignAll(data);
    loading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = THelperFunctions.isDarkMode(context);

    final Color cardColor = dark ? TColors.darkContainer : TColors.lightContainer;
    final Color textColor = dark ? TColors.textWhite : TColors.textPrimary;
    final Color subTextColor = dark ? TColors.darkGrey : TColors.textSecondary;
    final Color dividerColor = dark ? TColors.darkGrey : TColors.grey;
    final Color accent = TColors.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(() {
        if (loading.value) {
          return Center(child: CircularProgressIndicator(color: accent));
        }

        if (albums.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(TSizes.md),
              margin: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(TSizes.cardRdiusLg),
                border: Border.all(color: dark ? TColors.darkGrey : TColors.grey),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open, size: 48, color: accent),
                  const SizedBox(height: TSizes.sm),
                  Text(
                    "No folders found",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: TSizes.md),
                  ElevatedButton(onPressed: _load, child: const Text("Refresh")),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(TSizes.md),
          itemCount: albums.length,
          separatorBuilder: (_, __) => SizedBox(height: TSizes.sm,),
          itemBuilder: (_, i) {
            final a = albums[i];

            return InkWell(
              borderRadius: BorderRadius.circular(TSizes.cardRdiusMd),
              onTap: () => Get.to(
                    () => AlbumBrowserPage(
                  album: a,
                  type: widget.type,
                  title: a.name,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.md,
                  vertical: TSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(TSizes.cardRdiusMd),
                  border: Border.all(
                    color: dark ? TColors.darkerGrey : TColors.softGrey,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: dark ? TColors.darkPrimaryContainer : TColors.lightPrimaryContainer,
                        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                      ),
                      child: Icon(Icons.folder, color: accent),
                    ),
                    const SizedBox(width: TSizes.md),

                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FutureBuilder<int>(
                            future: a.assetCountAsync,
                            builder: (_, snap) {
                              final count = snap.data ?? 0;
                              return Text(
                                "$count items",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: subTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
