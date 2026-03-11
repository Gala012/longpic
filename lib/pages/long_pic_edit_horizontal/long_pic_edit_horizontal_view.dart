import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../main.dart';
import 'long_pic_edit_horizontal_logic.dart';
class LongPicEditHorizontalView extends GetView<LongPicEditHorizontalLogic> {
  const LongPicEditHorizontalView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
              child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 16.h),
            child: _buildPreviewArea(),
          )),
          Obx(() => controller.selectedIndex.value >= 0
              ? _buildToolbar()
              : const SizedBox.shrink()),
          _buildBottomBar(),
        ],
      ),
    );
  }
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'Horizontal Stitch',
        style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600),
      ),
      actions: [
        Obx(() => GestureDetector(
              onTap: controller.isSaving.value
                  ? null
                  : controller.onSaveTap,
              child: Container(
                margin: EdgeInsets.only(right: 12.w),
                padding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: controller.isSaving.value
                      ? Colors.grey
                      : primaryColor,
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: controller.isSaving.value
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save_alt,
                              color: Colors.white, size: 16.w),
                          SizedBox(width: 4.w),
                          Text('Save to Album',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            )),
      ],
    );
  }
  Widget _buildPreviewArea() {
    return Obx(() {
      if (controller.isLoading.value && controller.imageDataList.isEmpty) {
        return const Center(
            child: CircularProgressIndicator(color: Colors.white));
      }
      if (controller.isEditMode.value || controller.selectedIndex.value >= 0) {
        return _buildEditableList();
      }
      final preview = controller.previewImage.value;
      if (preview != null) {
        return _buildStitchedPreview(preview);
      }
      return _buildEditableList();
    });
  }
  Widget _buildStitchedPreview(Uint8List preview) {
    return GestureDetector(
      onTap: () => controller.isEditMode.value = true,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        panEnabled: true,
        scaleEnabled: true,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.w),
                  child: Image.memory(
                    preview,
                    fit: BoxFit.fitWidth,
                    width: 1.sw - 32.w,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Tap to edit • Pinch to zoom • Ready to save',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 11.sp),
                ),
                SizedBox(height: 12.h),
                Obx(() => ElevatedButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.onSaveTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.w),
                        ),
                      ),
                      icon: controller.isSaving.value
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.photo_library,
                              color: Colors.white, size: 20.w),
                      label: Text(
                        controller.isSaving.value
                            ? 'Saving...'
                            : 'Save to Album',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildEditableList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final config = controller.borderConfig.value;
          final padding = config.padding;
          final borderColor = config.color;
          final orderedIndices = controller.sortOrder;
          final itemCount = orderedIndices.length;
          return RepaintBoundary(
            key: controller.previewKey,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 32.h),
              color: borderColor,
              child: SingleChildScrollView(
                controller: controller.scrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(right: padding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(itemCount, (i) {
                    final index = orderedIndices[i];
                    final bool isSelected =
                        index == controller.selectedIndex.value;
                    return _buildPhotoItem(
                      index,
                      isSelected,
                      constraints.maxHeight - 64.h,
                      padding,
                    );
                  }),
                ),
              ),
            ),
          );
        });
      },
    );
  }
  Widget _buildPhotoItem(
    int index,
    bool isSelected,
    double containerHeight,
    double padding,
  ) {
    return GestureDetector(
      onTap: () => controller.onPhotoTap(index),
      child: Obx(() {
        final config = controller.borderConfig.value;
        final borderColor = config.color;
        final editedPath = controller.editedPaths[index];
        final imageData = controller.imageDataList[index];
        final imageHeight = containerHeight - padding * 2;
        final imageWidget = editedPath != null && File(editedPath).existsSync()
            ? Image.file(
                File(editedPath),
                key: ValueKey(editedPath),
                fit: BoxFit.fitHeight,
                height: imageHeight,
                gaplessPlayback: true,
              )
            : Image.memory(
                imageData,
                fit: BoxFit.fitHeight,
                height: imageHeight,
                gaplessPlayback: true,
              );
        return Container(
          height: containerHeight,
          decoration: BoxDecoration(
            color: borderColor,
            border: isSelected
                ? Border.all(
                    color: Colors.red,
                    width: 3.w,
                  )
                : null,
          ),
          padding: EdgeInsets.fromLTRB(padding, padding, 0, padding),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2.w),
            child: imageWidget,
          ),
        );
      }),
    );
  }
  Widget _buildToolbar() {
    final tools = [
      {
        'icon': Icons.crop,
        'label': 'Crop',
        'action': () async => await controller.onCropTap()
      },
      {
        'icon': Icons.rotate_right,
        'label': 'Rotate',
        'action': () => controller.onRotateTap()
      },
      {
        'icon': Icons.blur_on,
        'label': 'Mosaic',
        'action': () async => await controller.onMosaicTap()
      },
      {
        'icon': Icons.swap_horiz,
        'label': 'Replace',
        'action': () => controller.onReplaceTap()
      },
      {
        'icon': Icons.delete_outline,
        'label': 'Remove',
        'action': () => controller.onRemoveTap()
      },
    ];
    return Container(
      height: 70.h,
      color: const Color(0xFF242424),
      child: Row(
        children: tools.map((tool) {
          return Expanded(
            child: GestureDetector(
              onTap: tool['action'] as VoidCallback,
              child: Container(
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tool['icon'] as IconData,
                        color: Colors.white, size: 22.w),
                    SizedBox(height: 4.h),
                    Text(tool['label'] as String,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10.sp)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget _buildBottomBar() {
    return Container(
      height: 68.h,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomAction(
              Icons.border_all_outlined, 'Border', () => _showBorderPanel()),
          _buildBottomAction(Icons.sort, 'Sort', () => _showSortPanel()),
          _buildBottomAction(Icons.add_photo_alternate_outlined, 'Add Photo',
              controller.onAddPhotoTap),
        ],
      ),
    );
  }
  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24.w),
          SizedBox(height: 4.h),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 11.sp)),
        ],
      ),
    );
  }
  void _showBorderPanel() {
    Get.bottomSheet(
      _HorizontalBorderPanel(logic: controller),
      isScrollControlled: true,
    );
  }
  void _showSortPanel() {
    Get.bottomSheet(
      _HorizontalSortPanel(logic: controller),
      isScrollControlled: true,
    );
  }
}
class _HorizontalBorderPanel extends StatelessWidget {
  final LongPicEditHorizontalLogic logic;
  const _HorizontalBorderPanel({required this.logic});
  static const List<Color> _colors = [
    Colors.white,
    Colors.black,
    Color(0xFF4A90E2),
    Color(0xFF50C878),
    Color(0xFFFFD166),
    Color(0xFFE87040),
    Color(0xFF9B59B6),
    Colors.grey,
    Color(0xFFE74C3C),
    Color(0xFF2ECC71),
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandle(),
          SizedBox(height: 16.h),
          Text('Border Color',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 12.h),
          _buildColorSection(),
          SizedBox(height: 20.h),
          _buildPaddingSlider(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8.h),
        ],
      ),
    );
  }
  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 36.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
  Widget _buildColorSection() {
    return Obx(() {
      final currentColor = logic.borderConfig.value.color;
      return SizedBox(
        height: 40.w,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _colors.length,
          separatorBuilder: (_, __) => SizedBox(width: 10.w),
          itemBuilder: (_, index) => GestureDetector(
            onTap: () => logic.onBorderColorChanged(_colors[index]),
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: _colors[index],
                shape: BoxShape.circle,
                border: Border.all(
                  color: currentColor == _colors[index]
                      ? Colors.blue
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
  Widget _buildPaddingSlider() {
    return Obx(() {
      final padding = logic.borderConfig.value.padding;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.padding,
                  color: Colors.white.withOpacity(0.7), size: 20.w),
              SizedBox(width: 10.w),
              Text('Padding',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 14.sp)),
              const Spacer(),
              Text('${padding.toInt()}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 13.sp)),
            ],
          ),
          SizedBox(height: 8.h),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.w),
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: (padding / 20).clamp(0.0, 1.0),
              onChanged: (v) => logic.onBorderPaddingChanged(v),
            ),
          ),
        ],
      );
    });
  }
}
class _HorizontalSortPanel extends StatelessWidget {
  final LongPicEditHorizontalLogic logic;
  const _HorizontalSortPanel({required this.logic});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380.h,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text('Sort Photos',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text('Long press to drag and reorder',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 11.sp)),
          SizedBox(height: 12.h),
          Expanded(
            child: Obx(() => ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: logic.sortOrder.length,
                  onReorder: logic.onSortReorder,
                  proxyDecorator: (child, index, animation) => Material(
                    color: Colors.transparent,
                    child: child,
                  ),
                  itemBuilder: (_, i) {
                    final originalIdx = logic.sortOrder[i];
                    final editedPath = logic.editedPaths[originalIdx];
                    final imageData = logic.imageDataList[originalIdx];
                    return Container(
                      key: ValueKey(originalIdx),
                      width: 120.w,
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.w),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7.w),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            editedPath != null && File(editedPath).existsSync()
                                ? Image.file(File(editedPath),
                                    fit: BoxFit.cover)
                                : Image.memory(imageData, fit: BoxFit.cover),
                            Positioned(
                              bottom: 4.h,
                              right: 4.w,
                              child: Icon(Icons.drag_indicator,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 18.w),
                            ),
                            Positioned(
                              top: 4.h,
                              left: 4.w,
                              child: Container(
                                width: 18.w,
                                height: 18.w,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text('${i + 1}',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8.h),
        ],
      ),
    );
  }
}
