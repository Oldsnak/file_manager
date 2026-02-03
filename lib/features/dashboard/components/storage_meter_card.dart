// lib/features/dashboard/components/storage_meter_card.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/controllers/dashboard_controller.dart';
import '../../../core/models/storage_info.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/formatters.dart';
import '../../../foundation/helpers/helper_functions.dart';
import '../../file_browser/pages/browser_page.dart';
import '../components/health_score_meter.dart';

class StorageMeterCard extends StatelessWidget {
  const StorageMeterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final dash = Get.find<DashboardController>();

    return Obx(() {
      final StorageInfo? info = dash.storageInfo.value;

      // fallback
      final int total = info?.totalBytes ?? 0;
      final int used = info?.usedBytes ?? 0;
      final int free = info?.freeBytes ?? 0;

      final double percent = (total <= 0) ? 0.0 : (used / total);
      final int percent100 = (percent * 100).round();

      return Container(
        width: 320,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TSizes.productImageRadius),
          border: Border.all(width: 1, color: dark ? TColors.darkGrey : TColors.buttonDisabled),
          color: dark ? const Color(0xFF3C3C3C) : TColors.grey,
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "Internal Storage",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: TColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Meter
            Stack(
              children: [
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: dark ? TColors.dark : TColors.buttonDisabled,
                    borderRadius: BorderRadius.circular(TSizes.cardRdiusLg),
                  ),
                ),
                Positioned(
                  top: -40,
                  left: 15,
                  child: SizedBox(
                    width: 280,
                    child: HealthScoreMeter(score: percent100.toDouble()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwItems / 2),

            // Free/Total + Percent bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${TFormatters.bytesToGB(used)} / ${TFormatters.bytesToGB(total)}",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: TColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  LinearPercentIndicator(
                    width: 120,
                    lineHeight: 16,
                    percent: percent.clamp(0.0, 1.0),
                    center: Text(
                      "$percent100%",
                      style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                    ),
                    barRadius: const Radius.circular(10),
                    backgroundColor: TColors.textSecondary,
                    progressColor: TColors.primary,
                    animation: true,
                    animationDuration: 900,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Quick Links (Video/Images/Audios/Documents etc.)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
              child: Column(
                children: [
                  _fileTile(
                    name: 'Videos',
                    onTap: () => Get.to(() => const BrowserPage(title: "Videos", type: RequestType.video)),
                  ),
                  _fileTile(
                    name: 'Images',
                    onTap: () => Get.to(() => const BrowserPage(title: "Images", type: RequestType.image)),
                  ),
                  _fileTile(
                    name: 'Audio Files',
                    onTap: () => Get.to(() => const BrowserPage(title: "Audios", type: RequestType.audio)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Refresh storage button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: dash.refreshStorage,
                      icon: dash.isLoading.value
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.refresh, size: 18),
                      label: const Text("Refresh Storage"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
          ],
        ),
      );
    });
  }

  Widget _fileTile({required String name, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          const Divider(color: TColors.darkGrey),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: const [
                  Icon(Icons.arrow_forward_ios_outlined, size: 14, color: TColors.darkPrimary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
