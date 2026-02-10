import 'package:file_manager/foundation/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import '../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../common/widgets/texts/section_heading.dart';
import '../../../core/controllers/dashboard_controller.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../components/dashboard_categories.dart';
import '../components/product_card_vertical.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = Get.find<DashboardController>();
    final bool dark = THelperFunctions.isDarkMode(context);

    return Scaffold(

      body: RefreshIndicator(
        // onRefresh: dash.refreshStorage,
        onRefresh: dash.refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              TPrimaryHeaderContainer(
                child: Column(
                  children: [
                    // -- Appbar --
                    SizedBox(height: TSizes.appBarHeight,),

                    // -- Categories --
                    Padding(
                      padding: EdgeInsets.only(left: TSizes.defaultSpace),
                      child: Column(
                        children: [
                          // -- Heading
                          SectionHeading(title: 'Main Folders', showActionButton: false, textColor: dark ? Colors.black : Colors.white,),
                          SizedBox(height: TSizes.spaceBtwItems/2,),

                          // Categories
                          DashboardMedicineList()
                        ],
                      ),
                    ),
                    SizedBox(height: TSizes.spaceBtwSections,)
                  ],
                )
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SizedBox(height: TSizes.spaceBtwSections*2,),
                    // Text("Internal Storage:", style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: TColors.primary),),
                    // SizedBox(height: TSizes.spaceBtwItems,),
                    SizedBox(width: double.infinity,),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // SizedBox(height: 50, width: 50,child: Icon(Icons.arrow_back_ios),),
                        MedicalCardVertical(),
                        // SizedBox(height: 50, width: 50,child: Icon(Icons.arrow_forward_ios),),
                      ],
                    ),

                    SizedBox(height: TSizes.spaceBtwItems,),
                    Center(child: ElevatedButton(onPressed: (){}, child: Text("Internal Storage", style: TextStyle(color: TColors.darkContainer),),)),
                    SizedBox(height: TSizes.spaceBtwItems,),
                    // HealthScoreMeter(score: 72),
                  ],
                ),
              ),

              SizedBox(height: TSizes.lg*3,),
            ],
          ),
        ),
      ),
    );
  }
}
