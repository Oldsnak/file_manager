import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/controllers/ram_controller.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

class RamCleanerPage extends StatelessWidget {
  const RamCleanerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final c = Get.find<RamController>();

    final bgGradient = dark
        ? const RadialGradient(
      colors: [TColors.darkGradientBackgroundStart, TColors.darkGradientBackgroundEnd],
      radius: 1.0,
    )
        : const RadialGradient(
      colors: [TColors.lightGradientBackgroundStart, TColors.lightGradientBackgroundEnd],
      radius: 1.0,
    );

    return Container(
      decoration: BoxDecoration(gradient: bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "RAM Cleaner",
            style: TextStyle(color: dark ? TColors.textWhite : TColors.textPrimary),
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: dark ? TColors.textWhite : TColors.textPrimary),
          actions: [
            IconButton(
              onPressed: c.refreshRam,
              icon: Icon(Icons.refresh, color: dark ? TColors.textWhite : TColors.textPrimary),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Obx(() {
            final total = c.totalBytes.value;
            final used = c.usedBytes.value;
            final percent = c.usedPercent.value.clamp(0.0, 1.0);

            final cardBg = dark ? TColors.darkContainer : TColors.lightContainer;
            final border = dark ? TColors.darkerGrey : TColors.grey;
            final titleColor = dark ? TColors.textWhite : TColors.textPrimary;
            final subColor = dark ? TColors.darkGrey : TColors.textSecondary;

            return Column(
              children: [
                // ---- Meter Card ----
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(TSizes.lg),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(TSizes.cardRdiusLg),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: TColors.primary.withOpacity(dark ? 0.18 : 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Memory Usage",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),

                      // Circle Percent + animation
                      Obx(() {
                        final cleaning = c.isCleaning.value;
                        final animPercent = cleaning ? c.cleanProgress.value : percent;

                        return CircularPercentIndicator(
                          radius: 90,
                          lineWidth: 14,
                          animation: true,
                          animationDuration: 450,
                          percent: animPercent.clamp(0.0, 1.0),
                          circularStrokeCap: CircularStrokeCap.round,
                          backgroundColor: dark ? TColors.darkOptionalContainer : TColors.lightOptionalContainer,
                          progressColor: TColors.primary,
                          center: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: cleaning
                                ? Column(
                              key: const ValueKey("cleaning"),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: TColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Cleaning...",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: subColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              ],
                            )
                                : Column(
                              key: const ValueKey("idle"),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${(percent * 100).toInt()}%",
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: titleColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  "Used",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: subColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: TSizes.spaceBtwItems),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _metric(
                            context,
                            title: "Used",
                            value: c.formatBytes(used),
                            dark: dark,
                          ),
                          _metric(
                            context,
                            title: "Total",
                            value: c.formatBytes(total),
                            dark: dark,
                          ),
                        ],
                      ),

                      const SizedBox(height: TSizes.spaceBtwItems),

                      // Freed info (UX)
                      Obx(() {
                        final freed = c.freedBytesFake.value;
                        if (freed <= 0) return const SizedBox.shrink();

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(TSizes.md),
                          decoration: BoxDecoration(
                            color: dark ? TColors.darkPrimaryContainer : TColors.lightPrimaryContainer,
                            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                            border: Border.all(color: TColors.primary.withOpacity(0.35)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: TColors.primary),
                              const SizedBox(width: TSizes.sm),
                              Expanded(
                                child: Text(
                                  "Freed approx ${c.formatBytes(freed)}",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: titleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: TSizes.spaceBtwSections),

                // ---- Action Buttons ----
                Obx(() {
                  final cleaning = c.isCleaning.value;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: cleaning ? null : c.cleanRam,
                      icon: AnimatedRotation(
                        turns: cleaning ? 1 : 0,
                        duration: const Duration(milliseconds: 800),
                        child: const Icon(Icons.cleaning_services),
                      ),
                      label: Text(cleaning ? "Cleaning..." : "Clean RAM"),
                    ),
                  );
                }),

                const SizedBox(height: TSizes.sm),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: c.refreshRam,
                    child: const Text("Refresh"),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, {required String title, required String value, required bool dark}) {
    final titleColor = dark ? TColors.darkGrey : TColors.textSecondary;
    final valueColor = dark ? TColors.textWhite : TColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
