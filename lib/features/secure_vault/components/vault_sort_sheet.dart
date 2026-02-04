// lib/features/secure_vault/widgets/vault_sort_sheet.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

import '../../../core/controllers/vault_controller.dart';

void showVaultSortSheet(BuildContext context) {
  final c = Get.find<VaultController>();
  final bool dark = THelperFunctions.isDarkMode(context);

  final Color bg = dark ? TColors.darkContainer : TColors.lightContainer;
  final Color textColor = dark ? TColors.textWhite : TColors.textPrimary;
  final Color subText = dark ? TColors.darkGrey : TColors.textSecondary;
  final Color divider = dark ? TColors.darkGrey : TColors.grey;

  // current value
  final current = c.sortOption.value;

  showModalBottomSheet(
    context: context,
    backgroundColor: bg,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TSizes.cardRdiusLg),
      ),
    ),
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: TSizes.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.defaultSpace,
                  vertical: TSizes.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.sort_rounded, color: dark ? TColors.textWhite : TColors.textPrimary),
                    const SizedBox(width: TSizes.sm),
                    Expanded(
                      child: Text(
                        "Sort",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      "Vault",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: subText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: divider),

              _SortOptionTile(
                title: "Date: New → Old",
                icon: Icons.schedule_rounded,
                selected: current == VaultSortOption.dateNewToOld,
                dark: dark,
                onTap: () {
                  Navigator.pop(context);
                  c.setSort(VaultSortOption.dateNewToOld);
                },
              ),
              _SortOptionTile(
                title: "Date: Old → New",
                icon: Icons.schedule_outlined,
                selected: current == VaultSortOption.dateOldToNew,
                dark: dark,
                onTap: () {
                  Navigator.pop(context);
                  c.setSort(VaultSortOption.dateOldToNew);
                },
              ),
              _SortOptionTile(
                title: "Name: A → Z",
                icon: Icons.sort_by_alpha_rounded,
                selected: current == VaultSortOption.nameAZ,
                dark: dark,
                onTap: () {
                  Navigator.pop(context);
                  c.setSort(VaultSortOption.nameAZ);
                },
              ),
              _SortOptionTile(
                title: "Name: Z → A",
                icon: Icons.sort_by_alpha_outlined,
                selected: current == VaultSortOption.nameZA,
                dark: dark,
                onTap: () {
                  Navigator.pop(context);
                  c.setSort(VaultSortOption.nameZA);
                },
              ),
              _SortOptionTile(
                title: "Size: Small → Large",
                icon: Icons.swap_vert_rounded,
                selected: current == VaultSortOption.sizeSmallToLarge,
                dark: dark,
                onTap: () {
                  Navigator.pop(context);
                  c.setSort(VaultSortOption.sizeSmallToLarge);
                },
              ),
              _SortOptionTile(
                title: "Size: Large → Small",
                icon: Icons.swap_vert_rounded,
                selected: current == VaultSortOption.sizeLargeToSmall,
                dark: dark,
                onTap: () {
                  Navigator.pop(context);
                  c.setSort(VaultSortOption.sizeLargeToSmall);
                },
              ),

              const SizedBox(height: TSizes.xs),
            ],
          ),
        ),
      );
    },
  );
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = dark ? TColors.textWhite : TColors.textPrimary;
    final Color subText = dark ? TColors.darkGrey : TColors.textSecondary;

    final Color selectedBg = dark ? TColors.darkPrimaryContainer : TColors.lightPrimaryContainer;
    final Color normalBg = Colors.transparent;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: TSizes.defaultSpace,
          vertical: TSizes.md,
        ),
        decoration: BoxDecoration(
          color: selected ? selectedBg : normalBg,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? TColors.primary : subText),
            const SizedBox(width: TSizes.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: TColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
