// lib/features/secure_vault/pages/vault_home_page.dart

import 'package:file_manager/foundation/constants/colors.dart';
import 'package:file_manager/foundation/helpers/helper_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../HomePage.dart';
import '../../../core/controllers/vault_controller.dart';
import '../../../core/models/vault_item.dart';
import '../../file_browser/components/item_grid.dart';
import '../../file_browser/components/item_tile.dart';
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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _c.refreshVault();
  }

  Future<void> _unlockSelected(BuildContext context) async {
    final count = _c.selectedIds.length;
    if (count == 0) return;

    final restoreDir = await FilePicker.platform.getDirectoryPath();
    if (restoreDir == null || restoreDir.trim().isEmpty) {
      THelperFunctions.showSnackBar('Restore folder not selected');
      return;
    }

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlock files?'),
        content: Text(
          'Restore $count item(s) to the chosen folder?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final total = count;
    final ok = await _c.unlockSelectedToDirectory(restoreDir);
    if (!context.mounted) return;
    THelperFunctions.showSnackBar('Unlocked $ok / $total');
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
        title: Obx(() {
          if (_c.selectionMode.value) {
            return Text('${_c.selectedIds.length} selected');
          }
          return const Text('Secure Vault');
        }),
        actions: [
          Obx(() {
            if (_c.selectionMode.value) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Select all (this tab)',
                    icon: const Icon(Icons.select_all_rounded),
                    onPressed: () {
                      final tabItems = _itemsForTab(_tabController.index);
                      _c.selectAllWithIds(tabItems.map((e) => e.id));
                    },
                  ),
                  IconButton(
                    tooltip: 'Unlock',
                    icon: const Icon(Icons.lock_open_rounded),
                    onPressed: () => _unlockSelected(context),
                  ),
                ],
              );
            }
            return const VaultViewToggle();
          }),
        ],
        leading: Obx(() {
          if (_c.selectionMode.value) {
            return IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear selection',
              onPressed: _c.clearSelection,
            );
          }
          return IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.appBarTheme.iconTheme?.color,
            ),
            onPressed: () {
              Get.offAll(() => const HomePage());
            },
          );
        }),
        bottom: TabBar(
          controller: _tabController,
          labelColor: TColors.primary,
          unselectedLabelColor: theme.tabBarTheme.unselectedLabelColor ??
              theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          indicatorColor: TColors.primary,
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
        foregroundColor: dark ? TColors.dark : TColors.white,
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
    required this.dark,
    required this.theme,
  });

  final List<VaultItem> items;
  final String emptyMessage;
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
            return ItemTile(vaultItem: items[i]);
          },
        );
      }
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.88,
        ),
        itemBuilder: (context, i) {
          return ItemGrid(vaultItem: items[i]);
        },
      );
    });
  }
}
