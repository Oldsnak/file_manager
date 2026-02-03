import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../file_browser/pages/browser_page.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

class DashboardMedicineList extends StatelessWidget {
  const DashboardMedicineList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Center(
        child: Wrap(
          children: [
            //yaha database sy sari categories fetch kry
            CategoryNameDisplayer(name: "Downloads", icon: Icon(Iconsax.document_download, color: TColors.darkPrimary, ), ontap: () {},),
            CategoryNameDisplayer(name: "Documents", icon: Icon(Iconsax.document, color: TColors.darkPrimary), ontap: () {},),
            CategoryNameDisplayer(name: "Apps", icon: Icon(Iconsax.android, color: TColors.darkPrimary), ontap: () {},),
            CategoryNameDisplayer(
              name: "Images",
              icon: Icon(Iconsax.image, color: TColors.darkPrimary),
              ontap: () => Get.to(() => const BrowserPage(title: "Images", type: RequestType.image)),
            ),

            CategoryNameDisplayer(
              name: "Videos",
              icon: Icon(Iconsax.video, color: TColors.darkPrimary),
              ontap: () => Get.to(() => const BrowserPage(title: "Videos", type: RequestType.video)),
            ),

            CategoryNameDisplayer(
              name: "Audios",
              icon: Icon(Iconsax.audio_square, color: TColors.darkPrimary),
              ontap: () => Get.to(() => const BrowserPage(title: "Audios", type: RequestType.audio)),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryNameDisplayer extends StatelessWidget {
  const CategoryNameDisplayer({
    super.key, required this.name, required this.icon, required this.ontap,
  });
  final Icon icon;
  final String name;
  final Callback ontap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        width: 100,
        height: 75,
        padding: EdgeInsets.symmetric(vertical: TSizes.xs, horizontal: TSizes.sm),
        margin: EdgeInsets.only(bottom: TSizes.xs, right: TSizes.xs),
        decoration: BoxDecoration(
          color: TColors.darkContainer,
          borderRadius: BorderRadius.circular(TSizes.sm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            Text(name, style: TextStyle(color: TColors.darkPrimary, fontWeight: FontWeight.bold),),
          ],
        ),
      ),
    );
  }
}
