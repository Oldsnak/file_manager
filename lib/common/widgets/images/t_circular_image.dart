import 'package:flutter/material.dart';

import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

class CircularImage extends StatelessWidget {
  const CircularImage({
    super.key,
    this.fit = BoxFit.cover,
    required this.image,
    this.isNetworkImage = false,
    this.overlayColor,
    this.backgroundColor,
    this.width = 56,
    this.height = 56,
    this.padding = TSizes.sm,
    this.applyOverlayColor = true,
  });

  final BoxFit fit;
  final String image;
  final bool isNetworkImage, applyOverlayColor;
  final Color? overlayColor;
  final Color? backgroundColor;
  final double width, height, padding;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor ?? (dark ? TColors.black : TColors.white),
        shape: BoxShape.circle,
      ),

      child: ClipOval(
        child: Image(
          image: isNetworkImage
              ? NetworkImage(image)
              : AssetImage(image) as ImageProvider,

          fit: fit,   // <-- THIS ALONE handles perfect scaling

          // REMOVE width/height here to avoid cropping!
          // width: width,
          // height: height,

          color: applyOverlayColor
              ? (overlayColor ?? (dark ? TColors.white : TColors.black))
              : null,
          colorBlendMode:
          applyOverlayColor ? BlendMode.srcIn : BlendMode.srcOver,
        ),
      ),
    );
  }
}
