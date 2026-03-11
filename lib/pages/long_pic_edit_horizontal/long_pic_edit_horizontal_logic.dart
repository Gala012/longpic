import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../db_long_pic/data.dart';
import '../../db_long_pic/db_long_pic_entity.dart';
import '../../utils/index.dart';
class BorderConfig {
  final Color color;
  final double padding;
  const BorderConfig({
    this.color = Colors.white,
    this.padding = 8,
  });
  BorderConfig copyWith({
    Color? color,
    double? padding,
  }) {
    return BorderConfig(
      color: color ?? this.color,
      padding: padding ?? this.padding,
    );
  }
}
class _HStitchParams {
  final List<Uint8List> imageDataList;
  final int padding;
  final int bgColorValue;
  final bool isPreview;
  _HStitchParams({
    required this.imageDataList,
    required this.padding,
    required this.bgColorValue,
    this.isPreview = true,
  });
}
class LongPicEditHorizontalLogic extends GetxController {
  late final List<dynamic> _rawPhotos;
  final String mode;
  LongPicEditHorizontalLogic() : mode = _getModeFromArgs();
  static String _getModeFromArgs() {
    final args = Get.arguments as Map<String, dynamic>?;
    return args?['mode'] as String? ?? 'horizontal';
  }
  final scrollController = ScrollController();
  Timer? _debounceTimer;
  final imageDataList = <Uint8List>[].obs;
  final rotations = <int>[].obs;
  final editedPaths = <String?>[].obs;
  final selectedIndex = (-1).obs;
  final isEditMode = true.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final GlobalKey previewKey = GlobalKey();
  final borderConfig = BorderConfig().obs;
  final sortOrder = <int>[].obs;
  final previewImage = Rx<Uint8List?>(null);
  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    _rawPhotos = (args?['photos'] as List<dynamic>?) ?? [];
    if (_rawPhotos.isEmpty) {
      errorToast('No photos selected');
      Get.back();
      return;
    }
    _loadPhotos();
  }
  @override
  void onClose() {
    _debounceTimer?.cancel();
    scrollController.dispose();
    super.onClose();
  }
  Future<void> _loadPhotos() async {
    try {
      isLoading.value = true;
      imageDataList.clear();
      rotations.clear();
      editedPaths.clear();
      List<Uint8List> loaded = [];
      for (final photo in _rawPhotos) {
        Uint8List? data;
        if (photo is AssetEntity) {
          data = await photo.originBytes;
        } else if (photo is String) {
          final file = File(photo);
          if (await file.exists()) data = await file.readAsBytes();
        }
        if (data != null) {
          loaded.add(data);
          rotations.add(0);
          editedPaths.add(null);
        }
      }
      if (loaded.isEmpty) {
        errorToast('Failed to load photos');
        Get.back();
        return;
      }
      imageDataList.value = loaded;
      sortOrder.value = List.generate(loaded.length, (i) => i);
      if (mode == 'smart') {
        await _deduplicatePhotos();
      }
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!isClosed) _generatePreview();
      });
    } catch (e) {
      errorToast('Load failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> _deduplicatePhotos() async {
    final before = imageDataList.length;
    final unique = <Uint8List>[];
    final seen = <int>{};
    for (final data in imageDataList) {
      final hash = data.length ^ data.first ^ data.last;
      if (!seen.contains(hash)) {
        seen.add(hash);
        unique.add(data);
      }
    }
    if (unique.length < before) {
      imageDataList.value = unique;
      rotations.value = List.generate(unique.length, (_) => 0);
      editedPaths.value = List.generate(unique.length, (_) => null);
      sortOrder.value = List.generate(unique.length, (i) => i);
      final removed = before - unique.length;
      successToast('Removed $removed duplicate photo${removed > 1 ? 's' : ''}');
    }
  }
  void _generatePreviewDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _generatePreview();
    });
  }
  Future<void> _generatePreview() async {
    if (imageDataList.isEmpty) return;
    try {
      isLoading.value = true;
      final config = borderConfig.value;
      final orderedData = _getOrderedImageData();
      if (orderedData.isEmpty) {
        errorToast('No valid images to process');
        return;
      }
      final params = _HStitchParams(
        imageDataList: orderedData,
        padding: config.padding.toInt(),
        bgColorValue: config.color.toARGB32(),
        isPreview: true,
      );
      final result = await compute(_stitchInIsolate, params);
      if (result == null) {
        errorToast('Failed to generate preview');
      } else {
        previewImage.value = result;
      }
    } catch (e) {
      debugPrint('Preview error: $e');
      errorToast('Failed to generate preview: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  List<Uint8List> _getOrderedImageData() {
    debugPrint('=== _getOrderedImageData 开始 (横向) ===');
    debugPrint('sortOrder 长度: ${sortOrder.length}');
    debugPrint('imageDataList 长度: ${imageDataList.length}');
    debugPrint('sortOrder 内容: $sortOrder');
    final result = sortOrder.map((i) {
      final path = editedPaths[i];
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (file.existsSync()) {
          try {
            final bytes = file.readAsBytesSync();
            if (bytes.isEmpty) {
              debugPrint('Warning: Empty file at $path, using original image');
              return imageDataList[i];
            }
            debugPrint('使用编辑后的图片 $i: ${bytes.length} bytes');
            return bytes;
          } catch (e) {
            debugPrint(
                'Error reading edited file at $path: $e, using original image');
            return imageDataList[i];
          }
        }
      }
      debugPrint('使用原始图片 $i: ${imageDataList[i].length} bytes');
      return imageDataList[i];
    }).toList();
    debugPrint('=== _getOrderedImageData 完成，返回 ${result.length} 张图片 ===');
    return result;
  }
  static Uint8List? _stitchInIsolate(_HStitchParams params) {
    try {
      print('=== 开始横向拼接，输入图片数量: ${params.imageDataList.length} ===');
      final images = <img.Image>[];
      for (int i = 0; i < params.imageDataList.length; i++) {
        final data = params.imageDataList[i];
        print('处理图片 $i, 数据大小: ${data.length} bytes');
        if (data.isEmpty) {
          print('警告: 图片 $i 数据为空，跳过');
          continue;
        }
        try {
          final decoded = img.decodeImage(data);
          if (decoded != null) {
            print('成功解码图片 $i, 尺寸: ${decoded.width}x${decoded.height}');
            images.add(decoded);
          } else {
            print('警告: 图片 $i 解码失败，返回 null');
          }
        } catch (e) {
          print('错误: 图片 $i 解码异常: $e');
        }
      }
      print('=== 解码完成，成功图片数量: ${images.length} ===');
      if (images.isEmpty) {
        print('错误: 没有可用的图片');
        return null;
      }
      final padding = params.padding;
      final bg = img.ColorRgba8(
        (params.bgColorValue >> 16) & 0xFF,
        (params.bgColorValue >> 8) & 0xFF,
        params.bgColorValue & 0xFF,
        255,
      );
      final maxHeight = images.map((e) => e.height).reduce((a, b) => a > b ? a : b);
      print('最大高度: $maxHeight');
      final resizedImages = <img.Image>[];
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        print('处理图片 $i, 原始尺寸: ${image.width}x${image.height}');
        if (image.height != maxHeight) {
          final aspectRatio = image.width / image.height;
          final newWidth = (maxHeight * aspectRatio).round();
          print('需要缩放图片 $i 到: ${newWidth}x${maxHeight}');
          final resized = img.copyResize(image, width: newWidth, height: maxHeight);
          resizedImages.add(resized);
          print('图片 $i 缩放完成');
        } else {
          print('图片 $i 高度已是最大，无需缩放');
          resizedImages.add(image);
        }
      }
      print('=== 所有图片已处理，resizedImages 数量: ${resizedImages.length} ===');
      final canvasH = maxHeight + padding * 2;
      final totalWidth = resizedImages.map((e) => e.width).reduce((a, b) => a + b);
      final canvasW = totalWidth + padding * 2 + padding * (resizedImages.length - 1);
      print('画布尺寸: ${canvasW}x${canvasH}');
      final canvas = img.Image(width: canvasW, height: canvasH);
      img.fill(canvas, color: bg);
      int cx = padding;
      for (int i = 0; i < resizedImages.length; i++) {
        final image = resizedImages[i];
        img.compositeImage(canvas, image, dstX: cx, dstY: padding);
        cx += image.width;
        if (i < resizedImages.length - 1) {
          cx += padding;
        }
      }
      print('=== 横向拼接完成 ===');
      if (params.isPreview) {
        return Uint8List.fromList(img.encodeJpg(canvas, quality: 80));
      } else {
        return Uint8List.fromList(img.encodePng(canvas, level: 6));
      }
    } catch (e) {
      debugPrint('Stitch error: $e');
      return null;
    }
  }
  void onPhotoTap(int index) {
    isEditMode.value = true;
    selectedIndex.value = selectedIndex.value == index ? -1 : index;
  }
  void onRotateTap() async {
    if (selectedIndex.value < 0) return;
    final idx = selectedIndex.value;
    try {
      final currentData = _getCurrentImageData(idx);
      final decoded = img.decodeImage(currentData);
      if (decoded == null) return;
      final rotated = img.copyRotate(decoded, angle: 90);
      final newData = Uint8List.fromList(img.encodePng(rotated, level: 6));
      final dir = Directory.systemTemp;
      final file = File(
          '${dir.path}/long_pic_h_rotated_${idx}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(newData);
      editedPaths[idx] = file.path;
      await _generatePreview();
    } catch (e) {
      errorToast('Rotate failed');
    }
  }
  Uint8List _getCurrentImageData(int idx) {
    final path = editedPaths[idx];
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) return file.readAsBytesSync();
    }
    return imageDataList[idx];
  }
  Future<void> onReplaceTap() async {
    if (selectedIndex.value < 0) return;
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      errorToast('Photo permission denied');
      return;
    }
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return;
    final assets = await albums.first.getAssetListRange(start: 0, end: 50);
    if (assets.isEmpty) return;
    final selected = await Get.bottomSheet<AssetEntity>(
      _PhotoPickerSheet(assets: assets),
      isScrollControlled: true,
    );
    if (selected == null) return;
    try {
      final data = await selected.originBytes;
      if (data == null) return;
      final idx = selectedIndex.value;
      imageDataList[idx] = data;
      editedPaths[idx] = null;
      imageDataList.refresh();
      await _generatePreview();
    } catch (e) {
      errorToast('Replace failed');
    }
  }
  Future<void> onRemoveTap() async {
    if (selectedIndex.value < 0) return;
    if (imageDataList.length <= 1) {
      errorToast('At least 1 photo is required');
      return;
    }
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Remove this photo from the stitch?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Remove', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm != true) return;
    final idx = selectedIndex.value;
    imageDataList.removeAt(idx);
    rotations.removeAt(idx);
    editedPaths.removeAt(idx);
    sortOrder.value = List.generate(imageDataList.length, (i) => i);
    selectedIndex.value = -1;
    await _generatePreview();
  }
  Future<void> onAddPhotoTap() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      errorToast('Photo permission denied');
      return;
    }
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return;
    final assets = await albums.first.getAssetListRange(start: 0, end: 80);
    if (assets.isEmpty) return;
    final selected = await Get.bottomSheet<List<AssetEntity>>(
      _MultiPhotoPickerSheet(assets: assets),
      isScrollControlled: true,
    );
    if (selected == null || selected.isEmpty) return;
    try {
      final startIndex = imageDataList.length;
      for (final asset in selected) {
        final data = await asset.originBytes;
        if (data != null) {
          imageDataList.add(data);
          rotations.add(0);
          editedPaths.add(null);
        }
      }
      final newIndices = List.generate(
        imageDataList.length - startIndex,
        (i) => startIndex + i,
      );
      sortOrder.addAll(newIndices);
      await _generatePreview();
    } catch (e) {
      errorToast('Failed to add photo');
    }
  }
  void onBorderColorChanged(Color color) {
    borderConfig.value = borderConfig.value.copyWith(color: color);
    _generatePreviewDebounced();
  }
  void onBorderPaddingChanged(double val) {
    borderConfig.value = borderConfig.value.copyWith(padding: val * 20);
    _generatePreviewDebounced();
  }
  void onSortReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = sortOrder.removeAt(oldIndex);
    sortOrder.insert(newIndex, item);
    _generatePreviewDebounced();
  }
  void onCropDone(String resultPath) {
    if (selectedIndex.value < 0) return;
    editedPaths[selectedIndex.value] = resultPath;
    editedPaths.refresh();
    _generatePreview();
  }
  void onMosaicDone(String resultPath) {
    if (selectedIndex.value < 0) return;
    editedPaths[selectedIndex.value] = resultPath;
    editedPaths.refresh();
    _generatePreview();
  }
  Future<void> onCropTap() async {
    if (selectedIndex.value < 0) return;
    final idx = selectedIndex.value;
    final data = _getCurrentImageData(idx);
    final file = File(
        '${Directory.systemTemp.path}/long_pic_crop_src_${idx}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(data);
    final result = await Get.toNamed('/long_crop', arguments: {
      'photoPath': file.path,
      'sourceIndex': idx,
    });
    if (result is Map && result['cropResult'] != null) {
      onCropDone(result['cropResult'] as String);
    }
  }
  Future<void> onMosaicTap() async {
    if (selectedIndex.value < 0) return;
    final idx = selectedIndex.value;
    final data = _getCurrentImageData(idx);
    final file = File(
        '${Directory.systemTemp.path}/long_pic_mosaic_src_${idx}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(data);
    final result = await Get.toNamed('/long_mosaic', arguments: {
      'photoPath': file.path,
      'sourceIndex': idx,
    });
    if (result is Map && result['mosaicResult'] != null) {
      onMosaicDone(result['mosaicResult'] as String);
    }
  }
  Future<void> onSaveTap() async {
    if (isSaving.value || imageDataList.isEmpty) return;
    try {
      isSaving.value = true;
      final ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth && !ps.hasAccess) {
        errorToast('Please allow photo library access in Settings');
        return;
      }
      final capturedImage = await _generateCompleteImage();
      if (capturedImage == null) {
        errorToast('Failed to generate image');
        return;
      }
      final result = await ImageGallerySaverPlus.saveImage(
        capturedImage,
        quality: 100,
        name: 'LongPic_Horizontal_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result['isSuccess'] == true || result['filePath'] != null) {
        await _saveHistory(capturedImage, 'horizontal');
        successToast('Saved to Photos successfully!');
        Get.back();
        Get.back();
      } else {
        errorToast('Failed to save image to Photos');
      }
    } catch (e) {
      errorToast('Save failed: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }
  Future<Uint8List?> _generateCompleteImage() async {
    debugPrint('=== 开始生成完整横向长图 ===');
    debugPrint('当前 imageDataList 数量: ${imageDataList.length}');
    debugPrint('当前 sortOrder: $sortOrder');
    final config = borderConfig.value;
    final orderedData = _getOrderedImageData();
    debugPrint('获取到的有序图片数据: ${orderedData.length} 张');
    final params = _HStitchParams(
      imageDataList: orderedData,
      padding: config.padding.toInt(),
      bgColorValue: config.color.toARGB32(),
      isPreview: false,
    );
    final result = await compute(_stitchInIsolate, params);
    debugPrint('=== 完整横向长图生成${result != null ? '成功' : '失败'} ===');
    return result;
  }
  Future<void> _saveHistory(Uint8List imageData, String type) async {
    try {
      final codec = await ui.instantiateImageCodec(imageData, targetWidth: 200);
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      final thumbData = byteData?.buffer.asUint8List();
      String thumbPath = '';
      if (thumbData != null) {
        final thumbFile = File(
            '${Directory.systemTemp.path}/long_pic_thumb_${DateTime.now().millisecondsSinceEpoch}.png');
        await thumbFile.writeAsBytes(thumbData);
        thumbPath = thumbFile.path;
      }
      final record = HistoryRecord(
        type: type,
        title:
            '${type == 'vertical' ? 'Vertical' : 'Horizontal'} Stitch - ${imageDataList.length} photos',
        thumbnail: thumbPath,
        createdAt: DateTime.now().toIso8601String(),
      );
      await DbLongPic.to.insertHistoryRecord(record);
    } catch (e) {
      debugPrint('Save history failed: $e');
    }
  }
  void refreshAfterEdit(String type, String resultPath) {
    if (type == 'crop') {
      onCropDone(resultPath);
    } else if (type == 'mosaic') {
      onMosaicDone(resultPath);
    }
  }
}
class _PhotoPickerSheet extends StatefulWidget {
  final List<AssetEntity> assets;
  const _PhotoPickerSheet({required this.assets});
  @override
  State<_PhotoPickerSheet> createState() => _PhotoPickerSheetState();
}
class _PhotoPickerSheetState extends State<_PhotoPickerSheet> {
  AssetEntity? _selected;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 2, mainAxisSpacing: 2),
              itemCount: widget.assets.length,
              itemBuilder: (_, i) {
                final asset = widget.assets[i];
                final isSelected = _selected == asset;
                return GestureDetector(
                  onTap: () => setState(() => _selected = asset),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AssetEntityImage(asset,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize.square(150),
                          fit: BoxFit.cover),
                      if (isSelected)
                        Container(
                          color: Colors.green.withOpacity(0.4),
                          child: const Center(
                              child: Icon(Icons.check, color: Colors.white)),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            child: ElevatedButton(
              onPressed:
                  _selected == null ? null : () => Get.back(result: _selected),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: Colors.green,
              ),
              child:
                  const Text('Select', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
class _MultiPhotoPickerSheet extends StatefulWidget {
  final List<AssetEntity> assets;
  const _MultiPhotoPickerSheet({required this.assets});
  @override
  State<_MultiPhotoPickerSheet> createState() => _MultiPhotoPickerSheetState();
}
class _MultiPhotoPickerSheetState extends State<_MultiPhotoPickerSheet> {
  final _selected = <AssetEntity>[];
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 2, mainAxisSpacing: 2),
              itemCount: widget.assets.length,
              itemBuilder: (_, i) {
                final asset = widget.assets[i];
                final isSelected = _selected.contains(asset);
                final order = isSelected ? _selected.indexOf(asset) + 1 : 0;
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selected.remove(asset);
                    } else {
                      _selected.add(asset);
                    }
                  }),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AssetEntityImage(asset,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize.square(150),
                          fit: BoxFit.cover),
                      if (isSelected)
                        Container(color: Colors.black.withOpacity(0.3)),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: isSelected
                            ? Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text('$order',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              )
                            : Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed:
                  _selected.isEmpty ? null : () => Get.back(result: _selected),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.green,
              ),
              child: Text(
                  _selected.isEmpty
                      ? 'Select'
                      : 'Add ${_selected.length} Photo${_selected.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
