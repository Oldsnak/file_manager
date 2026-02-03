import 'package:flutter/material.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(color: dark ? TColors.textWhite : TColors.primary),
        ),
        iconTheme: IconThemeData(color: dark ? TColors.textWhite : TColors.primary),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction, size: 60, color: TColors.primary),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(
                "Coming soon",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: TSizes.sm),
              Text(
                subtitle ?? "This feature will be available in next update.",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: TColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
