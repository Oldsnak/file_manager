import 'package:flutter/material.dart';

import '../../../../foundation/constants/colors.dart';
import '../../../../foundation/constants/sizes.dart';
import '../../../../foundation/helpers/helper_functions.dart';

class GlossyContainer extends StatelessWidget {
  const GlossyContainer({super.key, required this.child});

  final Widget child;
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode=THelperFunctions.isDarkMode(context);
    final backgroundColor = isDarkMode
        ? TColors.darkPrimaryContainer
        : TColors.lightPrimaryContainer;

    final highlightColor = isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.6);

    final shadowColor = isDarkMode
        ? Colors.black.withOpacity(0.8)
        : Colors.grey.withOpacity(0.3);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: TSizes.sm, horizontal: TSizes.sm),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(TSizes.cardRdiusLg),
        boxShadow: [
          // 3D shadow depth
          BoxShadow(
            color: shadowColor,
            offset: const Offset(4, 4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: highlightColor,
            offset: const Offset(-4, -4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
            TColors.darkPrimaryContainer.withOpacity(0.9),
            TColors.darkSecondaryContainer.withOpacity(0.6),
          ]
              : [
            Colors.white.withOpacity(0.8),
            TColors.lightPrimaryContainer.withOpacity(0.9),
          ],
        ),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
