import 'package:file_manager/features/downloader/components/social_apps.dart';
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

class DownloaderHomePage extends StatelessWidget {
  const DownloaderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool dark = THelperFunctions.isDarkMode(context);

    // ✅ Local provider so you don't need global app wiring right now.
    return ChangeNotifierProvider(
      create: (_) => DownloaderController(
        downloaderService: DownloaderService(
          baseUrl: _inferBaseUrlForDevice(),
          // apiKey: "YOUR_KEY_IF_ANY",
        ),
        socialDetector: const SocialDetectorService(),
      ),
      child: Builder(
        builder: (context) {
          final c = context.watch<DownloaderController>();

          // Show errors as snackbar (no UI layout changes)
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
                                textColor: dark ? Colors.black : Colors.white,
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
                          child: Text(
                            "Download your videos here!",
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .apply(color: TColors.primary),
                          ),
                        ),
                        SizedBox(height: TSizes.spaceBtwSections),

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
                                        color: TColors.darkPrimary,
                                      ),
                                      border: UnderlineInputBorder(
                                        borderSide:
                                        BorderSide(color: TColors.darkGrey, width: 2),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                        BorderSide(color: TColors.darkGrey, width: 2),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                        BorderSide(color: TColors.darkPrimary, width: 2),
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
                                        : () => c.fetchVideoInfo(),
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

                        // Downloader card (same UI, data dynamic)
                        _DownloaderCard(
                          title: c.videoInfo?.title ??
                              "Paste a link and press the arrow button",
                          thumbnailUrl: c.videoInfo?.thumbnail,
                          fallbackAsset: thumbnail,
                          selectedQuality: c.selectedQuality,
                          onPickQuality: c.videoInfo?.formats.isNotEmpty == true
                              ? () => _showQualityPicker(context, c)
                              : null,
                          isLoading: c.isChecking || c.isFetchingInfo,
                        ),

                        SizedBox(height: TSizes.spaceBtwItems),

                        // Download button (same UI)
                        GestureDetector(
                          onTap: c.isStarting || !c.canStartDownload ? null : () => c.startDownload(),
                          child: Opacity(
                            opacity: (c.isStarting || !c.canStartDownload) ? 0.6 : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: TColors.primary,
                                borderRadius: BorderRadius.circular(TSizes.lg),
                              ),
                              child: IconButton(
                                onPressed: c.isStarting || !c.canStartDownload
                                    ? null
                                    : () => c.startDownload(),
                                icon: c.isStarting
                                    ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : Icon(
                                  Icons.arrow_downward,
                                  color: TColors.dark,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Optional: show progress via snackbar without UI layout changes
                        if (c.isDownloading && c.progress != null)
                          Padding(
                            padding: const EdgeInsets.only(top: TSizes.sm),
                            child: Text(
                              "${c.progress!.speedHuman ?? ''}  -  ${c.progress!.downloadedHuman}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: TColors.primary, fontWeight: FontWeight.bold),
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

  // 🔧 You can later move this to constants.
  // For emulator: 10.0.2.2
  // For real phone: your PC IP on WiFi (e.g. 192.168.1.10)
  static String _inferBaseUrlForDevice() {
    // Safe default for Android emulator:
    return "http://10.0.2.2:8000";
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
}

class _DownloaderCard extends StatelessWidget {
  final String title;
  final String? thumbnailUrl;
  final String fallbackAsset;
  final VideoQualityModel? selectedQuality;
  final VoidCallback? onPickQuality;
  final bool isLoading;

  const _DownloaderCard({
    required this.title,
    required this.thumbnailUrl,
    required this.fallbackAsset,
    required this.selectedQuality,
    required this.onPickQuality,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final sizeText = selectedQuality?.filesizeHuman ?? "--";
    final qualityText = (selectedQuality?.quality ?? "--").toUpperCase();

    return Container(
      padding: EdgeInsets.all(TSizes.md),
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: TColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(TSizes.lg),
        border: Border.all(color: TColors.primary),
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
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: TColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                : Text(
                              sizeText,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                ],
              ),
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
