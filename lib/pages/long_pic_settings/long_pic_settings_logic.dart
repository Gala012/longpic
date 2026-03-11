import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../db_long_pic/data.dart';
import '../../utils/index.dart';
class LongPicSettingsLogic extends GetxController {
  final RxString appVersion = ''.obs;
  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
  }
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion.value = 'v${packageInfo.version}';
    } catch (e) {
      appVersion.value = 'v1.0.0';
    }
  }
  void onClearAllDataTap() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'Are you sure you want to clear all history records? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _clearAllData();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  Future<void> _clearAllData() async {
    try {
      final success = await DbLongPic.to.clearAllHistoryRecords();
      if (success) {
        successToast('All data cleared successfully');
      } else {
        errorToast('Failed to clear data');
      }
    } catch (e) {
      errorToast('Failed to clear data');
    }
  }
}
