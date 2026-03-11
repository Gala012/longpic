import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'long_pic_mosaic_logic.dart';
class LongPicMosaicView extends GetView<LongPicMosaicLogic> {
  const LongPicMosaicView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: Text('Mosaic',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600)),
      actions: [
        Obx(() => GestureDetector(
              onTap:
                  controller.isProcessing.value ? null : controller.onDoneTap,
              child: Container(
                margin: EdgeInsets.only(right: 16.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: controller.isProcessing.value
                      ? Colors.grey
                      : const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(16.w),
                ),
                child: controller.isProcessing.value
                    ? SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Done',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600)),
              ),
            )),
      ],
    );
  }
  Widget _buildBody() {
    return Column(
      children: [
        Expanded(child: _buildCanvas()),
        _buildMosaicStyles(),
        _buildBrushControls(),
      ],
    );
  }
  Widget _buildCanvas() {
    return Obx(() {
      if (controller.isLoading.value &&
          controller.currentPhotoFile.value == null) {
        return const Center(
            child: CircularProgressIndicator(color: Colors.white));
      }
      if (controller.currentPhotoFile.value == null) {
        return Center(
          child: Icon(Icons.image_outlined,
              color: Colors.white.withOpacity(0.2), size: 60.w),
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.updateDisplayRect(
                constraints.maxWidth, constraints.maxHeight);
          });
          return GestureDetector(
            onPanStart: (d) {
              final ro = context.findRenderObject() as RenderBox;
              controller.onPanStart(d, ro);
            },
            onPanUpdate: (d) {
              final ro = context.findRenderObject() as RenderBox;
              controller.onPanUpdate(d, ro);
            },
            onPanEnd: controller.onPanEnd,
            child: SizedBox.expand(
              child: Obx(() {
                controller.drawTrigger.value;
                return CustomPaint(
                  foregroundPainter: _MosaicCanvasPainter(
                    photoFile: controller.currentPhotoFile.value!,
                    strokes: List.from(controller.strokes),
                    currentStroke: controller.currentStroke,
                    imageLeft: controller.imageDisplayLeft.value,
                    imageTop: controller.imageDisplayTop.value,
                    imageWidth: controller.imageDisplayWidth.value,
                    imageHeight: controller.imageDisplayHeight.value,
                    isEraserMode: controller.isEraserMode,
                    eraserPosition: controller.eraserPosition,
                    eraserRadius: controller.eraserRadius.value,
                  ),
                  child: Center(
                    child: Image.file(
                      controller.currentPhotoFile.value!,
                      width: controller.imageDisplayWidth.value,
                      height: controller.imageDisplayHeight.value,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }),
            ),
          );
        },
      );
    });
  }
  Widget _buildMosaicStyles() {
    final styles = [
      {'icon': Icons.cleaning_services_outlined, 'label': 'Eraser'},
      {'icon': Icons.grid_4x4, 'label': 'Pixel'},
      {'icon': Icons.blur_on, 'label': 'Blur'},
      {'icon': Icons.texture, 'label': 'Noise'},
      {'icon': Icons.grid_3x3, 'label': 'Cross'},
    ];
    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: const Color(0xFF1A1A1A),
      child: Obx(() => Row(
            children: styles.asMap().entries.map((entry) {
              final index = entry.key;
              final s = entry.value;
              final isSelected = controller.selectedStyleIndex.value == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.onStyleTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.w),
                          border: Border.all(
                            color:
                                isSelected ? Colors.blue : Colors.transparent,
                          ),
                        ),
                        child: Icon(s['icon'] as IconData,
                            color: Colors.white, size: 20.w),
                      ),
                      SizedBox(height: 4.h),
                      Text(s['label'] as String,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 9.sp)),
                    ],
                  ),
                ),
              );
            }).toList(),
          )),
    );
  }
  Widget _buildBrushControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      color: const Color(0xFF242424),
      child: Column(
        children: [
          Row(
            children: [
              Text('Brush Size',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 13.sp)),
              const Spacer(),
              Obx(() => Text(
                    controller.brushSize.value.round().toString(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold),
                  )),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Obx(() => SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape:
                            RoundSliderThumbShape(enabledThumbRadius: 7.w),
                        activeTrackColor: Colors.blue,
                        inactiveTrackColor: Colors.white.withOpacity(0.2),
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: ((controller.brushSize.value - 10) / 90)
                            .clamp(0.0, 1.0),
                        onChanged: controller.onBrushSizeChanged,
                      ),
                    )),
              ),
              SizedBox(width: 12.w),
              Obx(() => IconButton(
                    onPressed: controller.strokes.isEmpty
                        ? null
                        : controller.onUndoTap,
                    icon: Icon(
                      Icons.undo,
                      color: controller.strokes.isEmpty
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white,
                      size: 22.w,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )),
              SizedBox(width: 12.w),
              Obx(() => IconButton(
                    onPressed: controller.redoStrokes.isEmpty
                        ? null
                        : controller.onRedoTap,
                    icon: Icon(
                      Icons.redo,
                      color: controller.redoStrokes.isEmpty
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white,
                      size: 22.w,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
class _MosaicCanvasPainter extends CustomPainter {
  final File photoFile;
  final List<MosaicStroke> strokes;
  final MosaicStroke? currentStroke;
  final double imageLeft;
  final double imageTop;
  final double imageWidth;
  final double imageHeight;
  final bool isEraserMode;
  final Offset? eraserPosition;
  final double eraserRadius;
  _MosaicCanvasPainter({
    required this.photoFile,
    required this.strokes,
    this.currentStroke,
    required this.imageLeft,
    required this.imageTop,
    required this.imageWidth,
    required this.imageHeight,
    required this.isEraserMode,
    this.eraserPosition,
    required this.eraserRadius,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final allStrokes = [...strokes];
    if (currentStroke != null) {
      allStrokes.add(currentStroke!);
    }
    for (final stroke in allStrokes) {
      if (stroke.isEraser) {
        continue;
      }
      if (stroke.points.length == 1) {
        _drawStrokePoint(canvas, stroke.points.first.offset, stroke);
      } else {
        for (int i = 0; i < stroke.points.length - 1; i++) {
          final p1 = stroke.points[i].offset;
          final p2 = stroke.points[i + 1].offset;
          final steps = (p1 - p2).distance ~/ (stroke.brushSize / 4) + 1;
          for (int s = 0; s <= steps; s++) {
            final t = steps == 0 ? 0.0 : s / steps;
            final p = Offset.lerp(p1, p2, t)!;
            _drawStrokePoint(canvas, p, stroke);
          }
        }
      }
    }
    if (isEraserMode && eraserPosition != null) {
      _drawEraserIndicator(canvas, eraserPosition!);
    }
  }
  void _drawStrokePoint(Canvas canvas, Offset center, MosaicStroke stroke) {
    final radius = stroke.brushSize / 2;
    switch (stroke.type) {
      case MosaicType.pixel:
        _drawPixelEffect(canvas, center, radius);
        break;
      case MosaicType.blur:
        _drawBlurEffect(canvas, center, radius);
        break;
      case MosaicType.noise:
        _drawNoiseEffect(canvas, center, radius);
        break;
      case MosaicType.cross:
        _drawCrossEffect(canvas, center, radius);
        break;
    }
  }
  void _drawPixelEffect(Canvas canvas, Offset center, double radius) {
    final blockSize = 8.0;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withOpacity(0.6);
    for (double x = center.dx - radius;
        x < center.dx + radius;
        x += blockSize) {
      for (double y = center.dy - radius;
          y < center.dy + radius;
          y += blockSize) {
        final dx = x + blockSize / 2 - center.dx;
        final dy = y + blockSize / 2 - center.dy;
        if (dx * dx + dy * dy <= radius * radius) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, blockSize - 1, blockSize - 1),
            paint,
          );
        }
      }
    }
  }
  void _drawBlurEffect(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          Colors.grey.withOpacity(0.7),
          Colors.grey.withOpacity(0.3),
          Colors.grey.withOpacity(0.1),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }
  void _drawNoiseEffect(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.purple.withOpacity(0.5);
    final numPoints = (radius * radius / 15).toInt().clamp(50, 200);
    final random = math.Random((center.dx * 1000 + center.dy).toInt());
    final pointSize = (radius / 10).clamp(2.5, 6.0);
    for (int i = 0; i < numPoints; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = math.sqrt(random.nextDouble()) * radius;
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);
      canvas.drawCircle(Offset(x, y), pointSize, paint);
    }
  }
  void _drawCrossEffect(Canvas canvas, Offset center, double radius) {
    final blockSize = (radius / 4).clamp(6.0, 16.0);
    final lightPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.orange.withOpacity(0.65);
    final darkPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withOpacity(0.65);
    final startX = (center.dx - radius - blockSize).floorToDouble();
    final startY = (center.dy - radius - blockSize).floorToDouble();
    for (double x = startX;
        x < center.dx + radius + blockSize;
        x += blockSize) {
      for (double y = startY;
          y < center.dy + radius + blockSize;
          y += blockSize) {
        final blockCenterX = x + blockSize / 2;
        final blockCenterY = y + blockSize / 2;
        final dx = blockCenterX - center.dx;
        final dy = blockCenterY - center.dy;
        if (dx * dx + dy * dy <= radius * radius) {
          final blockX = (x / blockSize).floor();
          final blockY = (y / blockSize).floor();
          final isLight = (blockX + blockY) % 2 == 0;
          canvas.drawRect(
            Rect.fromLTWH(x, y, blockSize, blockSize),
            isLight ? lightPaint : darkPaint,
          );
        }
      }
    }
  }
  void _drawEraserIndicator(Canvas canvas, Offset position) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final innerPaint = Paint()
      ..color = Colors.red.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, eraserRadius, innerPaint);
    canvas.drawCircle(position, eraserRadius, paint);
  }
  @override
  bool shouldRepaint(_MosaicCanvasPainter old) => true;
}
