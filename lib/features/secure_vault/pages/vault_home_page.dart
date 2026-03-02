// lib/features/secure_vault/pages/vault_home_page.dart

import 'dart:io';

import 'package:file_manager/foundation/constants/colors.dart';
import 'package:file_manager/foundation/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../HomePage.dart';
import '../../../core/controllers/vault_controller.dart';
import '../../../core/models/vault_item.dart';
import '../components/vault_actions_sheet.dart';
import '../components/vault_view_toggle.dart';

class VaultHomePage extends StatefulWidget {
  const VaultHomePage({super.key});

  static const String routeName = "/vault-home";

  @override
  State<VaultHomePage> createState() => _VaultHomePageState();
}

class _VaultHomePageState extends State<VaultHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VaultController get _c => Get.find<VaultController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _c.refreshVault();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static List<VaultItemType> _tabTypes(int index) {
    switch (index) {
      case 0:
        return [VaultItemType.video];
      case 1:
        return [VaultItemType.audio];
      case 2:
        return [VaultItemType.image];
      case 3:
        return [VaultItemType.document, VaultItemType.other];
      default:
        return [];
    }
  }

  List<VaultItem> _itemsForTab(int tabIndex) {
    final types = _tabTypes(tabIndex);
    return _c.items.where((it) => types.contains(it.type)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Secure Vault"),
        actions: [const VaultViewToggle()],
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.iconTheme?.color,
          ),
          onPressed: () {
            Get.offAll(() => const HomePage());
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Videos", icon: Icon(Icons.video_file_rounded)),
            Tab(text: "Audios", icon: Icon(Icons.audiotrack_rounded)),
            Tab(text: "Pictures", icon: Icon(Icons.image_rounded)),
            Tab(text: "Other", icon: Icon(Icons.folder_rounded)),
          ],
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (_c.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: List.generate(4, (index) {
              return _VaultTabContent(
                items: _itemsForTab(index),
                emptyMessage: _emptyMessage(index),
                onTapItem: (item) => showVaultActionsSheet(context, item),
                dark: dark,
                theme: theme,
              );
            }),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _c.pickAndLockFiles,
        backgroundColor: TColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _emptyMessage(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return "No videos in vault.\nTap + to lock files.";
      case 1:
        return "No audio files in vault.\nTap + to lock files.";
      case 2:
        return "No pictures in vault.\nTap + to lock files.";
      case 3:
        return "No documents or other files in vault.\nTap + to lock files.";
      default:
        return "No files in this category.";
    }
  }
}

class _VaultTabContent extends StatelessWidget {
  const _VaultTabContent({
    required this.items,
    required this.emptyMessage,
    required this.onTapItem,
    required this.dark,
    required this.theme,
  });

  final List<VaultItem> items;
  final String emptyMessage;
  final void Function(VaultItem) onTapItem;
  final bool dark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: TColors.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final c = Get.find<VaultController>();
    return Obx(() {
      final isList = c.viewMode.value == VaultViewMode.list;
      if (isList) {
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final item = items[i];
            return _VaultListTile(
              item: item,
              theme: theme,
              dark: dark,
              onTap: () => onTapItem(item),
            );
          },
        );
      }
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (context, i) {
          final item = items[i];
          return _VaultGridCard(
            item: item,
            theme: theme,
            dark: dark,
            onTap: () => onTapItem(item),
          );
        },
      );
    });
  }
}

class _VaultListTile extends StatelessWidget {
  const _VaultListTile({
    required this.item,
    required this.theme,
    required this.dark,
    required this.onTap,
  });

  final VaultItem item;
  final ThemeData theme;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile = File(item.storedPath).existsSync();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: hasFile ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            _TypeIcon(type: item.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_formatSize(item.sizeBytes)} • ${_formatDate(item.modified)}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (!hasFile)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  "Missing",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: TColors.error,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: theme.iconTheme.color?.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );
  }
}

class _VaultGridCard extends StatelessWidget {
  const _VaultGridCard({
    required this.item,
    required this.theme,
    required this.dark,
    required this.onTap,
  });

  final VaultItem item;
  final ThemeData theme;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile = File(item.storedPath).existsSync();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: hasFile ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: _TypeIcon(type: item.type),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${_formatSize(item.sizeBytes)} • ${_formatDate(item.modified)}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              ),
            ),
            if (!hasFile)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Missing",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: TColors.error,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final VaultItemType type;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (type) {
      case VaultItemType.image:
        icon = Icons.image_rounded;
        break;
      case VaultItemType.video:
        icon = Icons.video_file_rounded;
        break;
      case VaultItemType.audio:
        icon = Icons.audiotrack_rounded;
        break;
      case VaultItemType.document:
        icon = Icons.description_rounded;
        break;
      case VaultItemType.other:
        icon = Icons.insert_drive_file_rounded;
        break;
    }
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: TColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: TColors.primary, size: 24),
    );
  }
}

String _formatSize(int bytes) {
  if (bytes <= 0) return "0 B";
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes >= gb) return "${(bytes / gb).toStringAsFixed(2)} GB";
  if (bytes >= mb) return "${(bytes / mb).toStringAsFixed(1)} MB";
  if (bytes >= kb) return "${(bytes / kb).toStringAsFixed(0)} KB";
  return "$bytes B";
}

String _formatDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, "0");
  final m = dt.month.toString().padLeft(2, "0");
  final d = dt.day.toString().padLeft(2, "0");
  return "$y-$m-$d";
}
