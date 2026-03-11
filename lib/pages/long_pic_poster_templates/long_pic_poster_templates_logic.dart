import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'poster_template_model.dart';
class LongPicPosterTemplatesLogic extends GetxController {
  final RxList<PosterTemplate> templates = <PosterTemplate>[].obs;
  final RxBool isLoading = true.obs;
  SharedPreferences? _prefs;
  static const String _downloadedKeyPrefix = 'template_downloaded_';
  @override
  void onInit() {
    super.onInit();
    _initData();
  }
  Future<void> _initData() async {
    try {
      isLoading.value = true;
      _prefs = await SharedPreferences.getInstance();
      await _loadTemplates();
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Fluttertoast.showToast(msg: 'Failed to load templates: ${e.toString()}');
    }
  }
  Future<void> _loadTemplates() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/poster_templates/templates_config.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString) as List;
      final List<PosterTemplate> loadedTemplates = jsonList
          .map((json) => PosterTemplate.fromJson(json as Map<String, dynamic>))
          .toList();
      for (var template in loadedTemplates) {
        template.isDownloaded = _getDownloadedStatus(template.id);
      }
      templates.value = loadedTemplates;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading templates: ${e.toString()}');
      rethrow;
    }
  }
  bool _getDownloadedStatus(String templateId) {
    return _prefs?.getBool('$_downloadedKeyPrefix$templateId') ?? true;
  }
  Future<void> _setDownloadedStatus(String templateId, bool status) async {
    try {
      await _prefs?.setBool('$_downloadedKeyPrefix$templateId', status);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to save download status');
    }
  }
  Future<void> onTemplateTap(PosterTemplate template) async {
    try {
      if (template.isDownloaded) {
        await Get.toNamed(
          '/long_select_photo',
          parameters: {
            'mode': 'poster',
            'maxCount': '${template.requiredImageCount}',
            'templateId': template.id,
            'templateName': template.name,
          },
        );
      } else {
        await _downloadTemplate(template);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    }
  }
  Future<void> _downloadTemplate(PosterTemplate template) async {
    try {
      Fluttertoast.showToast(msg: 'Downloading ${template.name}...');
      await Future.delayed(const Duration(milliseconds: 500));
      template.isDownloaded = true;
      await _setDownloadedStatus(template.id, true);
      templates.refresh();
      Fluttertoast.showToast(msg: '${template.name} downloaded successfully!');
      await Get.toNamed(
        '/long_select_photo',
        parameters: {
          'mode': 'poster',
          'maxCount': '${template.requiredImageCount}',
          'templateId': template.id,
          'templateName': template.name,
        },
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Download failed: ${e.toString()}');
    }
  }
  Future<void> onRefresh() async {
    await _loadTemplates();
  }
}
