// lib/features/secure_vault/widgets/vault_view_toggle.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/vault_controller.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

class VaultViewToggle extends StatelessWidget {
  const VaultViewToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<VaultController>();
    final bool dark = THelperFunctions.isDarkMode(context);

    final Color iconColor = dark ? TColors.textWhite : TColors.textPrimary;
    final Color activeBg =
    dark ? TColors.darkPrimaryContainer : TColors.lightPrimaryContainer;
    final Color borderColor = dark ? TColors.darkGrey : TColors.grey;

    return Obx(() {
      final isList = c.viewMode.value == VaultViewMode.list;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: TSizes.xs),
        decoration: BoxDecoration(
          color: activeBg,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          border: Border.all(color: borderColor),
        ),
        child: IconButton(
          splashRadius: 22,
          tooltip: isList ? "Grid view" : "List view",
          icon: Icon(
            isList ? Icons.grid_view_rounded : Icons.view_list_rounded,
            color: iconColor,
            size: TSizes.iconMd,
          ),
          onPressed: c.toggleViewMode,
        ),
      );
    });
  }
}
