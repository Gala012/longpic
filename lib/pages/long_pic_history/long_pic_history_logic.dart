import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../db_long_pic/data.dart';
import '../../db_long_pic/db_long_pic_entity.dart';
import '../../utils/index.dart';
class LongPicHistoryLogic extends GetxController {
  final RxList<HistoryRecord> historyList = <HistoryRecord>[].obs;
  final RxBool isSelectMode = false.obs;
  final RxSet<int> selectedIds = <int>{}.obs;
  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }
  Future<void> loadHistory() async {
    try {
      final records = await DbLongPic.to.getHistoryRecords();
      historyList.value = records;
    } catch (e) {
      errorToast('Failed to load history');
    }
  }
  void onToggleSelectMode() {
    isSelectMode.value = !isSelectMode.value;
    if (!isSelectMode.value) {
      selectedIds.clear();
    }
  }
  void onToggleSelect(int id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }
  void onShowItemMenu(HistoryRecord record) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _buildMenuOption(
              Icons.edit_outlined,
              'Rename',
              const Color(0xFF1E293B),
              () {
                Get.back();
                onRenameTap(record);
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _buildMenuOption(
              Icons.delete_outline,
              'Delete',
              const Color(0xFFE74C3C),
              () {
                Get.back();
                onDeleteSingleTap(record.id!);
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _buildMenuOption(
              Icons.close,
              'Cancel',
              const Color(0xFF64748B),
              () => Get.back(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  Widget _buildMenuOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: color, fontSize: 15)),
          ],
        ),
      ),
    );
  }
  void onRenameTap(HistoryRecord record) {
    final TextEditingController textController =
        TextEditingController(text: record.title);
    Get.dialog(
      AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = textController.text.trim();
              if (newTitle.isEmpty) {
                errorToast('Title cannot be empty');
                return;
              }
              Get.back();
              await _updateTitle(record.id!, newTitle);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  Future<void> _updateTitle(int id, String newTitle) async {
    try {
      final success = await DbLongPic.to.updateHistoryRecord(id, newTitle);
      if (success) {
        successToast('Renamed successfully');
        await loadHistory();
      } else {
        errorToast('Failed to rename');
      }
    } catch (e) {
      errorToast('Failed to rename');
    }
  }
  void onDeleteSingleTap(int id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _deleteRecords([id]);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  void onBatchDeleteTap() {
    if (selectedIds.isEmpty) {
      errorToast('Please select at least one record');
      return;
    }
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Records'),
        content: Text(
            'Are you sure you want to delete ${selectedIds.length} record(s)?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _deleteRecords(selectedIds.toList());
              isSelectMode.value = false;
              selectedIds.clear();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  Future<void> _deleteRecords(List<int> ids) async {
    try {
      final allRecords = historyList.where((r) => ids.contains(r.id)).toList();
      for (var record in allRecords) {
        try {
          final file = File(record.thumbnail);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
        }
      }
      final success = await DbLongPic.to.deleteHistoryRecords(ids);
      if (success) {
        successToast('Deleted successfully');
        await loadHistory();
      } else {
        errorToast('Failed to delete');
      }
    } catch (e) {
      errorToast('Failed to delete');
    }
  }
  String getTypeDisplayName(String type) {
    switch (type) {
      case 'vertical':
        return 'Vertical Stitch';
      case 'horizontal':
        return 'Horizontal Stitch';
      case 'grid':
        return 'Grid Collage';
      case 'smart':
        return 'Smart Stitch';
      case 'poster':
        return 'Poster Screenshot';
      default:
        return type;
    }
  }
  String formatCreatedAt(String createdAt) {
    return createdAt;
  }
}
