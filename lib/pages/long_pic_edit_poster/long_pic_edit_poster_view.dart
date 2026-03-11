import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../main.dart';
import 'long_pic_edit_poster_logic.dart';
class LongPicEditPosterView extends GetView<LongPicEditPosterLogic> {
  const LongPicEditPosterView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: textPrimary, size: 20.w),
        onPressed: () => Get.back(),
      ),
      title: Obx(() => Text(
        controller.template.value?.name ?? 'Poster Preview',
        style: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      )),
      actions: [
        Obx(() => Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: ElevatedButton.icon(
            onPressed: controller.isSaving.value ? null : controller.onSaveTap,
            icon: Icon(
              Icons.download_rounded,
              size: 18.w,
              color: Colors.white,
            ),
            label: Text(
              controller.isSaving.value ? 'Saving...' : 'Save',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.w),
              ),
            ),
          ),
        )),
      ],
    );
  }
  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      if (controller.template.value == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.w, color: Colors.grey),
              SizedBox(height: 16.h),
              Text(
                'Template not found',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
            ],
          ),
        );
      }
      return SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Center(
          child: RepaintBoundary(
            key: controller.posterKey,
            child: _buildPosterCanvas(),
          ),
        ),
      );
    });
  }
  Widget _buildPosterCanvas() {
    final template = controller.template.value!;
    final posterWidth = 1.sw - 32.w;
    final imageCount = template.requiredImageCount;
    final posterHeight = posterWidth * (imageCount <= 2 ? 2.2 : imageCount <= 4 ? 2.5 : 3.0);
    return Container(
      width: posterWidth,
      height: posterHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.w),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                template.templateUrl,
                width: posterWidth,
                height: posterHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: posterWidth,
                    height: posterHeight,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 64.w,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            ...template.imageSlots.asMap().entries.map((entry) {
              final index = entry.key;
              final slot = entry.value;
              final imageData = index < controller.loadedImages.length
                  ? controller.loadedImages[index]
                  : null;
              return _buildImageSlot(slot, imageData, posterWidth, posterHeight);
            }),
          ],
        ),
      ),
    );
  }
  Widget _buildImageSlot(dynamic slot, Uint8List? imageData, double posterWidth, double posterHeight) {
    final scaleX = posterWidth / 1080;
    final scaleY = posterHeight / 1920;
    final scale = (scaleX + scaleY) / 2 * 1.2;
    final double left = (slot.x as int).toDouble() * scaleX;
    final double top = (slot.y as int).toDouble() * scaleY;
    final double width = (slot.width as int).toDouble() * scale;
    final double height = (slot.height as int).toDouble() * scale;
    final String shape = slot.shape as String;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: _buildShapedImage(imageData, width, height, shape),
    );
  }
  Widget _buildShapedImage(Uint8List? imageData, double width, double height, String shape) {
    Widget imageWidget;
    if (imageData != null) {
      imageWidget = Image.memory(
        imageData,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Icon(
          Icons.image_outlined,
          size: width * 0.3,
          color: Colors.grey[400],
        ),
      );
    }
    switch (shape) {
      case 'circle':
        return ClipOval(child: imageWidget);
      case 'roundRect':
        return ClipRRect(
          borderRadius: BorderRadius.circular(12.w),
          child: imageWidget,
        );
      case 'rectangle':
      default:
        return imageWidget;
    }
  }
}
