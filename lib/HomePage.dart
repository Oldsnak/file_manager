import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:file_manager/features/ram_cleaner/pages/ram_cleaner_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'core/services/vault_auth_service.dart';
import 'features/dashboard/pages/dashboard_page.dart';
import 'features/secure_vault/pages/vault_entry_page.dart';
import 'features/secure_vault/pages/vault_setup_page.dart';

import 'foundation/constants/colors.dart';
import 'foundation/helpers/helper_functions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int current_page = 0;

  // ✅ Keep screens stable. Vault tab now decides: Setup OR Entry (PIN/Fingerprint gate).
  late final List<Widget> screens = [
    const Dashboard(),
    const RamCleanerPage(),
    const _VaultGate(), // ✅ updated
    const Scaffold(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      body: IndexedStack(
        index: current_page,
        children: screens,
      ),
      extendBody: true,
      bottomNavigationBar: CurvedNavigationBar(
        onTap: (index) {
          setState(() {
            current_page = index;
          });
        },
        backgroundColor: Colors.transparent,
        color: TColors.primary,
        animationDuration: const Duration(milliseconds: 300),
        items: [
          Icon(Iconsax.archive_book, color: dark ? TColors.dark : TColors.white),
          Icon(Icons.memory, color: dark ? TColors.dark : TColors.white),
          Icon(Iconsax.security_safe, color: dark ? TColors.dark : TColors.white),
          Icon(Icons.tune, color: dark ? TColors.dark : TColors.white),
        ],
      ),
    );
  }
}

/// ✅ Vault tab gate:
/// - If vault not setup => show VaultSetupPage
/// - If setup => show VaultEntryPage (auth screen), then it will navigate to VaultHomePage
class _VaultGate extends StatelessWidget {
  const _VaultGate();

  @override
  Widget build(BuildContext context) {
    return const VaultEntryPage();
  }
}

