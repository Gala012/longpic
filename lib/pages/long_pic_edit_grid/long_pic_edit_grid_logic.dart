import 'dart:async';
import 'dart:io';
import 'dart:math';
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
class GridBorderConfig {
  final Color color;
  final double outerBorder;
  final double spacing;
  const GridBorderConfig({
    this.color = Colors.white,
    this.outerBorder = 8,
    this.spacing = 4,
  });
  GridBorderConfig copyWith({
    Color? color,
    double? outerBorder,
    double? spacing,
  }) {
    return GridBorderConfig(
      color: color ?? this.color,
      outerBorder: outerBorder ?? this.outerBorder,
      spacing: spacing ?? this.spacing,
    );
  }
}
class AspectRatioOption {
  final String label;
  final String sub;
  final double? ratio;
  const AspectRatioOption({
    required this.label,
    required this.sub,
    this.ratio,
  });
}
class _GridStitchParams {
  final List<Uint8List> imageDataList;
  final int picsPerRow;
  final double? aspectRatio;
  final Color bgColor;
  final double outerBorder;
  final double spacing;
  final bool isPreview;
  _GridStitchParams({
    required this.imageDataList,
    required this.picsPerRow,
    this.aspectRatio,
    required this.bgColor,
    required this.outerBorder,
    required this.spacing,
    this.isPreview = true,
  });
}
class LongPicEditGridLogic extends GetxController {
  late final List<dynamic> _rawPhotos;
  final imageDataList = <Uint8List>[].obs;
  final sortOrder = <int>[].obs;
  final editedPaths = <String?>[].obs;
  final selectedIndex = (-1).obs;
  final picsPerRow = 4.obs;
  final borderConfig = GridBorderConfig().obs;
  final selectedRatioIndex = 3.obs;
  static const aspectRatioOptions = [
    AspectRatioOption(label: '1:1', sub: 'Square', ratio: 1.0),
    AspectRatioOption(label: '3:4', sub: 'Portrait', ratio: 3 / 4),
    AspectRatioOption(label: '4:3', sub: 'Landscape', ratio: 4 / 3),
    AspectRatioOption(label: '9:16', sub: 'Phone', ratio: 9 / 16),
    AspectRatioOption(label: '16:9', sub: 'Wide', ratio: 16 / 9),
    AspectRatioOption(label: 'Original', sub: 'Original', ratio: null),
  ];
  final isLoading = false.obs;
  final isSaving = false.obs;
  final GlobalKey previewKey = GlobalKey();
  final previewImage = Rx<Uint8List?>(null);
  Timer? _debounceTimer;
  static const _fastDebounceMs = 100;
  static const _normalDebounceMs = 300;
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
    super.onClose();
  }
  Future<void> _loadPhotos() async {
    try {
      isLoading.value = true;
      imageDataList.clear();
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
        }
      }
      if (loaded.isEmpty) {
        errorToast('Failed to load photos');
        Get.back();
        return;
      }
      imageDataList.value = loaded;
      sortOrder.value = List.generate(loaded.length, (i) => i);
      editedPaths.value = List.generate(loaded.length, (_) => null);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!isClosed) _generatePreview();
      });
    } catch (e) {
      errorToast('Load failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  void onPicsPerRowChanged(double value) {
    picsPerRow.value = value.toInt();
    _generatePreviewDebounced(fastMode: true);
  }
  void onBorderColorChanged(Color color) {
    borderConfig.value = borderConfig.value.copyWith(color: color);
    _generatePreviewDebounced(fastMode: true);
  }
  void onOuterBorderChanged(double value) {
    borderConfig.value = borderConfig.value.copyWith(outerBorder: value * 20);
    _generatePreviewDebounced(fastMode: true);
  }
  void onSpacingChanged(double value) {
    borderConfig.value = borderConfig.value.copyWith(spacing: value * 20);
    _generatePreviewDebounced(fastMode: true);
  }
  void openAspectRatioPanel() {
  }
  void onAspectRatioChanged(int index) {
    selectedRatioIndex.value = index;
    _generatePreview();
    Get.back();
  }
  void onShuffleTap() {
    final random = Random();
    final newOrder = List<int>.from(sortOrder);
    newOrder.shuffle(random);
    sortOrder.value = newOrder;
    _generatePreview();
    successToast('Photos shuffled');
  }
  void onPhotoTap(int index) {
    selectedIndex.value = selectedIndex.value == index ? -1 : index;
  }
  Future<void> onRotateTap() async {
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
          '${dir.path}/long_pic_grid_rotated_${idx}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(newData);
      editedPaths[idx] = file.path;
      await _generatePreview();
    } catch (e) {
      errorToast('Rotate failed');
    }
  }
  Uint8List _getCurrentImageData(int idx) {
    final path = editedPaths[idx];
    if (path != null && path.isNotEmpty) {
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
        content: const Text('Remove this photo from the grid?'),
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
    editedPaths.removeAt(idx);
    sortOrder.value = List.generate(imageDataList.length, (i) => i);
    selectedIndex.value = -1;
    await _generatePreview();
  }
  Future<void> onCropTap() async {
    if (selectedIndex.value < 0) return;
    final idx = selectedIndex.value;
    final data = _getCurrentImageData(idx);
    final file = File(
        '${Directory.systemTemp.path}/long_pic_grid_crop_src_${idx}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(data);
    final result = await Get.toNamed('/crop', arguments: {
      'photoPath': file.path,
      'sourceIndex': idx,
    });
    if (result is Map && result['cropResult'] != null) {
      editedPaths[selectedIndex.value] = result['cropResult'] as String;
      editedPaths.refresh();
      _generatePreview();
    }
  }
  Future<void> onMosaicTap() async {
    if (selectedIndex.value < 0) return;
    final idx = selectedIndex.value;
    final data = _getCurrentImageData(idx);
    final file = File(
        '${Directory.systemTemp.path}/long_pic_grid_mosaic_src_${idx}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(data);
    final result = await Get.toNamed('/mosaic', arguments: {
      'photoPath': file.path,
      'sourceIndex': idx,
    });
    if (result is Map && result['mosaicResult'] != null) {
      editedPaths[selectedIndex.value] = result['mosaicResult'] as String;
      editedPaths.refresh();
      _generatePreview();
    }
  }
  Future<void> onAddPhotoTap() async {
    try {
      final ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth && !ps.hasAccess) {
        errorToast('Photo permission denied');
        return;
      }
      final albums =
          await PhotoManager.getAssetPathList(type: RequestType.image);
      if (albums.isEmpty) return;
      final assets = await albums.first.getAssetListRange(start: 0, end: 100);
      if (assets.isEmpty) return;
      final selected = await Get.bottomSheet<List<AssetEntity>>(
        _MultiPhotoPickerSheet(assets: assets),
        isScrollControlled: true,
      );
      if (selected == null || selected.isEmpty) return;
      final startIndex = imageDataList.length;
      for (final asset in selected) {
        final data = await asset.originBytes;
        if (data != null) {
          imageDataList.add(data);
          editedPaths.add(null);
        }
      }
      final newIndices = List.generate(
        imageDataList.length - startIndex,
        (i) => startIndex + i,
      );
      sortOrder.addAll(newIndices);
      await _generatePreview();
      successToast('Added ${selected.length} photo${selected.length > 1 ? 's' : ''}');
    } catch (e) {
      errorToast('Failed to add photo: ${e.toString()}');
    }
  }
  void _generatePreviewDebounced({bool fastMode = false}) {
    _debounceTimer?.cancel();
    final delay = fastMode ? _fastDebounceMs : _normalDebounceMs;
    _debounceTimer = Timer(Duration(milliseconds: delay), () {
      _generatePreview();
    });
  }
  Future<void> _generatePreview() async {
    if (imageDataList.isEmpty) return;
    try {
      isLoading.value = true;
      final startTime = DateTime.now();
      final orderedData = sortOrder.map((i) => imageDataList[i]).toList();
      if (orderedData.isEmpty) {
        errorToast('No valid images to process');
        return;
      }
      final config = borderConfig.value;
      final ratioIndex = selectedRatioIndex.value;
      final params = _GridStitchParams(
        imageDataList: orderedData,
        picsPerRow: picsPerRow.value,
        aspectRatio: aspectRatioOptions[ratioIndex].ratio,
        bgColor: config.color,
        outerBorder: config.outerBorder,
        spacing: config.spacing,
        isPreview: true,
      );
      final result = await compute(_stitchGridInIsolate, params);
      final duration = DateTime.now().difference(startTime);
      debugPrint('🎨 Preview generated in ${duration.inMilliseconds}ms');
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
  static Uint8List? _stitchGridInIsolate(_GridStitchParams params) {
    try {
      final images = <img.Image>[];
      for (int i = 0; i < params.imageDataList.length; i++) {
        final data = params.imageDataList[i];
        if (data.isEmpty) continue;
        try {
          final decoded = img.decodeImage(data);
          if (decoded != null) {
            if (params.isPreview) {
              const maxPreviewSize = 800;
              if (decoded.width > maxPreviewSize || decoded.height > maxPreviewSize) {
                final scale = maxPreviewSize / (decoded.width > decoded.height ? decoded.width : decoded.height);
                final newWidth = (decoded.width * scale).toInt();
                final newHeight = (decoded.height * scale).toInt();
                images.add(img.copyResize(decoded, width: newWidth, height: newHeight));
              } else {
                images.add(decoded);
              }
            } else {
              images.add(decoded);
            }
          }
        } catch (e) {
          debugPrint('Error decoding image at index $i: $e');
        }
      }
      if (images.isEmpty) {
        debugPrint('Error: No valid images to stitch');
        return null;
      }
      final picsPerRow = params.picsPerRow;
      final spacing = params.spacing.toInt();
      final outerBorder = params.outerBorder.toInt();
      int rows = (images.length / picsPerRow).ceil();
      int maxWidth = images.map((e) => e.width).reduce((a, b) => a > b ? a : b);
      int cellWidth = maxWidth;
      int cellHeight;
      if (params.aspectRatio != null) {
        cellHeight = (cellWidth / params.aspectRatio!).toInt();
      } else {
        cellHeight = images.map((e) => e.height).reduce((a, b) => a > b ? a : b);
      }
      int canvasWidth =
          picsPerRow * cellWidth + (picsPerRow - 1) * spacing + outerBorder * 2;
      int canvasHeight =
          rows * cellHeight + (rows - 1) * spacing + outerBorder * 2;
      if (params.isPreview) {
        const maxCanvasSize = 1200;
        if (canvasWidth > maxCanvasSize || canvasHeight > maxCanvasSize) {
          final scale = maxCanvasSize / (canvasWidth > canvasHeight ? canvasWidth : canvasHeight);
          canvasWidth = (canvasWidth * scale).toInt();
          canvasHeight = (canvasHeight * scale).toInt();
          cellWidth = (cellWidth * scale).toInt();
          cellHeight = (cellHeight * scale).toInt();
        }
      }
      final bg = img.ColorRgba8(
        params.bgColor.red,
        params.bgColor.green,
        params.bgColor.blue,
        255,
      );
      final canvas = img.Image(width: canvasWidth, height: canvasHeight);
      img.fill(canvas, color: bg);
      int currentRow = 0;
      int currentCol = 0;
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        int x = outerBorder + currentCol * (cellWidth + spacing);
        int y = outerBorder + currentRow * (cellHeight + spacing);
        final resized = _resizeAndCrop(image, cellWidth, cellHeight);
        img.compositeImage(canvas, resized, dstX: x, dstY: y);
        currentCol++;
        if (currentCol >= picsPerRow) {
          currentCol = 0;
          currentRow++;
        }
      }
      if (params.isPreview) {
        return Uint8List.fromList(img.encodeJpg(canvas, quality: 70));
      } else {
        return Uint8List.fromList(img.encodePng(canvas, level: 6));
      }
    } catch (e) {
      debugPrint('Grid stitch error: $e');
      return null;
    }
  }
  static img.Image _resizeAndCrop(
      img.Image src, int targetWidth, int targetHeight) {
    final srcAspect = src.width / src.height;
    final targetAspect = targetWidth / targetHeight;
    img.Image resized;
    if (srcAspect > targetAspect) {
      resized = img.copyResize(src, height: targetHeight);
    } else {
      resized = img.copyResize(src, width: targetWidth);
    }
    final cropX = ((resized.width - targetWidth) / 2).toInt();
    final cropY = ((resized.height - targetHeight) / 2).toInt();
    return img.copyCrop(resized,
        x: cropX, y: cropY, width: targetWidth, height: targetHeight);
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
      final capturedImage = await _capturePreviewArea();
      if (capturedImage == null) {
        errorToast('Failed to capture image');
        return;
      }
      final result = await ImageGallerySaverPlus.saveImage(
        capturedImage,
        quality: 100,
        name: 'LongPic_Grid_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result['isSuccess'] == true || result['filePath'] != null) {
        await _saveHistory(capturedImage);
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
  Future<Uint8List?> _capturePreviewArea() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final RenderRepaintBoundary? boundary =
          previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        print('Boundary is null, using fallback method');
        return await _generateFallbackImage();
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 6.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Capture error: $e, using fallback');
      return await _generateFallbackImage();
    }
  }
  Future<Uint8List?> _generateFallbackImage() async {
    final orderedData = sortOrder.map((i) => imageDataList[i]).toList();
    final config = borderConfig.value;
    final ratioIndex = selectedRatioIndex.value;
    final params = _GridStitchParams(
      imageDataList: orderedData,
      picsPerRow: picsPerRow.value,
      aspectRatio: aspectRatioOptions[ratioIndex].ratio,
      bgColor: config.color,
      outerBorder: config.outerBorder,
      spacing: config.spacing,
      isPreview: false,
    );
    return await compute(_stitchGridInIsolate, params);
  }
  Future<void> _saveHistory(Uint8List imageData) async {
    try {
      final codec =
          await ui.instantiateImageCodec(imageData, targetWidth: 200);
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
        type: 'grid',
        title:
            'Grid Collage - ${imageDataList.length} photo${imageDataList.length > 1 ? 's' : ''}',
        thumbnail: thumbPath,
        createdAt: DateTime.now().toIso8601String(),
      );
      await DbLongPic.to.insertHistoryRecord(record);
    } catch (e) {
      debugPrint('Save history failed: $e');
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
