// lib/features/secure_vault/pages/vault_home_page.dart
import 'package:file_manager/foundation/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../HomePage.dart';
import 'vault_lock_page.dart';
import 'vault_entry_page.dart';

class VaultHomePage extends StatelessWidget {
  const VaultHomePage({super.key});

  static const String routeName = "/vault-home";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Secure Vault"),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
          ),
          onPressed: () {
            Get.offAll(() => const HomePage());
          },
        ),
      ),


      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _HeaderCard(theme: theme),
              const SizedBox(height: 14),

              // Main actions
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                  children: [
                    _ActionCard(
                      title: "Enter Vault",
                      subtitle: "Unlock with PIN / biometrics",
                      icon: Icons.lock_open_rounded,
                      onTap: () => Get.to(
                            () => const VaultLockPage(),
                        transition: Transition.cupertino,
                      ),
                    ),
                    _ActionCard(
                      title: "Lock Files",
                      subtitle: "Hide your private files",
                      icon: Icons.lock_rounded,
                      onTap: () => Get.to(
                            () => const VaultLockPage(),
                        transition: Transition.cupertino,
                      ),
                    ),
                    _ActionCard(
                      title: "Help",
                      subtitle: "How Secure Vault works",
                      icon: Icons.help_outline_rounded,
                      onTap: () => _openHelpSheet(context),
                    ),
                    _ActionCard(
                      title: "Settings",
                      subtitle: "Change PIN & options",
                      icon: Icons.settings_rounded,
                      onTap: () => Get.snackbar(
                        "Secure Vault",
                        "Settings page will be added next.",
                        snackPosition: SnackPosition.BOTTOM,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Secure Vault Help",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 10),
                _HelpRow(
                  icon: Icons.lock_rounded,
                  title: "Lock Files",
                  desc:
                  "Files are moved into app private storage, so they won’t appear in Gallery/Files apps.",
                ),
                SizedBox(height: 10),
                _HelpRow(
                  icon: Icons.lock_open_rounded,
                  title: "Unlock Files",
                  desc:
                  "Restore files back to their original location (or choose a folder).",
                ),
                SizedBox(height: 10),
                _HelpRow(
                  icon: Icons.security_rounded,
                  title: "Security",
                  desc:
                  "Access requires PIN (and optional biometrics). You can change PIN anytime.",
                ),
                SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: TColors.primary.withOpacity(0.10),

        border: Border.all(color: TColors.primary.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.lock_rounded,
              color: TColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Secure Vault",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Protect your private files with PIN / biometrics.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TColors.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor.withOpacity(0.65)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: TColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.85),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  "Open",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: TColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: TColors.primary,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: TColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: TColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
