// lib/features/file_browser/pages/internal_storage_tree_page.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../../../core/controllers/file_browser_controller.dart';
import '../../../core/models/browser_item.dart';
import '../../../core/services/file_scan_service.dart';
import '../../../core/services/internal_archive_service.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

/// Internal storage browser: one page per folder level. Folder tiles match
/// [FoldersPage]; tapping a folder opens a new page with its children.
class InternalStorageTreePage extends StatefulWidget {
  const InternalStorageTreePage({
    super.key,
    required this.directoryPath,
    this.title,
  });

  static const String androidDefaultRoot = '/storage/emulated/0';

  final String directoryPath;
  final String? title;

  @override
  State<InternalStorageTreePage> createState() => _InternalStorageTreePageState();
}

enum _CompressFormat { zip, tarGz, tar }

class _InternalStorageTreePageState extends State<InternalStorageTreePage> {
  final FileScanService _scan = Get.find<FileScanService>();

  DirectoryLevelListing? _listing;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _scan.listDirectoryLevel(widget.directoryPath);
      if (!mounted) return;
      setState(() {
        _listing = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _listing = null;
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String get _displayTitle {
    if (widget.title != null && widget.title!.trim().isNotEmpty) {
      return widget.title!.trim();
    }
    return _treeBasename(widget.directoryPath);
  }

  void _openFolder(BuildContext context, String path) {
    final name = _treeBasename(path);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => InternalStorageTreePage(
          directoryPath: path,
          title: name,
        ),
      ),
    );
  }

