import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../main.dart';
import 'long_pic_select_photo_logic.dart';
class LongPicSelectPhotoView extends GetView<LongPicSelectPhotoLogic> {
  const LongPicSelectPhotoView({super.key});
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomBar(),
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
      title: Text(
        _getTitle(),
        style: TextStyle(
            color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.white, fontSize: 15.sp),
          ),
        ),
      ],
    );
  }
  String _getTitle() {
    switch (controller.mode) {
      case 'smart':
        return 'Select Photos (Smart)';
      case 'vertical':
        return 'Select Photos (Vertical)';
      case 'horizontal':
        return 'Select Photos (Horizontal)';
      case 'grid':
        return 'Select Photos (Grid)';
      default:
        return 'Select Photos';
    }
  }
  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value && controller.photos.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      if (controller.photos.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined,
                  color: Colors.white.withOpacity(0.4), size: 60.w),
              SizedBox(height: 12.h),
              Text(
                'No photos found',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 14.sp),
              ),
            ],
          ),
        );
      }
      return Stack(
        children: [
          GridView.builder(
            controller: controller.scrollController,
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 1.5,
              mainAxisSpacing: 1.5,
            ),
            itemCount: controller.photos.length,
            itemBuilder: (context, index) =>
                _buildPhotoItem(controller.photos[index]),
          ),
          if (controller.isLoadingMore.value)
            Positioned(
              bottom: 20.h,
              left: 0,
              right: 0,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      );
    });
  }
  Widget _buildPhotoItem(AssetEntity photo) {
    return Obx(() {
      final isSelected = controller.isSelected(photo);
      final order = isSelected ? controller.selectionOrder(photo) : 0;
      return GestureDetector(
        onTap: () => controller.onPhotoTap(photo),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AssetEntityImage(
              photo,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(200),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF333333),
                child: Icon(Icons.broken_image_outlined,
                    color: Colors.white.withOpacity(0.3), size: 24.w),
              ),
            ),
            if (isSelected) Container(color: Colors.black.withOpacity(0.3)),
            Positioned(
              top: 6.w,
              right: 6.w,
              child: isSelected
                  ? Container(
                      width: 22.w,
                      height: 22.w,
                      decoration: const BoxDecoration(
                        color: accentGreen,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$order',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Container(
                      width: 22.w,
                      height: 22.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }
  Widget _buildBottomBar() {
    return Obx(() {
      final count = controller.selectedPhotos.length;
      final hasSelected = count > 0;
      return Container(
        height: 62.h,
        color: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: hasSelected ? () {} : null,
              child: Text(
                'Preview($count)',
                style: TextStyle(
                  color: hasSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  fontSize: 15.sp,
                ),
              ),
            ),
            GestureDetector(
              onTap: hasSelected ? controller.onDoneTap : null,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: hasSelected ? accentGreen : const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: Text(
                  hasSelected ? '$count  Done' : 'Done',
                  style: TextStyle(
                    color: hasSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
