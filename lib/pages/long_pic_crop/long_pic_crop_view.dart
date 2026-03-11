import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'long_pic_crop_logic.dart';
class LongPicCropView extends GetView<LongPicCropLogic> {
  const LongPicCropView({super.key});
  static const _ratioLabels = [
    'Free', '1 : 1', '4 : 3', '3 : 4', '16 : 9', '9 : 16'
  ];
  static const _ratioSizes = [
    Size(20, 20),
    Size(18, 18),
    Size(22, 16),
    Size(16, 22),
    Size(26, 14),
    Size(14, 26),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildCropPreview()),
          _buildBottomControls(),
        ],
      ),
    );
  }
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: Text('Crop',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600)),
      actions: [
        Obx(() => GestureDetector(
              onTap: controller.isProcessing.value
                  ? null
                  : controller.onConfirmTap,
              child: Container(
                margin: EdgeInsets.only(right: 16.w),
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: controller.isProcessing.value
                      ? Colors.grey
                      : const Color(0xFF4A90E2),
                  shape: BoxShape.circle,
                ),
                child: controller.isProcessing.value
                    ? Padding(
                        padding: EdgeInsets.all(8.w),
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(Icons.check,
                        color: Colors.white, size: 18.w),
              ),
            )),
      ],
    );
  }
  Widget _buildCropPreview() {
    return Container(
      color: Colors.black,
      child: Obx(() {
        if (controller.isLoading.value &&
            controller.currentPhotoFile.value == null) {
          return const Center(
              child:
                  CircularProgressIndicator(color: Colors.white));
        }
        if (controller.currentPhotoFile.value == null) {
          return Center(
            child: Icon(Icons.image_outlined,
                size: 60.w, color: Colors.white.withOpacity(0.3)),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.updateImageDisplayRect(
                Rect.fromLTWH(
                    0, 0, constraints.maxWidth, constraints.maxHeight),
              );
            });
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.file(
                    controller.currentPhotoFile.value!,
                    fit: BoxFit.contain,
                    key: ValueKey(
                        controller.currentPhotoFile.value!.path),
                  ),
                ),
                _buildCropOverlay(),
                Obx(() => AnimatedOpacity(
                      opacity: controller.isProcessing.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: IgnorePointer(
                        ignoring: !controller.isProcessing.value,
                        child: Container(
                          color: Colors.black.withOpacity(0.6),
                          child: Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                    color: Colors.white),
                                SizedBox(height: 12.h),
                                Text('Processing...',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.sp)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )),
              ],
            );
          },
        );
      }),
    );
  }
  Widget _buildCropOverlay() {
    return Obx(() {
      if (controller.cropBoxWidth.value == 0 ||
          controller.cropBoxHeight.value == 0) {
        return const SizedBox.shrink();
      }
      final l = controller.cropBoxLeft.value;
      final t = controller.cropBoxTop.value;
      final w = controller.cropBoxWidth.value;
      final h = controller.cropBoxHeight.value;
      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CropMaskPainter(
                    cropRect: Rect.fromLTWH(l, t, w, h)),
              ),
            ),
          ),
          Positioned(
            left: l,
            top: t,
            width: w,
            height: h,
            child: GestureDetector(
              onPanStart: controller.onCropBoxPanStart,
              onPanUpdate: controller.onCropBoxPanUpdate,
              behavior: HitTestBehavior.translucent,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color(0xFF4A90E2), width: 2),
                ),
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
          ),
          _buildCornerHandle('tl', l, t),
          _buildCornerHandle('tr', l + w, t),
          _buildCornerHandle('bl', l, t + h),
          _buildCornerHandle('br', l + w, t + h),
        ],
      );
    });
  }
  Widget _buildCornerHandle(
      String corner, double left, double top) {
    final size = 26.w;
    final offset = size / 2;
    return Positioned(
      left: left - offset,
      top: top - offset,
      child: GestureDetector(
        onPanStart: (d) => controller.onCornerDragStart(corner, d),
        onPanUpdate: controller.onCornerDragUpdate,
        onPanEnd: controller.onCornerDragEnd,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildBottomControls() {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
      child: _buildRatioSelector(),
    );
  }
  Widget _buildRatioSelector() {
    return Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_ratioLabels.length, (index) {
              final isSelected =
                  controller.selectedRatio.value == index;
              final size = _ratioSizes[index];
              return GestureDetector(
                onTap: () => controller.onRatioTap(index),
                child: Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.w),
                          color: isSelected
                              ? const Color(0xFF4A90E2)
                                  .withOpacity(0.15)
                              : Colors.transparent,
                        ),
                        child: Center(
                          child: Container(
                            width: size.width.w,
                            height: size.height.w,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4A90E2)
                                    : const Color(0xFF888888),
                                width: 1.5.w,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _ratioLabels[index],
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isSelected
                              ? const Color(0xFF4A90E2)
                              : const Color(0xFF888888),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ));
  }
}
class _CropMaskPainter extends CustomPainter {
  final Rect cropRect;
  _CropMaskPainter({required this.cropRect});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, cropRect.top), paint);
    canvas.drawRect(
        Rect.fromLTWH(0, cropRect.bottom, size.width,
            size.height - cropRect.bottom),
        paint);
    canvas.drawRect(
        Rect.fromLTWH(0, cropRect.top, cropRect.left, cropRect.height),
        paint);
    canvas.drawRect(
        Rect.fromLTWH(cropRect.right, cropRect.top,
            size.width - cropRect.right, cropRect.height),
        paint);
  }
  @override
  bool shouldRepaint(_CropMaskPainter old) =>
      old.cropRect != cropRect;
}
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(size.width / 3, 0),
        Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0),
        Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3),
        Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3),
        Offset(size.width, size.height * 2 / 3), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
