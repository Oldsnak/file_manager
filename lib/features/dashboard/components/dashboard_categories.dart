import 'package:file_manager/foundation/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../common/widgets/pages/coming_soon_page.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../file_browser/pages/browser_page.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../file_browser/pages/file_scan_page.dart';

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
            CategoryNameDisplayer(name: "Downloads", icon: Iconsax.document_download, ontap: () => Get.to(() => const FileScanPage(title: "Downloads", category: ScanCategory.downloads,)),),
            CategoryNameDisplayer(name: "Documents", icon: Iconsax.document, ontap: () => Get.to(() => const FileScanPage(title: "Documents", category: ScanCategory.documents,)),),
            CategoryNameDisplayer(name: "Apps", icon: Iconsax.android, ontap: () => Get.to(() => const ComingSoonPage(title: "Apps", subtitle: "Apps listing needs additional Android package APIs.",)),),
            CategoryNameDisplayer(
              name: "Images",
              icon: Iconsax.image,
              ontap: () => Get.to(() => const BrowserPage(title: "Images", type: RequestType.image)),
            ),

            CategoryNameDisplayer(
              name: "Videos",
              icon: Iconsax.video,
              ontap: () => Get.to(() => const BrowserPage(title: "Videos", type: RequestType.video)),
            ),

            CategoryNameDisplayer(
              name: "Audios",
              icon: Iconsax.audio_square,
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
  final IconData icon;
  final String name;
  final Callback ontap;

  @override
  Widget build(BuildContext context) {
    final bool dark = THelperFunctions.isDarkMode(context);
    return GestureDetector(
      onTap: ontap,
      child: Container(
        width: 100,
        height: 75,
        padding: EdgeInsets.symmetric(vertical: TSizes.xs, horizontal: TSizes.sm),
        margin: EdgeInsets.only(bottom: TSizes.xs, right: TSizes.xs),
        decoration: BoxDecoration(
          color: dark ? TColors.darkContainer : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(TSizes.sm),
          border: Border.all(color: dark ? Colors.transparent : Colors.white)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: dark ? TColors.darkPrimary : TColors.black,),
            Text(name, style: TextStyle(color: dark ? TColors.darkPrimary : Colors.black, fontWeight: FontWeight.bold),),
          ],
        ),
      ),
    );
  }
}
