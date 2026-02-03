// lib/features/file_browser/components/sort_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/file_browser_controller.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

void showSortSheet(BuildContext context) {
  final c = Get.find<FileBrowserController>();
  final bool dark = THelperFunctions.isDarkMode(context);

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
    ),
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TSizes.defaultSpace,
            vertical: TSizes.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Text(
                "Sort by",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dark ? TColors.textWhite : TColors.textPrimary,
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              _tile(context, c, "Date (Newest first)", SortOption.dateNewToOld),
              _tile(context, c, "Date (Oldest first)", SortOption.dateOldToNew),
              _tile(context, c, "Name (A–Z)", SortOption.nameAZ),
              _tile(context, c, "Name (Z–A)", SortOption.nameZA),
              _tile(context, c, "Size (Smallest)", SortOption.sizeSmallToLarge),
              _tile(context, c, "Size (Largest)", SortOption.sizeLargeToSmall),

              const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        ),
      );
    },
  );
}

Widget _tile(
    BuildContext context,
    FileBrowserController c,
    String title,
    SortOption opt,
    ) {
  final bool dark = THelperFunctions.isDarkMode(context);
  final bool selected = c.sortOption.value == opt;

  return InkWell(
    borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
    onTap: () {
      c.setSort(opt);
      Navigator.pop(context);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(
        vertical: TSizes.sm,
        horizontal: TSizes.sm,
      ),
      margin: const EdgeInsets.only(bottom: TSizes.xs),
      decoration: BoxDecoration(
        color: selected
            ? (dark
            ? TColors.darkPrimaryContainer
            : TColors.lightPrimaryContainer)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            size: TSizes.iconSm,
            color: selected ? TColors.primary : TColors.textSecondary,
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: dark ? TColors.textWhite : TColors.textPrimary,
                fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
