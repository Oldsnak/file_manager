import 'package:file_manager/common/widgets/texts/t_brand_title_text.dart';
import 'package:flutter/material.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/enums.dart';
import '../../../foundation/constants/sizes.dart';

class BrandTitleWithVerifiedIcon extends StatelessWidget {
  const BrandTitleWithVerifiedIcon({
    super.key,
    required this.title,
    this.maxLines=1,
    this.textColor,
    this.iconColor = TColors.primary,
    this.textAlign = TextAlign.center,
    this.brandTextSize=TextSizes.small,
  });

  final String title;
  final int maxLines;
  final Color? textColor, iconColor;
  final TextAlign? textAlign;
  final TextSizes brandTextSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: BrandTitleText(
            title: title,
            color: textColor,
            maxLines: maxLines,
            textAlign: textAlign,
            brandTextSize: brandTextSize,
          ),
        ),
        SizedBox(width: TSizes.xs,),
        Icon(Icons.verified, color: iconColor, size: TSizes.iconXs,),
      ],
    );
  }
}