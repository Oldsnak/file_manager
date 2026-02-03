import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:file_manager/features/ram_cleaner/pages/ram_cleaner_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'features/dashboard/pages/dashboard_page.dart';
import 'features/secure_vault/pages/vault_setup_page.dart';
import 'foundation/constants/colors.dart';
import 'foundation/helpers/helper_functions.dart';


class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int current_page=0;
  List<Widget> screens=[
    Dashboard(),
    RamCleanerPage(),
    VaultSetupPage(),
    Scaffold(),
  ];
  @override
  Widget build(BuildContext context) {
    final bool dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      body: IndexedStack(
        index: current_page,
        children:screens,
      ),



      extendBody: true,
      bottomNavigationBar: CurvedNavigationBar(
        onTap: (index){
          setState(() {
            current_page=index;
          });
        },
        backgroundColor: Colors.transparent,
        color: TColors.primary,
        animationDuration: Duration(milliseconds: 300),
        items: [
          Icon(Iconsax.archive_book, color: dark ? TColors.dark : TColors.white),
          Icon(Icons.memory, color: dark ? TColors.dark : TColors.white,),
          Icon(Iconsax.security_safe, color: dark ? TColors.dark : TColors.white),
          Icon(Icons.tune, color: dark ? TColors.dark : TColors.white),
        ],
      ),
    );
  }
}
