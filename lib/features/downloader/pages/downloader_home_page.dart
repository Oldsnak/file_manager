import 'package:file_manager/features/downloader/components/social_apps.dart';
import 'package:file_manager/foundation/constants/api_config.dart';
import 'package:file_manager/foundation/constants/assets.dart';
import 'package:file_manager/foundation/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../common/widgets/texts/section_heading.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';

import '../../../core/controllers/downloader_controller.dart';
import '../../../core/services/downloader_service.dart';
import '../../../core/services/social_detector_service.dart';
import '../../../core/models/video_quality_model.dart';

class DownloaderHomePage extends StatefulWidget {
  const DownloaderHomePage({super.key});

  @override
  State<DownloaderHomePage> createState() => _DownloaderHomePageState();
}

class _DownloaderHomePageState extends State<DownloaderHomePage> {
  int _providerKey = 0;

  void _showBackendUrlDialog() {
    final controller = TextEditingController(text: ApiConfig.effectiveBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend URL (real device)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.10:8000',
            labelText: 'Video downloader API URL',
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                ApiConfig.setVideoDownloaderBaseUrl(url);
                setState(() => _providerKey++);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = THelperFunctions.isDarkMode(context);

    return ChangeNotifierProvider(
      key: ValueKey(_providerKey),
      create: (_) => DownloaderController(
        downloaderService: DownloaderService(
          baseUrl: ApiConfig.effectiveBaseUrl,
          apiKey: ApiConfig.effectiveApiKey,
        ),
        socialDetector: const SocialDetectorService(),
      ),
      child: Builder(
        builder: (context) {
          final c = context.watch<DownloaderController>();

          // Show errors and save result as snackbar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final err = c.error;
            if (err != null && err.trim().isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(err),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
            final saveErr = c.lastSaveError;
            if (saveErr != null && saveErr.trim().isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(saveErr),
                  backgroundColor: Colors.orange.shade700,
                ),
              );
              c.clearLastSaveResult();
            }
            final savedPath = c.lastSavedFilePath;
            if (savedPath != null && savedPath.trim().isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Saved to $savedPath'),
                  backgroundColor: Colors.green.shade700,
                ),
              );
              c.clearLastSaveResult();
            }
          });

