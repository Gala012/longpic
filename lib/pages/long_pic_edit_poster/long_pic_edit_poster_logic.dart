import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../db_long_pic/data.dart';
import '../../db_long_pic/db_long_pic_entity.dart';
import '../../utils/index.dart';
import '../long_pic_poster_templates/poster_template_model.dart';
class LongPicEditPosterLogic extends GetxController {
  String? templateId;
  String? templateName;
  List<String> photosPaths = [];
  Rx<PosterTemplate?> template = Rx<PosterTemplate?>(null);
  final RxList<Uint8List?> loadedImages = <Uint8List?>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final GlobalKey posterKey = GlobalKey();
  @override
  void onInit() {
    super.onInit();
    _initData();
  }
  Future<void> _initData() async {
    try {
      isLoading.value = true;
      final arguments = Get.arguments as Map<String, dynamic>?;
      if (arguments == null) {
        errorToast('Missing arguments');
        Get.back();
        return;
      }
      templateId = arguments['templateId'] as String?;
      templateName = arguments['templateName'] as String?;
      final photosData = arguments['photos'];
      if (photosData is List) {
        photosPaths = photosData.map((e) => e.toString()).toList();
      }
      if (templateId == null || photosPaths.isEmpty) {
        errorToast('Invalid template or photos');
        Get.back();
        return;
      }
      await _loadTemplate();
      await _loadPhotosData();
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorToast('Failed to load data: ${e.toString()}');
      Get.back();
    }
  }
  Future<void> _loadTemplate() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/poster_templates/templates_config.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString) as List;
      final templateJson = jsonList.firstWhere(
            (item) => item['id'] == templateId,
        orElse: () => null,
      );
      if (templateJson == null) {
        throw Exception('Template not found: $templateId');
      }
      template.value = PosterTemplate.fromJson(templateJson as Map<String, dynamic>);
    } catch (e) {
      errorToast('Failed to load template: ${e.toString()}');
      rethrow;
    }
  }
  Future<void> _loadPhotosData() async {
    try {
      loadedImages.value = List.filled(photosPaths.length, null);
      for (int i = 0; i < photosPaths.length; i++) {
        final filePath = photosPaths[i];
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          loadedImages[i] = bytes;
        }
      }
      loadedImages.refresh();
    } catch (e) {
      errorToast('Failed to load photos: ${e.toString()}');
      rethrow;
    }
  }
  Future<void> onSaveTap() async {
    if (isSaving.value) return;
    try {
      isSaving.value = true;
      successToast('Saving...');
      final posterImage = await _capturePoster();
      if (posterImage == null) {
        throw Exception('Failed to capture poster');
      }
      final thumbnailPath = await _saveThumbnail(posterImage);
      if (thumbnailPath == null) {
        throw Exception('Failed to save thumbnail');
      }
      final result = await ImageGallerySaverPlus.saveImage(
        posterImage,
        quality: 100,
        name: 'poster_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result['isSuccess'] != true) {
        throw Exception('Failed to save to gallery');
      }
      await _saveToHistory(thumbnailPath);
      successToast('Saved successfully!');
      Future.delayed(const Duration(milliseconds: 800), () {
        Get.offAllNamed('/long_home');
      });
    } catch (e) {
      errorToast('Save failed: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }
  Future<Uint8List?> _capturePoster() async {
    try {
      final RenderRepaintBoundary boundary =
      posterKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 5.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Capture error: $e');
      return null;
    }
  }
  Future<String?> _saveThumbnail(Uint8List imageData) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String thumbnailDir = '${appDir.path}/thumbnails';
      final Directory dir = Directory(thumbnailDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final String fileName = 'poster_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = '$thumbnailDir/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(imageData);
      return filePath;
    } catch (e) {
      print('Save thumbnail error: $e');
      return null;
    }
  }
  Future<void> _saveToHistory(String thumbnailPath) async {
    try {
      final now = DateTime.now();
      final record = HistoryRecord(
        type: 'poster',
        title: templateName ?? 'Poster ${now.month}/${now.day}',
        thumbnail: thumbnailPath,
        createdAt: now.toString(),
      );
      await DbLongPic.to.insertHistoryRecord(record);
    } catch (e) {
      print('Failed to save history: $e');
    }
  }
}
