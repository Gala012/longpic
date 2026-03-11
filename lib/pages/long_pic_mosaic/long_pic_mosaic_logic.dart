import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import '../../utils/index.dart';
class MosaicPoint {
  final Offset offset;
  const MosaicPoint({required this.offset});
}
class MosaicStroke {
  final String id;
  final List<MosaicPoint> points;
  final double brushSize;
  final MosaicType type;
  final bool isEraser;
  final DateTime timestamp;
  const MosaicStroke({
    required this.id,
    required this.points,
    required this.brushSize,
    required this.type,
    required this.isEraser,
    required this.timestamp,
  });
}
enum MosaicType { pixel, blur, noise, cross }
class LongPicMosaicLogic extends GetxController {
  late final String photoPath;
  late final int sourceIndex;
  final currentPhotoFile = Rx<File?>(null);
  final isLoading = false.obs;
  final isProcessing = false.obs;
  ui.Image? _uiImage;
  final canvasWidth = 0.0.obs;
  final canvasHeight = 0.0.obs;
  final imageDisplayLeft = 0.0.obs;
  final imageDisplayTop = 0.0.obs;
  final imageDisplayWidth = 0.0.obs;
  final imageDisplayHeight = 0.0.obs;
  final strokes = <MosaicStroke>[].obs;
  final redoStrokes = <MosaicStroke>[].obs;
  MosaicStroke? _currentStroke;
  final selectedStyleIndex = 1.obs;
  final brushSize = 50.0.obs;
  Offset? eraserPosition;
  final eraserRadius = 25.0.obs;
  final drawTrigger = 0.obs;
  bool get isEraserMode => selectedStyleIndex.value == 0;
  MosaicType get currentType {
    switch (selectedStyleIndex.value) {
      case 2:
        return MosaicType.blur;
      case 3:
        return MosaicType.noise;
      case 4:
        return MosaicType.cross;
      default:
        return MosaicType.pixel;
    }
  }
  MosaicStroke? get currentStroke => _currentStroke;
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
      final data = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      _uiImage = frame.image;
    } catch (e) {
      errorToast('Failed to load image');
    } finally {
      isLoading.value = false;
    }
  }
  void updateDisplayRect(double w, double h) {
    if (currentPhotoFile.value == null || _uiImage == null) return;
    final imgW = _uiImage!.width.toDouble();
    final imgH = _uiImage!.height.toDouble();
    final imageAspect = imgW / imgH;
    final containerAspect = w / h;
    double actualW, actualH, offsetX, offsetY;
    if (imageAspect > containerAspect) {
      actualW = w;
      actualH = w / imageAspect;
      offsetX = 0;
      offsetY = (h - actualH) / 2;
    } else {
      actualH = h;
      actualW = h * imageAspect;
      offsetX = (w - actualW) / 2;
      offsetY = 0;
    }
    imageDisplayLeft.value = offsetX;
    imageDisplayTop.value = offsetY;
    imageDisplayWidth.value = actualW;
    imageDisplayHeight.value = actualH;
    canvasWidth.value = w;
    canvasHeight.value = h;
  }
  void onPanStart(DragStartDetails details, RenderBox renderBox) {
    final localPos = renderBox.globalToLocal(details.globalPosition);
    if (isEraserMode) {
      eraserPosition = localPos;
      drawTrigger.value++;
    } else {
      _currentStroke = MosaicStroke(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        points: [MosaicPoint(offset: localPos)],
        brushSize: brushSize.value,
        type: currentType,
        isEraser: false,
        timestamp: DateTime.now(),
      );
      strokes.add(_currentStroke!);
      redoStrokes.clear();
      drawTrigger.value++;
    }
  }
  void onPanUpdate(DragUpdateDetails details, RenderBox renderBox) {
    final localPos = renderBox.globalToLocal(details.globalPosition);
    if (isEraserMode) {
      eraserPosition = localPos;
      _eraseAtPoint(localPos);
      drawTrigger.value++;
    } else if (_currentStroke != null) {
      _currentStroke!.points.add(MosaicPoint(offset: localPos));
      drawTrigger.value++;
    }
  }
  void onPanEnd(DragEndDetails details) {
    _currentStroke = null;
    eraserPosition = null;
    drawTrigger.value++;
  }
  void _eraseAtPoint(Offset point) {
    final List<MosaicStroke> newStrokes = [];
    bool hasChanges = false;
    for (final stroke in strokes) {
      if (stroke.isEraser) {
        newStrokes.add(stroke);
        continue;
      }
      final List<bool> shouldErase = [];
      for (final mosaicPoint in stroke.points) {
        final distance = (mosaicPoint.offset - point).distance;
        shouldErase.add(distance <= eraserRadius.value);
      }
      final segments = _splitStroke(stroke, shouldErase);
      if (segments.length != 1 || segments.isEmpty) {
        hasChanges = true;
      }
      newStrokes.addAll(segments);
    }
    if (hasChanges) {
      strokes.value = newStrokes;
      drawTrigger.value++;
    }
  }
  List<MosaicStroke> _splitStroke(MosaicStroke stroke, List<bool> shouldErase) {
    if (shouldErase.every((e) => !e)) {
      return [stroke];
    }
    if (shouldErase.every((e) => e)) {
      return [];
    }
    final List<MosaicStroke> segments = [];
    final List<MosaicPoint> currentSegment = [];
    for (int i = 0; i < stroke.points.length; i++) {
      if (!shouldErase[i]) {
        currentSegment.add(stroke.points[i]);
      } else {
        if (currentSegment.length >= 2) {
          segments.add(MosaicStroke(
            id: '${stroke.id}_seg_${segments.length}',
            points: List.from(currentSegment),
            brushSize: stroke.brushSize,
            type: stroke.type,
            isEraser: stroke.isEraser,
            timestamp: stroke.timestamp,
          ));
        }
        currentSegment.clear();
      }
    }
    if (currentSegment.length >= 2) {
      segments.add(MosaicStroke(
        id: '${stroke.id}_seg_${segments.length}',
        points: List.from(currentSegment),
        brushSize: stroke.brushSize,
        type: stroke.type,
        isEraser: stroke.isEraser,
        timestamp: stroke.timestamp,
      ));
    }
    return segments;
  }
  void onStyleTap(int index) {
    selectedStyleIndex.value = index;
  }
  void onBrushSizeChanged(double val) {
    brushSize.value = val * 90 + 10;
    eraserRadius.value = brushSize.value / 2;
  }
  void onUndoTap() {
    if (strokes.isEmpty) return;
    final last = strokes.removeLast();
    redoStrokes.add(last);
    drawTrigger.value++;
  }
  void onRedoTap() {
    if (redoStrokes.isEmpty) return;
    final last = redoStrokes.removeLast();
    strokes.add(last);
    drawTrigger.value++;
  }
  Future<void> onDoneTap() async {
    if (currentPhotoFile.value == null || isProcessing.value) return;
    if (strokes.isEmpty) {
      Get.back(result: {
        'mosaicResult': photoPath,
        'sourceIndex': sourceIndex,
      });
      return;
    }
    try {
      isProcessing.value = true;
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing mosaic...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
      final rawData = await currentPhotoFile.value!.readAsBytes();
      final srcImage = img.decodeImage(rawData);
      if (srcImage == null) {
        Get.back();
        errorToast('Failed to decode image');
        return;
      }
      final imgW = srcImage.width.toDouble();
      final imgH = srcImage.height.toDouble();
      final scaleX = imgW / imageDisplayWidth.value;
      final scaleY = imgH / imageDisplayHeight.value;
      final processedRegions = <String, bool>{};
      for (final stroke in strokes) {
        if (stroke.isEraser) {
          continue;
        }
        final step = (stroke.brushSize / 4).round().clamp(1, 10);
        for (int i = 0; i < stroke.points.length; i += step) {
          final mosaicPoint = stroke.points[i];
          final relX = mosaicPoint.offset.dx - imageDisplayLeft.value;
          final relY = mosaicPoint.offset.dy - imageDisplayTop.value;
          if (relX < 0 ||
              relY < 0 ||
              relX > imageDisplayWidth.value ||
              relY > imageDisplayHeight.value) continue;
          final pixX = (relX * scaleX).round();
          final pixY = (relY * scaleY).round();
          final radius = (stroke.brushSize * scaleX / 2).round();
          final regionKey = '${pixX ~/ radius}_${pixY ~/ radius}_${stroke.type.index}';
          if (processedRegions.containsKey(regionKey)) continue;
          processedRegions[regionKey] = true;
          _applyMosaic(srcImage, pixX, pixY, radius, stroke.type);
        }
      }
      final resultData =
          Uint8List.fromList(img.encodeJpg(srcImage, quality: 92));
      final resultFile = File(
          '${Directory.systemTemp.path}/long_pic_mosaic_result_${sourceIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await resultFile.writeAsBytes(resultData);
      Get.back();
      Get.back(result: {
        'mosaicResult': resultFile.path,
        'sourceIndex': sourceIndex,
      });
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      errorToast('Failed to apply mosaic: ${e.toString()}');
    } finally {
      isProcessing.value = false;
    }
  }
  void _applyMosaic(
      img.Image image, int cx, int cy, int radius, MosaicType type) {
    switch (type) {
      case MosaicType.pixel:
        _applyPixelMosaic(image, cx, cy, radius);
        break;
      case MosaicType.blur:
        _applyBlurMosaic(image, cx, cy, radius);
        break;
      case MosaicType.noise:
        _applyNoiseMosaic(image, cx, cy, radius);
        break;
      case MosaicType.cross:
        _applyCrossMosaic(image, cx, cy, radius);
        break;
    }
  }
  void _applyPixelMosaic(
      img.Image image, int cx, int cy, int radius) {
    const int blockSize = 12;
    final x0 = (cx - radius).clamp(0, image.width - 1);
    final y0 = (cy - radius).clamp(0, image.height - 1);
    final x1 = (cx + radius).clamp(0, image.width - 1);
    final y1 = (cy + radius).clamp(0, image.height - 1);
    for (int bx = x0; bx <= x1; bx += blockSize) {
      for (int by = y0; by <= y1; by += blockSize) {
        final distX = bx + blockSize / 2 - cx;
        final distY = by + blockSize / 2 - cy;
        if (distX * distX + distY * distY > radius * radius) continue;
        final centerColor =
            image.getPixel(bx + blockSize ~/ 2, by + blockSize ~/ 2);
        for (int px = bx;
            px < bx + blockSize && px < image.width;
            px++) {
          for (int py = by;
              py < by + blockSize && py < image.height;
              py++) {
            image.setPixel(px, py, centerColor);
          }
        }
      }
    }
  }
  void _applyBlurMosaic(
      img.Image image, int cx, int cy, int radius) {
    const int blurKernel = 4;
    const int sampleStep = 2;
    final x0 = (cx - radius).clamp(0, image.width - 1);
    final y0 = (cy - radius).clamp(0, image.height - 1);
    final x1 = (cx + radius).clamp(0, image.width - 1);
    final y1 = (cy + radius).clamp(0, image.height - 1);
    for (int px = x0; px <= x1; px++) {
      for (int py = y0; py <= y1; py++) {
        final dx = px - cx;
        final dy = py - cy;
        if (dx * dx + dy * dy > radius * radius) continue;
        int r = 0, g = 0, b = 0, count = 0;
        for (int kx = -blurKernel; kx <= blurKernel; kx += sampleStep) {
          for (int ky = -blurKernel; ky <= blurKernel; ky += sampleStep) {
            final nx = (px + kx).clamp(0, image.width - 1);
            final ny = (py + ky).clamp(0, image.height - 1);
            final c = image.getPixel(nx, ny);
            r += c.r.toInt();
            g += c.g.toInt();
            b += c.b.toInt();
            count++;
          }
        }
        if (count > 0) {
          image.setPixel(px, py,
              img.ColorRgb8(r ~/ count, g ~/ count, b ~/ count));
        }
      }
    }
  }
  void _applyNoiseMosaic(
      img.Image image, int cx, int cy, int radius) {
    final rand = math.Random();
    final x0 = (cx - radius).clamp(0, image.width - 1);
    final y0 = (cy - radius).clamp(0, image.height - 1);
    final x1 = (cx + radius).clamp(0, image.width - 1);
    final y1 = (cy + radius).clamp(0, image.height - 1);
    for (int px = x0; px <= x1; px++) {
      for (int py = y0; py <= y1; py++) {
        final dx = px - cx;
        final dy = py - cy;
        if (dx * dx + dy * dy > radius * radius) continue;
        image.setPixel(
          px,
          py,
          img.ColorRgb8(
            rand.nextInt(256),
            rand.nextInt(256),
            rand.nextInt(256),
          ),
        );
      }
    }
  }
  void _applyCrossMosaic(
      img.Image image, int cx, int cy, int radius) {
    const int blockSize = 10;
    final x0 = (cx - radius).clamp(0, image.width - 1);
    final y0 = (cy - radius).clamp(0, image.height - 1);
    final x1 = (cx + radius).clamp(0, image.width - 1);
    final y1 = (cy + radius).clamp(0, image.height - 1);
    for (int px = x0; px <= x1; px++) {
      for (int py = y0; py <= y1; py++) {
        final dx = px - cx;
        final dy = py - cy;
        if (dx * dx + dy * dy > radius * radius) continue;
        final isLight =
            ((px ~/ blockSize) + (py ~/ blockSize)) % 2 == 0;
        final c = image.getPixel(px, py);
        if (isLight) {
          image.setPixel(px, py,
              img.ColorRgb8(c.r.toInt(), c.g.toInt(), c.b.toInt()));
        } else {
          image.setPixel(px, py, img.ColorRgb8(30, 30, 30));
        }
      }
    }
  }
  @override
  void onClose() {
    _uiImage?.dispose();
    super.onClose();
  }
}
