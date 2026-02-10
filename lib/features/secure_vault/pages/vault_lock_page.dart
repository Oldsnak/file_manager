// lib/features/secure_vault/pages/vault_lock_page.dart
import 'dart:io';
import 'package:file_manager/foundation/constants/colors.dart';
import 'package:file_manager/foundation/helpers/helper_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/controllers/vault_controller.dart';
import '../../../core/models/vault_item.dart';


class VaultLockPage extends StatelessWidget {
  const VaultLockPage({super.key});

  static const String routeName = "/secure-vault";

  VaultController get _c => Get.find<VaultController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: TColors.primary,
        title: Obx(() {
          if (_c.selectionMode.value) {
            return Text("Selected: ${_c.selectedIds.length}");
          }
          return const Text("Secure Vault");
        }),
        // centerTitle: true,
        actions: [
          Obx(() {
            if (_c.selectionMode.value) {
              return Row(
                children: [
                  IconButton(
                    tooltip: "Select all",
                    onPressed: _c.selectAll,
                    icon: const Icon(Icons.select_all_rounded),
                  ),
                  IconButton(
                    tooltip: "Unlock selected",
                    onPressed: () => _unlockSelected(context),
                    icon: const Icon(Icons.lock_open_rounded),
                  ),
                  IconButton(
                    tooltip: "Delete selected",
                    onPressed: () => _deleteSelected(context),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                  IconButton(
                    tooltip: "Clear selection",
                    onPressed: _c.clearSelection,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              );
            }

            return Row(
              children: [
                IconButton(
                  tooltip: "Refresh",
                  onPressed: _c.refreshVault,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: "Sort",
                  onPressed: () => _openSortSheet(context),
                  icon: const Icon(Icons.sort_rounded),
                ),
                IconButton(
                  tooltip: "View",
                  onPressed: _c.toggleViewMode,
                  icon: Obx(() {
                    return Icon(
                      _c.viewMode.value == VaultViewMode.list
                          ? Icons.grid_view_rounded
                          : Icons.view_agenda_rounded,
                    );
                  }),
                ),
              ],
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TColors.primary,
        foregroundColor: dark ? Colors.black : Colors.white,
        onPressed: _c.pickAndLockFiles,
        icon: const Icon(Icons.add),
        label: const Text("Add files"),
      ),
      body: SafeArea(
        child: Obx(() {
          if (_c.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = _c.items;

          if (items.isEmpty) {
            return _EmptyState(
              onAdd: _c.pickAndLockFiles,
              onRefresh: _c.refreshVault,
            );
          }

          if (_c.viewMode.value == VaultViewMode.list) {
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final it = items[i];
                return _VaultListTile(
                  item: it,
                  selected: _c.selectedIds.contains(it.id),
                  selectionMode: _c.selectionMode.value,
                  onTap: () => _onItemTap(context, it),
                  onLongPress: () => _onItemLongPress(it),
                );
              },
            );
          }

          // Grid
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.86,
            ),
            itemBuilder: (context, i) {
              final it = items[i];
              return _VaultGridCard(
                item: it,
                selected: _c.selectedIds.contains(it.id),
                selectionMode: _c.selectionMode.value,
                onTap: () => _onItemTap(context, it),
                onLongPress: () => _onItemLongPress(it),
                theme: theme,
              );
            },
          );
        }),
      ),
    );
  }

  // =========================================================
  // ITEM INTERACTIONS
  // =========================================================

  void _onItemLongPress(VaultItem it) {
    if (!_c.selectionMode.value) {
      _c.startSelection(it.id);
    } else {
      _c.toggleSelection(it.id);
    }
  }

  Future<void> _onItemTap(BuildContext context, VaultItem it) async {
    if (_c.selectionMode.value) {
      _c.toggleSelection(it.id);
      return;
    }

    // If file missing (should be cleaned, but just in case)
    if (!File(it.storedPath).existsSync()) {
      Get.snackbar("Vault", "File is missing (deleted from storage?)",
          snackPosition: SnackPosition.BOTTOM);
      await _c.refreshVault();
      return;
    }

    // Open for preview
    await OpenFilex.open(it.storedPath);
  }

  // =========================================================
  // SORT / ACTIONS
  // =========================================================

  void _openSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Obx(() {
          final current = _c.sortOption.value;

          Widget tile(VaultSortOption opt, String label, IconData icon) {
            return ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: current == opt ? const Icon(Icons.check_rounded) : null,
              onTap: () {
                _c.setSort(opt);
                Navigator.of(context).pop();
              },
            );
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                const Text(
                  "Sort by",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                tile(VaultSortOption.dateNewToOld, "Date (new to old)",
                    Icons.schedule_rounded),
                tile(VaultSortOption.dateOldToNew, "Date (old to new)",
                    Icons.history_rounded),
                tile(VaultSortOption.nameAZ, "Name (A → Z)",
                    Icons.sort_by_alpha_rounded),
                tile(VaultSortOption.nameZA, "Name (Z → A)",
                    Icons.sort_by_alpha_rounded),
                tile(VaultSortOption.sizeSmallToLarge, "Size (small → large)",
                    Icons.straighten_rounded),
                tile(VaultSortOption.sizeLargeToSmall, "Size (large → small)",
                    Icons.straighten_rounded),
                const SizedBox(height: 12),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final count = _c.selectedIds.length;
    if (count == 0) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete files?"),
        content: Text("Delete $count selected item(s) from Secure Vault?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final deleted = await _c.deleteSelected();
    Get.snackbar("Vault", "Deleted $deleted item(s)",
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _unlockSelected(BuildContext context) async {
    final selected = _c.items
        .where((x) => _c.selectedIds.contains(x.id))
        .toList(growable: false);

    if (selected.isEmpty) return;

    // We might need restore directory for some items:
    // - originalPath is null/empty
    // - OR original directory doesn't exist (optional safety)
    bool needsDir = selected.any((it) {
      final op = it.originalPath ?? "";
      if (op.trim().isEmpty) return true;
      final parent = _parentDir(op);
      return parent.trim().isEmpty;
    });

    String? restoreDir;

    if (needsDir) {
      restoreDir = await FilePicker.platform.getDirectoryPath();
      if (restoreDir == null || restoreDir.trim().isEmpty) {
        Get.snackbar("Vault", "Restore folder not selected",
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }

    // confirm
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Unlock files?"),
        content: Text("Restore ${selected.length} item(s) back to storage?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Unlock"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    int success = 0;

    for (final it in selected) {
      final op = it.originalPath ?? "";
      final String? dirToUse =
      op.trim().isEmpty ? restoreDir : restoreDir; // allow dir even if op exists
      final restored = await _c.unlockItem(it, restoreDirectory: dirToUse);
      if (restored != null && restored.isNotEmpty) success++;
    }

    _c.clearSelection();

    Get.snackbar(
      "Vault",
      "Unlocked $success / ${selected.length}",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _parentDir(String path) {
    final norm = path.replaceAll("\\", "/");
    final idx = norm.lastIndexOf("/");
    if (idx <= 0) return "";
    return norm.substring(0, idx);
  }
}

// =========================================================
// UI WIDGETS
// =========================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd, required this.onRefresh});

  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 84,
              width: 84,
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 38,
                color: TColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "No files in Vault",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              "Add files to lock them inside Secure Vault.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Refresh"),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text("Add files"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultListTile extends StatelessWidget {
  const _VaultListTile({
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final VaultItem item;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? TColors.primary
                : theme.dividerColor.withOpacity(0.6),
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
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_formatSize(item.sizeBytes)} • ${_formatDate(item.modified)}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (selectionMode) ...[
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color:
                selected ? TColors.primary : theme.iconTheme.color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VaultGridCard extends StatelessWidget {
  const _VaultGridCard({
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.theme,
  });

  final VaultItem item;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? TColors.primary
                : theme.dividerColor.withOpacity(0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: selectionMode
                  ? Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? TColors.primary
                    : theme.iconTheme.color,
              )
                  : const SizedBox(height: 24, width: 24),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                height: 66,
                width: 66,
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(child: _TypeIcon(type: item.type, size: 34)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              _formatSize(item.sizeBytes),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(item.modified),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type, this.size = 26});

  final VaultItemType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (type) {
      case VaultItemType.image:
        icon = Icons.image_rounded;
        break;
      case VaultItemType.video:
        icon = Icons.movie_rounded;
        break;
      case VaultItemType.audio:
        icon = Icons.music_note_rounded;
        break;
      case VaultItemType.document:
        icon = Icons.description_rounded;
        break;
      case VaultItemType.other:
        icon = Icons.insert_drive_file_rounded;
        break;
    }
    return Icon(icon, size: size);
  }
}

// =========================================================
// HELPERS
// =========================================================

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
