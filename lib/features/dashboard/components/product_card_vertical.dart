import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../common/Styles/sadows.dart';
import '../../../common/widgets/pages/coming_soon_page.dart';
import '../../../core/controllers/dashboard_controller.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';
import '../../file_browser/pages/browser_page.dart';
import '../../file_browser/pages/file_scan_page.dart';
import 'health_score_meter.dart';

class MedicalCardVertical extends StatelessWidget {
  MedicalCardVertical({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final dash = Get.find<DashboardController>();

    return Obx(() {
      final storage = dash.storageInfo.value;

      final totalBytes = storage?.totalBytes ?? 0;
      final usedBytes = storage?.usedBytes ?? 0;
      final percent = storage?.usedPercent ?? 0.0;

      // GB numbers for display
      final usedGB = usedBytes / (1024 * 1024 * 1024);
      final totalGB = totalBytes / (1024 * 1024 * 1024);

      // meter score 0-100
      final score = (percent * 100).clamp(0.0, 100.0);

      // Category spaces (GB) (dynamic)
      final videos = dash.videoGB.value;
      final images = dash.imageGB.value;
      final audios = dash.audioGB.value;

      return Container(
        width: 280,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          boxShadow: [
            dark ? TShadowStyle.verticalProductShadow
                :
              BoxShadow(
                color: dark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
                blurRadius: 15, // Shadow ko soft karne ke liye
                spreadRadius: 1, // Shadow kitna phele ga
                offset: const Offset(0, 8), // Shadow ko neechay ki taraf push karne ke liye (x=0, y=8)
              ),
              // Optional: Inner light effect for 3D depth
              if (!dark)
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-2, -2),
                  blurRadius: 5,
                ),
          ],
          borderRadius: BorderRadius.circular(TSizes.productImageRadius),
          border: Border.all(width: 1, color: dark ? TColors.darkGrey : TColors.primary.withOpacity(0.7)),
          color: dark ? const Color(0xFF3C3C3C) : TColors.primary.withOpacity(0.2),
        ),
        child: Column(
          children: [
            Text(
              "Internal Storage",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: dark ? TColors.primary : TColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Thumbnail, wishlist Button, Discount Tag
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    // color: dark ? TColors.dark : TColors.buttonDisabled,
                    color: dark ? TColors.dark : TColors.darkPrimary.withOpacity(1),
                    borderRadius: BorderRadius.circular(TSizes.cardRdiusLg),
                  ),
                  padding: EdgeInsets.all(TSizes.sm),
                ),
                Positioned(
                  top: -40,
                  left: 15,
                  child: SizedBox(
                    width: 250,
                    child: HealthScoreMeter(score: score),
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwItems / 2),

            // -- Details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: TSizes.sm),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: TSizes.sm),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${usedGB.toStringAsFixed(1)} GB / ${totalGB.toStringAsFixed(1)} GB",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: dark ? TColors.primary : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        LinearPercentIndicator(
                          width: 100.0,
                          lineHeight: 15.0,
                          percent: percent.clamp(0.0, 1.0),
                          center: Text(
                            "${(percent * 100).toInt()}%",
                            style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          barRadius: const Radius.circular(10),
                          backgroundColor: dark ? TColors.textSecondary : TColors.darkGrey,
                          progressColor: dark ? TColors.primary : Colors.blue,
                          animation: true,
                          animationDuration: 900,
                        ),
                      ],
                    ),

                    SizedBox(height: TSizes.xs),

                    fileTile(
                      name: 'Videos',
                      space: videos,
                      onTap: () => Get.to(() => const BrowserPage(title: "Videos", type: RequestType.video)),
                    ),
                    fileTile(
                      name: 'Images',
                      space: images,
                      onTap: () => Get.to(() => const BrowserPage(title: "Images", type: RequestType.image)),
                    ),
                    fileTile(
                      name: 'Audio Files',
                      space: audios,
                      onTap: () => Get.to(() => const FileScanPage(title: "Audio Files", category: ScanCategory.audioFiles,)),
                    ),

                    fileTile(
                      name: 'Documents',
                      space: 0.8,
                      onTap: () => Get.to(() => const FileScanPage(title: "Documents", category: ScanCategory.documents,)),
                    ),

                    fileTile(
                      name: 'Downloads',
                      space: 0.0,
                      onTap: () => Get.to(() => const FileScanPage(title: "Downloads", category: ScanCategory.downloads,)),
                    ),

                    // fileTile(
                    //   name: 'Compresssed Files',
                    //   space: 0.0,
                    //   onTap: () => Get.to(() => const FileScanPage(title: "Compressed Files", category: ScanCategory.compressed,)),
                    // ),

                    fileTile(
                      name: 'Large files',
                      space: 0.0,
                      onTap: () => Get.to(() => const FileScanPage(
                        title: "Large Files (1GB+)",
                        category: ScanCategory.largeFiles,
                      )),
                    ),

                    fileTile(
                      name: 'Other files',
                      space: 0.0,
                      onTap: () => Get.to(() => const FileScanPage(
                        title: "Other Files",
                        category: ScanCategory.otherFiles,
                      )),
                    ),

                    fileTile(
                      name: 'Apps',
                      space: 5.4,
                      onTap: () => Get.to(() => const ComingSoonPage(title: "Apps", subtitle: "Apps listing needs additional Android package APIs.",)),
                    ),

                    fileTile(
                      name: 'System',
                      space: 12.5,
                      onTap: () => Get.to(() => const ComingSoonPage(
                        title: "System",
                        subtitle: "System files access is restricted. We'll add a safe viewer later.",
                      )),
                    ),

                    fileTile(
                      name: 'Duplicates',
                      space: 0.0,
                      onTap: () => Get.to(() => const ComingSoonPage(
                        title: "Duplicate Files",
                        subtitle: "Duplicate detection (hash based) will be added next.",
                      )),
                    ),

                    fileTile(
                      name: 'Recycle bin',
                      space: 0.0,
                      onTap: () => Get.to(() => const ComingSoonPage(
                        title: "Recycle Bin",
                        subtitle: "We’ll add a custom recycle bin system in next update.",
                      )),
                    ),

                    SizedBox(height: TSizes.sm),

                    // optional refresh button (UI same rakhna ho to remove kar do)
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: ElevatedButton(
                    //     onPressed: dash.refreshAll,
                    //     child: Obx(() => dash.isLoading.value
                    //         ? const SizedBox(
                    //       height: 18,
                    //       width: 18,
                    //       child: CircularProgressIndicator(strokeWidth: 2),
                    //     )
                    //         : const Text("Refresh")),
                    //   ),
                    // ),

                    SizedBox(height: TSizes.sm),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class fileTile extends StatelessWidget {
  const fileTile({
    super.key,
    required this.name,
    required this.space,
    required this.onTap,
  });

  final String name;
  final double space; // GB
  final Callback onTap;

  @override
  Widget build(BuildContext context) {
    final bool dark = THelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Divider(color: TColors.darkGrey),
          SizedBox(height: TSizes.xs / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text(
                    "${space.toStringAsFixed(1)} GB",
                    style: TextStyle(fontWeight: FontWeight.bold, color: dark ? TColors.darkPrimary : Colors.black),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_outlined, size: 14, color: dark ? TColors.darkPrimary : TColors.black),
                ],
              ),
            ],
          ),
          SizedBox(height: TSizes.xs / 2),
        ],
      ),
    );
  }
}