          return Scaffold(
            body: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  TPrimaryHeaderContainer(
                    child: Column(
                      children: [
                        const SizedBox(height: TSizes.appBarHeight),
                        Padding(
                          padding: const EdgeInsets.only(left: TSizes.defaultSpace),
                          child: Column(
                            children: [
                              SectionHeading(
                                title: 'Quick Actions',
                                showActionButton: false,
                                textColor: Colors.black,
                              ),
                              const SizedBox(height: TSizes.spaceBtwItems / 2),
                              const SocialApps(),
                            ],
                          ),
                        ),
                        const SizedBox(height: TSizes.spaceBtwSections),
                      ],
                    ),
                  ),

                  // Body
                  Padding(
                    padding: const EdgeInsets.all(TSizes.defaultSpace),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  "Download your videos here!",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium!
                                      .apply(color: TColors.primary),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  context.findAncestorStateOfType<_DownloaderHomePageState>()
                                      ?._showBackendUrlDialog();
                                },
                                icon: Icon(Icons.link, color: TColors.primary),
                                tooltip: 'Set backend URL (for real device)',
                              ),
                            ],
                          ),
                        ),
                        if (ApiConfig.effectiveBaseUrl.contains('10.0.2.2'))
                          Padding(
                            padding: const EdgeInsets.only(top: TSizes.sm),
                            child: Material(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(TSizes.sm),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TSizes.md,
                                  vertical: TSizes.sm,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 20, color: Colors.amber.shade900),
                                    const SizedBox(width: TSizes.sm),
                                    Expanded(
                                      child: Text(
                                        'On a real device, tap the link icon above and set your PC\'s IP (e.g. http://192.168.1.10:8000).',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: TSizes.spaceBtwSections),

                        // Playlist toggle
                        Row(
                          children: [
                            Checkbox(
                              value: c.isPlaylistMode,
                              onChanged: (value) => c.setPlaylistMode(value ?? false),
                            ),
                            const SizedBox(width: TSizes.sm),
                            const Text('Playlist'),
                          ],
                        ),

                        // Search Bar
                        Container(
                          width: double.infinity,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(TSizes.lg),
                            border: Border.all(color: TColors.primary, width: 3),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: TextField(
                                    controller: c.urlController,
                                    decoration: InputDecoration(
                                      hintText: 'Paste Links here',
                                      hintStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: TColors.primary,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                        BorderSide(color: TColors.primary, width: 2),
                                      ),
                                      contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: TColors.darkPrimary,
                                    ),
                                    cursorColor: TColors.darkPrimary,
                                    cursorWidth: 2,
                                  ),
                                ),
                              ),

                              // Arrow button
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: double.infinity,
                                  width: double.infinity,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(TSizes.lg - 3),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        TColors.primary.withOpacity(0.95),
                                        TColors.primary.withOpacity(0.75),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.35),
                                        offset: const Offset(4, 4),
                                        blurRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.25),
                                        offset: const Offset(-2, -2),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: c.isChecking || c.isFetchingInfo
                                        ? null
                                        : () => c.isPlaylistMode
                                        ? c.fetchPlaylistInfo()
                                        : c.fetchVideoInfo(),
                                    icon: c.isChecking || c.isFetchingInfo
                                        ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                        : Icon(
                                      Icons.arrow_downward,
                                      color: TColors.dark,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: TSizes.spaceBtwSections),

                        // Single-video downloader card: only after backend returns info
                        if (!c.isPlaylistMode && c.videoInfo != null)
                          _DownloaderCard(
                            title: c.videoInfo!.title ?? "Untitled video",
                            thumbnailUrl: c.videoInfo!.thumbnail,
                            fallbackAsset: thumbnail,
                            selectedQuality: c.selectedQuality,
                            onPickQuality: c.videoInfo!.formats.isNotEmpty
                                ? () => _showQualityPicker(context, c)
                                : null,
                            isLoading: c.isChecking || c.isFetchingInfo,
                            isDownloading: c.isDownloading,
                            progressValue: c.progressValue,
                            canStartDownload: c.canStartDownload && !c.isStarting && !c.isDownloading,
                            onDownload: c.canStartDownload && !c.isStarting && !c.isDownloading
                                ? () => c.startDownload()
                                : null,
                          ),

                        // Playlist UI
                        if (c.isPlaylistMode && c.hasPlaylist) ...[
                          Row(
                            children: [
                              Checkbox(
                                value: c.areAllSelected,
                                onChanged: (value) => c.toggleSelectAll(value ?? false),
                              ),
                              const Text('Select All'),
                            ],
                          ),
                          if (c.isDownloading && c.selectedPlaylistCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: TSizes.sm),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Video ${c.completedPlaylistCount + 1} of ${c.selectedPlaylistCount}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                      color: TColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () => c.cancelDownload(),
                                    icon: const Icon(Icons.stop, size: 20),
                                    label: const Text('Stop'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: TSizes.sm),
                          Column(
                            children: c.playlistItems
                                .map(
                                  (item) => _PlaylistItemCard(
                                item: item,
                                onToggleSelected: (val) =>
                                    c.toggleItemSelected(item.id, val),
                                onPickQuality: () =>
                                    _showPlaylistQualityPicker(context, c, item),
                                isCurrentlyDownloading:
                                c.currentDownloadingSourceUrl == item.id,
                                isCompleted: c.isPlaylistItemCompleted(item.id),
                                progressValue: c.currentDownloadingSourceUrl == item.id
                                    ? c.progressValue
                                    : null,
                              ),
                            )
                                .toList(),
                          ),
                          const SizedBox(height: TSizes.sm),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: c.hasAnySelected && !c.isDownloading
                                  ? () => c.startPlaylistDownload()
                                  : null,
                              icon: const Icon(Icons.download),
                              label: const Text('Download selected'),
                            ),
                          ),
                        ],

                        if (c.isSavingToDevice)
                          Padding(
                            padding: const EdgeInsets.only(top: TSizes.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: TColors.primary),
                                ),
                                const SizedBox(width: TSizes.sm),
                                Text(
                                  'Saving to device...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: TColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TSizes.lg * 3),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static void _showQualityPicker(BuildContext context, DownloaderController c) {
    final formats = c.videoInfo?.formats ?? const <VideoQualityModel>[];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) {
        return SafeArea(
          child: ListView.separated(
            itemCount: formats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final f = formats[i];
              final selected = c.selectedQuality?.formatId == f.formatId;

              return ListTile(
                title: Text(
                  f.quality.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(f.filesizeHuman ?? ""),
                trailing: selected ? const Icon(Icons.check_circle) : null,
                onTap: () {
                  c.selectQuality(f);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  static void _showPlaylistQualityPicker(
      BuildContext context,
      DownloaderController c,
      PlaylistItemVM item,
      ) {
    final formats = item.qualities;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) {
        return SafeArea(
          child: ListView.separated(
            itemCount: formats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final f = formats[i];
              final selected = item.selectedQuality?.formatId == f.formatId;

              return ListTile(
                title: Text(
                  f.quality.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(f.filesizeHuman ?? ""),
                trailing: selected ? const Icon(Icons.check_circle) : null,
                onTap: () {
                  c.selectQualityForItem(item.id, f);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _PlaylistItemCard extends StatelessWidget {
  final PlaylistItemVM item;
  final ValueChanged<bool> onToggleSelected;
  final VoidCallback onPickQuality;
  final bool isCurrentlyDownloading;
  final bool isCompleted;
  final double? progressValue;

  const _PlaylistItemCard({
    required this.item,
    required this.onToggleSelected,
    required this.onPickQuality,
    this.isCurrentlyDownloading = false,
    this.isCompleted = false,
    this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    final qualityText = (item.selectedQuality?.quality ?? '--').toUpperCase();
    final sizeText = item.selectedQuality?.filesizeHuman ?? '--';

    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TSizes.md),
        border: Border.all(color: TColors.primary.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: item.selected,
            onChanged: (value) => onToggleSelected(value ?? false),
          ),
          SizedBox(
            width: 80,
            height: 56,
            child: _Thumb(
              thumbnailUrl: item.thumbnail,
              fallbackAsset: thumbnail,
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (isCompleted)
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                else if (isCurrentlyDownloading && progressValue != null) ...[
                  LinearProgressIndicator(value: progressValue),
                  const SizedBox(height: 2),
                  Text(
                    '${(progressValue! * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: TColors.primary, fontWeight: FontWeight.bold),
                  ),
                ] else ...[
                  Text(
                    'Quality: $qualityText',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Size: $sizeText',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: onPickQuality,
                      child: const Text('Change quality'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloaderCard extends StatelessWidget {
  final String title;
  final String? thumbnailUrl;
  final String fallbackAsset;
  final VideoQualityModel? selectedQuality;
  final VoidCallback? onPickQuality;
  final bool isLoading;
  final bool isDownloading;
  final double? progressValue;
  final bool canStartDownload;
  final VoidCallback? onDownload;

  const _DownloaderCard({
    required this.title,
    required this.thumbnailUrl,
    required this.fallbackAsset,
    required this.selectedQuality,
    required this.onPickQuality,
    required this.isLoading,
    required this.isDownloading,
    required this.progressValue,
    required this.canStartDownload,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final sizeText = selectedQuality?.filesizeHuman ?? "--";
    final qualityText = (selectedQuality?.quality ?? "--").toUpperCase();

    return Container(
      padding: EdgeInsets.all(TSizes.md),
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: TColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(TSizes.lg),
        border: Border.all(color: TColors.primary),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            // padding: EdgeInsets.all(TSizes.md),
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(TSizes.lg),
              // border: Border.all(color: TColors.primary),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: double.infinity,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: TColors.dark.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TColors.dark),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _Thumb(
                      thumbnailUrl: thumbnailUrl,
                      fallbackAsset: fallbackAsset,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: EdgeInsets.only(left: TSizes.lg),
                    child: Column(
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .apply(color: TColors.primary),
                        ),
                        SizedBox(height: TSizes.spaceBtwItems),
                        if (!isDownloading) ...[
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: TColors.dark.withOpacity(0.5),
                              border: Border.all(color: TColors.primary),
                              borderRadius: BorderRadius.circular(TSizes.md),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Padding(
                                    padding: const EdgeInsets.all(TSizes.sm),
                                    child: isLoading
                                        ? Text(
                                      "Loading...",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                        color: TColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                        : Text(
                                      sizeText,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                        color: TColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: GestureDetector(
                                    onTap: onPickQuality,
                                    child: Container(
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: TColors.primary,
                                        borderRadius: BorderRadius.circular(TSizes.md),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            qualityText,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          LinearProgressIndicator(
                            value: progressValue,
                          ),
                          const SizedBox(height: TSizes.sm),
                          if (progressValue != null)
                            Text(
                              '${(progressValue! * 100).toStringAsFixed(0)}% downloaded',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: TColors.primary, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TSizes.sm),
          if (onDownload != null || isDownloading)
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canStartDownload && !isDownloading ? onDownload : null,
                icon: isDownloading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.download),
                label: const Text('Download'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? thumbnailUrl;
  final String fallbackAsset;

  const _Thumb({required this.thumbnailUrl, required this.fallbackAsset});

  @override
  Widget build(BuildContext context) {
    final url = thumbnailUrl?.trim();

    // If backend provides a thumbnail URL, show it (network).
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(fallbackAsset, fit: BoxFit.contain),
        ),
      );
    }

    // fallback local asset
    return Image.asset(fallbackAsset, fit: BoxFit.contain);
  }
}
