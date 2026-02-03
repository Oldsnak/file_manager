// lib/features/secure_vault/pages/vault_home_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/vault_controller.dart';
import '../../../core/models/vault_item.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/constants/sizes.dart';
import '../../../foundation/helpers/helper_functions.dart';

class VaultHomePage extends StatefulWidget {
  const VaultHomePage({super.key});

  @override
  State<VaultHomePage> createState() => _VaultHomePageState();
}

class _VaultHomePageState extends State<VaultHomePage> {
  final VaultController c = Get.find<VaultController>();

  @override
  void initState() {
    super.initState();
    c.refreshVault();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    final bgGradient = dark
        ? const RadialGradient(
      colors: [
        TColors.darkGradientBackgroundStart,
        TColors.darkGradientBackgroundEnd,
      ],
      radius: 1.0,
    )
        : const RadialGradient(
      colors: [
        TColors.lightGradientBackgroundStart,
        TColors.lightGradientBackgroundEnd,
      ],
      radius: 1.0,
    );

    return Container(
      decoration: BoxDecoration(gradient: bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Secure Vault",
            style: TextStyle(
              color: dark ? TColors.textWhite : TColors.textPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(
            color: dark ? TColors.textWhite : TColors.textPrimary,
          ),
          actions: [
            IconButton(
              tooltip: "Refresh",
              onPressed: c.refreshVault,
              icon: Icon(
                Icons.refresh,
                color: dark ? TColors.textWhite : TColors.textPrimary,
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: TColors.primary,
          icon: const Icon(Icons.lock_outline, color: TColors.textWhite),
          label: const Text(
            "Lock Files",
            style: TextStyle(color: TColors.textWhite),
          ),
          onPressed: c.pickAndLockFiles,
        ),
        body: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Obx(() {
            if (c.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: TColors.primary),
              );
            }

            if (c.items.isEmpty) {
              return _emptyState(context, dark);
            }

            return GridView.builder(
              itemCount: c.items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: TSizes.gridViewSpacing,
                mainAxisSpacing: TSizes.gridViewSpacing,
              ),
              itemBuilder: (_, i) => _vaultItemCard(
                context,
                item: c.items[i],
                dark: dark,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, bool dark) {
    final titleColor = dark ? TColors.textWhite : TColors.textPrimary;
    final subColor = dark ? TColors.darkGrey : TColors.textSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 64, color: TColors.primary),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            "Your vault is empty",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Lock photos, videos or files to keep them private.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: subColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TSizes.spaceBtwSections),
          ElevatedButton.icon(
            onPressed: c.pickAndLockFiles,
            icon: const Icon(Icons.add),
            label: const Text("Add to Vault"),
          ),
        ],
      ),
    );
  }

  Widget _vaultItemCard(
      BuildContext context, {
        required VaultItem item,
        required bool dark,
      }) {
    final cardBg = dark ? TColors.darkContainer : TColors.lightContainer;
    final border = dark ? TColors.darkerGrey : TColors.grey;
    final titleColor = dark ? TColors.textWhite : TColors.textPrimary;

    IconData icon;
    switch (item.type) {
      case VaultItemType.image:
        icon = Icons.image;
        break;
      case VaultItemType.video:
        icon = Icons.videocam;
        break;
      case VaultItemType.audio:
        icon = Icons.audiotrack;
        break;
      case VaultItemType.document:
        icon = Icons.description;
        break;
      default:
        icon = Icons.insert_drive_file;
    }

    return GestureDetector(
      onTap: () => _showItemActions(context, item, dark),
      child: Container(
        padding: const EdgeInsets.all(TSizes.sm),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(TSizes.cardRdiusMd),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: dark
                      ? TColors.darkOptionalContainer
                      : TColors.lightOptionalContainer,
                  borderRadius:
                  BorderRadius.circular(TSizes.borderRadiusMd),
                ),
                child: Center(
                  child: Icon(icon, size: 36, color: TColors.primary),
                ),
              ),
            ),
            const SizedBox(height: TSizes.xs),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemActions(BuildContext context, VaultItem item, bool dark) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
      dark ? TColors.darkContainer : TColors.lightContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock_open),
                title: const Text("Unlock & Restore"),
                onTap: () async {
                  Navigator.pop(context);
                  await c.unlockItem(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: TColors.error),
                title: const Text("Delete from Vault"),
                onTap: () async {
                  Navigator.pop(context);
                  await c.deleteItem(item);
                },
              ),
              const SizedBox(height: TSizes.sm),
            ],
          ),
        );
      },
    );
  }
}