  Future<String?> _promptArchiveFileName(BuildContext context, {required String initial}) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive file name'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            hintText: 'File name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _runArchiveJob(
    BuildContext context, {
    required String progressMessage,
    required Future<void> Function() work,
    required String successMessage,
  }) async {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: TSizes.md),
              Expanded(child: Text(progressMessage)),
            ],
          ),
        ),
      ),
    );
    try {
      await work();
      if (!mounted || !context.mounted) return;
      Navigator.of(context).pop();
      THelperFunctions.showSnackBar(successMessage);
      await _load();
    } catch (e) {
      if (!mounted || !context.mounted) return;
      Navigator.of(context).pop();
      THelperFunctions.showSnackBar('Failed: $e');
    }
  }

  Future<void> _startFolderCompress(BuildContext context, String folderPath, _CompressFormat format) async {
    final destDir = await FilePicker.platform.getDirectoryPath();
    if (!mounted || !context.mounted || destDir == null || destDir.trim().isEmpty) return;

    final ext = switch (format) {
      _CompressFormat.zip => '.zip',
      _CompressFormat.tarGz => '.tar.gz',
      _CompressFormat.tar => '.tar',
    };
    final base = _treeBasename(folderPath);
    final suggested = InternalArchiveService.sanitizeArchiveFileName(base, ext);

    if (!mounted || !context.mounted) return;
    final entered = await _promptArchiveFileName(context, initial: suggested);
    if (!mounted || !context.mounted || entered == null || entered.isEmpty) return;

    final safeName = InternalArchiveService.sanitizeArchiveFileName(entered, ext);
    final outPath = p.join(destDir, safeName);

    if (await File(outPath).exists()) {
      if (!context.mounted) return;
      THelperFunctions.showSnackBar('A file with that name already exists in the selected folder.');
      return;
    }

    if (!mounted || !context.mounted) return;
    await _runArchiveJob(
      context,
      progressMessage: 'Compressing…',
      successMessage: 'Saved ${p.basename(outPath)}',
      work: () async {
        switch (format) {
          case _CompressFormat.zip:
            await InternalArchiveService.compressFolderToZip(folderPath, outPath);
          case _CompressFormat.tarGz:
            await InternalArchiveService.compressFolderToTarGz(folderPath, outPath);
          case _CompressFormat.tar:
            await InternalArchiveService.compressFolderToTar(folderPath, outPath);
        }
      },
    );
  }

  void _onFolderLongPress(BuildContext context, String folderPath) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TColors.primary.withOpacity(0.7),
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_zip_outlined),
              title: const Text('Compress to ZIP'),
              onTap: () {
                Navigator.pop(ctx);
                _startFolderCompress(context, folderPath, _CompressFormat.zip);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Compress to TAR.GZ'),
              onTap: () {
                Navigator.pop(ctx);
                _startFolderCompress(context, folderPath, _CompressFormat.tarGz);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Compress to TAR'),
              subtitle: const Text('Uncompressed archive'),
              onTap: () {
                Navigator.pop(ctx);
                _startFolderCompress(context, folderPath, _CompressFormat.tar);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startExtractArchive(BuildContext context, String archivePath) async {
    final destDir = await FilePicker.platform.getDirectoryPath();
    if (!mounted || !context.mounted || destDir == null || destDir.trim().isEmpty) return;

    await _runArchiveJob(
      context,
      progressMessage: 'Extracting…',
      successMessage: 'Extracted to folder',
      work: () => InternalArchiveService.extractArchiveTo(archivePath, destDir),
    );
  }

  void _onArchiveLongPress(BuildContext context, BrowserItem file) {
    showModalBottomSheet<void>(
      backgroundColor: TColors.primary.withOpacity(0.7),
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.unarchive_outlined),
              title: const Text('Uncompress'),
              subtitle: const Text('Choose folder to extract into'),
              onTap: () {
                Navigator.pop(ctx);
                _startExtractArchive(context, file.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final textColor = dark ? TColors.textWhite : TColors.textPrimary;
    final subTextColor = dark ? TColors.darkGrey : TColors.textSecondary;
    final accent = TColors.primary;
    final cardColor = dark ? TColors.darkContainer : TColors.lightContainer;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _displayTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: _buildBody(
        context,
        dark,
        textColor,
        subTextColor,
        accent,
        cardColor,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool dark,
    Color textColor,
    Color subTextColor,
    Color accent,
    Color cardColor,
  ) {
    if (!Platform.isAndroid) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.lg),
          child: Text(
            'Internal storage browsing is available on Android.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: subTextColor,
                ),
          ),
        ),
      );
    }

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    if (_error != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(TSizes.md),
          margin: const EdgeInsets.all(TSizes.defaultSpace),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(TSizes.cardRdiusLg),
            border: Border.all(
              color: dark ? TColors.darkGrey : TColors.grey,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: TColors.error),
              const SizedBox(height: TSizes.sm),
              Text(
                'Could not read folder',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: TSizes.sm),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: subTextColor,
                    ),
              ),
              const SizedBox(height: TSizes.md),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final root = _listing!;
    final topFolders = root.folderPaths;
    final topFiles = root.files;

    if (topFolders.isEmpty && topFiles.isEmpty) {
      return RefreshIndicator(
        color: accent,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              margin: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: cardColor,
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
                    'No folders found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: TSizes.md),
                  ElevatedButton(onPressed: _load, child: const Text('Refresh')),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final folderCount = topFolders.length;
    final hasFiles = topFiles.isNotEmpty;
    final headerCount = hasFiles ? 1 : 0;
    final itemCount = folderCount + headerCount + topFiles.length;

    return RefreshIndicator(
      color: accent,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(TSizes.md),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: TSizes.sm),
        itemBuilder: (context, index) {
          if (index < folderCount) {
            return _InternalStorageFolderTile(
              folderPath: topFolders[index],
              onOpen: () => _openFolder(context, topFolders[index]),
              onLongPress: () => _onFolderLongPress(context, topFolders[index]),
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              accent: accent,
              dark: dark,
            );
          }
          if (hasFiles) {
            if (index == folderCount) {
              return Padding(
                padding: const EdgeInsets.only(top: TSizes.sm, bottom: TSizes.xs),
                child: Text(
                  'Files',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                ),
              );
            }
            final fi = index - folderCount - 1;
            return _InternalStorageFileTile(
              file: topFiles[fi],
              siblings: topFiles,
              onLongPress: InternalArchiveService.looksLikeArchive(topFiles[fi].name)
                  ? () => _onArchiveLongPress(context, topFiles[fi])
                  : null,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              accent: accent,
              dark: dark,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Same layout as [FoldersPage] album row: card + folder icon + title/subtitle + chevron.
class _InternalStorageFolderTile extends StatelessWidget {
  const _InternalStorageFolderTile({
    required this.folderPath,
    required this.onOpen,
    required this.onLongPress,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.accent,
    required this.dark,
  });

  final String folderPath;
  final VoidCallback onOpen;
  final VoidCallback onLongPress;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color accent;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final name = _treeBasename(folderPath);

    return InkWell(
      borderRadius: BorderRadius.circular(TSizes.cardRdiusMd),
      onTap: onOpen,
      onLongPress: onLongPress,
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
                color: dark
                    ? TColors.darkPrimaryContainer
                    : TColors.lightPrimaryContainer,
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              ),
              child: Icon(Icons.folder, color: accent),
            ),
            const SizedBox(width: TSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Folder',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
          ],
        ),
      ),
    );
  }
}

/// File row using the same card + leading box pattern as folder tiles.
class _InternalStorageFileTile extends StatelessWidget {
  const _InternalStorageFileTile({
    required this.file,
    required this.siblings,
    this.onLongPress,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.accent,
    required this.dark,
  });

  final BrowserItem file;
  final List<BrowserItem> siblings;
  final VoidCallback? onLongPress;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color accent;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final browser = Get.find<FileBrowserController>();

    return InkWell(
      borderRadius: BorderRadius.circular(TSizes.cardRdiusMd),
      onTap: () => browser.openItem(file, siblingFiles: siblings),
      onLongPress: onLongPress,
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
                color: dark
                    ? TColors.darkPrimaryContainer
                    : TColors.lightPrimaryContainer,
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              ),
              child: Icon(_iconForFile(file), color: accent, size: 24),
            ),
            const SizedBox(width: TSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatSize(file.sizeBytes),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
          ],
        ),
      ),
    );
  }
}

String _treeBasename(String p) {
  var s = p.replaceAll('\\', '/');
  while (s.length > 1 && s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  final i = s.lastIndexOf('/');
  return i < 0 || i == s.length - 1 ? s : s.substring(i + 1);
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

IconData _iconForFile(BrowserItem it) {
  if (it.isVideo) return Icons.video_file_rounded;
  if (it.isAudio) return Icons.audio_file_rounded;
  if (it.isImage) return Icons.image_rounded;
  final n = it.name.toLowerCase();
  if (n.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
  if (InternalArchiveService.looksLikeArchive(it.name)) {
    return Icons.folder_zip_outlined;
  }
  return Icons.insert_drive_file_rounded;
}
