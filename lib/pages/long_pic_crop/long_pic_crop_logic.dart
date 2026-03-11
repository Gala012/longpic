import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import '../../utils/index.dart';
class LongPicCropLogic extends GetxController {
  late final String photoPath;
  late final int sourceIndex;
  final currentPhotoFile = Rx<File?>(null);
  final isLoading = false.obs;
  final isProcessing = false.obs;
  final imageWidth = 0.obs;
  final imageHeight = 0.obs;
  final imageDisplayLeft = 0.0.obs;
  final imageDisplayTop = 0.0.obs;
  final imageDisplayWidth = 0.0.obs;
  final imageDisplayHeight = 0.0.obs;
  final cropBoxLeft = 0.0.obs;
  final cropBoxTop = 0.0.obs;
  final cropBoxWidth = 0.0.obs;
  final cropBoxHeight = 0.0.obs;
  final selectedRatio = 0.obs;
  static const List<double?> _ratioValues = [
    null, 1.0, 4 / 3, 3 / 4, 16 / 9, 9 / 16
  ];
  Offset? _lastFocalPoint;
  String? _draggingCorner;
  Offset? _dragStartPoint;
  double? _dragStartWidth;
  double? _dragStartHeight;
  double? _dragStartLeft;
  double? _dragStartTop;
  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    photoPath = args?['photoPath'] as String? ?? '';
    sourceIndex = args?['sourceIndex'] as int? ?? 0;
    if (photoPath.isEmpty) {
      errorToast('No photo path provided');
      Get.back();
      return;
    }
    _loadPhoto(photoPath);
  }
  Future<void> _loadPhoto(String path) async {
    try {
      isLoading.value = true;
      final file = File(path);
      if (!await file.exists()) {
        errorToast('Photo file not found');
        Get.back();
        return;
      }
      currentPhotoFile.value = file;
      await _updateImageSize(file);
    } catch (e) {
      errorToast('Failed to load image');
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> _updateImageSize(File file) async {
    try {
      final data = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      imageWidth.value = frame.image.width;
      imageHeight.value = frame.image.height;
    } catch (e) {
      debugPrint('Get image size error: $e');
    }
  }
  void updateImageDisplayRect(Rect displayRect) {
    if (imageWidth.value == 0 || imageHeight.value == 0) return;
    final containerW = displayRect.width;
    final containerH = displayRect.height;
    final imageAspect = imageWidth.value / imageHeight.value;
    final containerAspect = containerW / containerH;
    double actualW, actualH, offsetX, offsetY;
    if (imageAspect > containerAspect) {
      actualW = containerW;
      actualH = containerW / imageAspect;
      offsetX = 0;
      offsetY = (containerH - actualH) / 2;
    } else {
      actualH = containerH;
      actualW = containerH * imageAspect;
      offsetX = (containerW - actualW) / 2;
      offsetY = 0;
    }
    imageDisplayLeft.value = offsetX;
    imageDisplayTop.value = offsetY;
    imageDisplayWidth.value = actualW;
    imageDisplayHeight.value = actualH;
    if (cropBoxWidth.value == 0 && imageDisplayWidth.value > 0) {
      _initializeCropBox();
    }
  }
  void _initializeCropBox() {
    if (imageDisplayWidth.value == 0 || imageDisplayHeight.value == 0) return;
    final ratio = _ratioValues[selectedRatio.value];
    final maxW = imageDisplayWidth.value * 0.9;
    final maxH = imageDisplayHeight.value * 0.9;
    double boxW, boxH;
    if (ratio == null) {
      final size = maxW < maxH ? maxW : maxH;
      boxW = size;
      boxH = size;
    } else if (ratio >= 1.0) {
      boxW = maxW;
      boxH = boxW / ratio;
      if (boxH > maxH) {
        boxH = maxH;
        boxW = boxH * ratio;
      }
    } else {
      boxH = maxH;
      boxW = boxH * ratio;
      if (boxW > maxW) {
        boxW = maxW;
        boxH = boxW / ratio;
      }
    }
    cropBoxWidth.value = boxW;
    cropBoxHeight.value = boxH;
    cropBoxLeft.value =
        imageDisplayLeft.value + (imageDisplayWidth.value - boxW) / 2;
    cropBoxTop.value =
        imageDisplayTop.value + (imageDisplayHeight.value - boxH) / 2;
    _constrainCropBox();
  }
  void onRatioTap(int index) {
    selectedRatio.value = index;
    _initializeCropBox();
  }
  void onCropBoxPanStart(DragStartDetails details) {
    _lastFocalPoint = details.globalPosition;
  }
  void onCropBoxPanUpdate(DragUpdateDetails details) {
    if (_lastFocalPoint == null) return;
    final delta = details.globalPosition - _lastFocalPoint!;
    cropBoxLeft.value += delta.dx;
    cropBoxTop.value += delta.dy;
    _constrainCropBox();
    _lastFocalPoint = details.globalPosition;
  }
  void onCornerDragStart(String corner, DragStartDetails details) {
    _draggingCorner = corner;
    _dragStartPoint = details.globalPosition;
    _dragStartWidth = cropBoxWidth.value;
    _dragStartHeight = cropBoxHeight.value;
    _dragStartLeft = cropBoxLeft.value;
    _dragStartTop = cropBoxTop.value;
  }
  void onCornerDragUpdate(DragUpdateDetails details) {
    if (_draggingCorner == null || _dragStartPoint == null) return;
    final delta = details.globalPosition - _dragStartPoint!;
    final ratio = _ratioValues[selectedRatio.value];
    double newW = _dragStartWidth!;
    double newH = _dragStartHeight!;
    double newLeft = _dragStartLeft!;
    double newTop = _dragStartTop!;
    switch (_draggingCorner) {
      case 'tl':
        newW = _dragStartWidth! - delta.dx;
        newH = ratio != null ? newW / ratio : _dragStartHeight! - delta.dy;
        newLeft = _dragStartLeft! + (_dragStartWidth! - newW);
        newTop = _dragStartTop! + (_dragStartHeight! - newH);
        break;
      case 'tr':
        newW = _dragStartWidth! + delta.dx;
        newH = ratio != null ? newW / ratio : _dragStartHeight! - delta.dy;
        newTop = _dragStartTop! + (_dragStartHeight! - newH);
        break;
      case 'bl':
        newW = _dragStartWidth! - delta.dx;
        newH = ratio != null ? newW / ratio : _dragStartHeight! + delta.dy;
        newLeft = _dragStartLeft! + (_dragStartWidth! - newW);
        break;
      case 'br':
        newW = _dragStartWidth! + delta.dx;
        newH = ratio != null ? newW / ratio : _dragStartHeight! + delta.dy;
        break;
    }
    if (newW < 50 || newH < 50) return;
    final minLeft = imageDisplayLeft.value;
    final minTop = imageDisplayTop.value;
    final maxRight = imageDisplayLeft.value + imageDisplayWidth.value;
    final maxBottom = imageDisplayTop.value + imageDisplayHeight.value;
    if (newLeft < minLeft ||
        newTop < minTop ||
        newLeft + newW > maxRight ||
        newTop + newH > maxBottom) return;
    cropBoxWidth.value = newW;
    cropBoxHeight.value = newH;
    cropBoxLeft.value = newLeft;
    cropBoxTop.value = newTop;
  }
  void onCornerDragEnd(DragEndDetails details) {
    _draggingCorner = null;
    _dragStartPoint = null;
  }
  void _constrainCropBox() {
    if (imageDisplayWidth.value == 0) return;
    final minLeft = imageDisplayLeft.value;
    final minTop = imageDisplayTop.value;
    final maxLeft = imageDisplayLeft.value +
        imageDisplayWidth.value -
        cropBoxWidth.value;
    final maxTop = imageDisplayTop.value +
        imageDisplayHeight.value -
        cropBoxHeight.value;
    cropBoxLeft.value = cropBoxLeft.value
        .clamp(minLeft, maxLeft < minLeft ? minLeft : maxLeft);
    cropBoxTop.value = cropBoxTop.value
        .clamp(minTop, maxTop < minTop ? minTop : maxTop);
  }
  Rect _screenToCropCoords() {
    final scale = imageWidth.value / imageDisplayWidth.value;
    final relLeft = cropBoxLeft.value - imageDisplayLeft.value;
    final relTop = cropBoxTop.value - imageDisplayTop.value;
    final pixX =
        (relLeft * scale).clamp(0.0, imageWidth.value.toDouble());
    final pixY =
        (relTop * scale).clamp(0.0, imageHeight.value.toDouble());
    final pixW = (cropBoxWidth.value * scale)
        .clamp(1.0, imageWidth.value.toDouble() - pixX);
    final pixH = (cropBoxHeight.value * scale)
        .clamp(1.0, imageHeight.value.toDouble() - pixY);
    return Rect.fromLTWH(pixX, pixY, pixW, pixH);
  }
  Future<void> onConfirmTap() async {
    if (currentPhotoFile.value == null || isProcessing.value) return;
    try {
      isProcessing.value = true;
      final cropRect = _screenToCropCoords();
      final x = cropRect.left.round();
      final y = cropRect.top.round();
      final w = cropRect.width.round();
      final h = cropRect.height.round();
      if (w < 10 || h < 10) {
        errorToast('Crop area is too small');
        return;
      }
      final rawData =
          await currentPhotoFile.value!.readAsBytes();
      final decoded = img.decodeImage(rawData);
      if (decoded == null) {
        errorToast('Failed to decode image');
        return;
      }
      final cropped = img.copyCrop(decoded,
          x: x.clamp(0, decoded.width - 1),
          y: y.clamp(0, decoded.height - 1),
          width: w.clamp(1, decoded.width - x),
          height: h.clamp(1, decoded.height - y));
      final resultData =
          Uint8List.fromList(img.encodeJpg(cropped, quality: 95));
      final resultFile = File(
          '${Directory.systemTemp.path}/long_pic_crop_result_${sourceIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await resultFile.writeAsBytes(resultData);
      Get.back(result: {
        'cropResult': resultFile.path,
        'sourceIndex': sourceIndex,
      });
    } catch (e) {
      errorToast('Crop failed: ${e.toString()}');
    } finally {
      isProcessing.value = false;
    }
  }
}
