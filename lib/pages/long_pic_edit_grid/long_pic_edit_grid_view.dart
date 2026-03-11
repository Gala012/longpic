import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../main.dart';
import 'long_pic_edit_grid_logic.dart';
class LongPicEditGridView extends GetView<LongPicEditGridLogic> {
  const LongPicEditGridView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPreviewArea(),
                ],
              ),
            ),
          ),
          Obx(() => controller.selectedIndex.value >= 0
              ? _buildToolbar()
              : const SizedBox.shrink()),
          _buildPicsPerRowControl(),
          _buildBottomBar(context),
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
        'Grid Collage',
        style: TextStyle(
            color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      actions: [
        Obx(() => IconButton(
              icon: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: controller.isSaving.value ? Colors.grey : primaryColor,
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.isSaving.value)
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      Icon(Icons.save_alt, color: Colors.white, size: 16.w),
                    SizedBox(width: 4.w),
                    Text('Save',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              onPressed:
                  controller.isSaving.value ? null : controller.onSaveTap,
            )),
      ],
    );
  }
  Widget _buildPreviewArea() {
    return Obx(() {
      if (controller.isLoading.value && controller.imageDataList.isEmpty) {
        return Container(
          height: 400.h,
          alignment: Alignment.center,
          child: CircularProgressIndicator(color: primaryColor),
        );
      }
      return RepaintBoundary(
        key: controller.previewKey,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          panEnabled: true,
          scaleEnabled: true,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: _buildEditableGrid(),
          ),
        ),
      );
    });
  }
  Widget _buildEditableGrid() {
    return Obx(() {
      final config = controller.borderConfig.value;
      final spacing = config.spacing;
      final outerBorder = config.outerBorder;
      final borderColor = config.color;
      final picsPerRow = controller.picsPerRow.value;
      return Container(
        padding: EdgeInsets.all(outerBorder),
        decoration: BoxDecoration(
          color: borderColor,
          borderRadius: BorderRadius.circular(4.w),
        ),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: picsPerRow,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: _getAspectRatio(),
          ),
          itemCount: controller.imageDataList.length,
          itemBuilder: (_, index) {
            return _buildPhotoItem(index);
          },
        ),
      );
    });
  }
  double _getAspectRatio() {
    final index = controller.selectedRatioIndex.value;
    final ratio = LongPicEditGridLogic.aspectRatioOptions[index].ratio;
    return ratio ?? 1.0;
  }
  Widget _buildPhotoItem(int index) {
    return Obx(() {
      final isSelected = controller.selectedIndex.value == index;
      final editedPath = controller.editedPaths[index];
      final imageData = controller.imageDataList[index];
      return GestureDetector(
        onTap: () => controller.onPhotoTap(index),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2.w),
              child: editedPath != null && File(editedPath).existsSync()
                  ? Image.file(
                      File(editedPath),
                      fit: BoxFit.cover,
                    )
                  : Image.memory(
                      imageData,
                      fit: BoxFit.cover,
                    ),
            ),
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red,
                    width: 4.w,
                  ),
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 4.w,
                right: 4.w,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12.w,
                  ),
                ),
              ),
          ],
        ),
      );
    });
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
  Widget _buildPicsPerRowControl() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      color: const Color(0xFF242424),
      child: Obx(() => Row(
            children: [
              Text('Pics Per Row',
                  style: TextStyle(color: Colors.white, fontSize: 13.sp)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.w),
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: controller.picsPerRow.value.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    onChanged: controller.onPicsPerRowChanged,
                  ),
                ),
              ),
              Container(
                width: 30.w,
                alignment: Alignment.center,
                child: Text(
                  '${controller.picsPerRow.value}',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )),
    );
  }
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      height: 70.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildBottomAction(Icons.border_all_outlined, 'Border', () {
              _showBorderPanel(context);
            }),
            _buildBottomAction(Icons.aspect_ratio, 'Aspect Ratio', () {
              controller.openAspectRatioPanel();
              _showAspectRatioPanel(context);
            }),
            _buildBottomAction(
                Icons.shuffle, 'Shuffle', controller.onShuffleTap),
            _buildBottomAction(Icons.add_photo_alternate_outlined, 'Add Photo',
                controller.onAddPhotoTap),
          ],
        ),
      ),
    );
  }
  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        width: 80.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24.w),
            SizedBox(height: 4.h),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 10.sp)),
          ],
        ),
      ),
    );
  }
  void _showBorderPanel(BuildContext context) {
    Get.bottomSheet(_GridBorderPanel(controller: controller),
        isScrollControlled: true);
  }
  void _showAspectRatioPanel(BuildContext context) {
    Get.bottomSheet(_AspectRatioPanel(controller: controller),
        isScrollControlled: true);
  }
}
class _GridBorderPanel extends StatelessWidget {
  final LongPicEditGridLogic controller;
  _GridBorderPanel({required this.controller});
  final List<Color> _colors = [
    Colors.white,
    Colors.black,
    const Color(0xFF4A90E2),
    const Color(0xFF50C878),
    const Color(0xFFFFD166),
    const Color(0xFFE87040),
    const Color(0xFF9B59B6),
    Colors.grey,
    const Color(0xFFE74C3C),
    const Color(0xFF2ECC71),
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
          SizedBox(height: 16.h),
          _buildColorSection(),
          SizedBox(height: 16.h),
          Obx(() => _buildSliderRow(
              Icons.space_dashboard_outlined,
              'Grid Spacing',
              controller.borderConfig.value.spacing / 20,
              controller.onSpacingChanged)),
          SizedBox(height: 8.h),
          Obx(() => _buildSliderRow(
              Icons.border_outer,
              'Padding',
              controller.borderConfig.value.outerBorder / 20,
              controller.onOuterBorderChanged)),
        ],
      ),
    );
  }
  Widget _buildColorSection() {
    return SizedBox(
      height: 40.w,
      child: Obx(() {
        final selectedColor = controller.borderConfig.value.color;
        final colorWidgets = <Widget>[];
        for (int index = 0; index < _colors.length; index++) {
          final isSelected = _colors[index].value == selectedColor.value;
          colorWidgets.add(
            GestureDetector(
              onTap: () => controller.onBorderColorChanged(_colors[index]),
              child: Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: _colors[index],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: colorWidgets.length,
          separatorBuilder: (_, __) => SizedBox(width: 10.w),
          itemBuilder: (_, index) => colorWidgets[index],
        );
      }),
    );
  }
  Widget _buildSliderRow(
      IconData icon, String label, double value, Function(double) onChanged) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 20.w),
        SizedBox(width: 10.w),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.w),
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: Colors.white,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}
class _AspectRatioPanel extends StatelessWidget {
  final LongPicEditGridLogic controller;
  const _AspectRatioPanel({required this.controller});
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
          SizedBox(height: 16.h),
          Text('Aspect Ratio',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 20.h),
          Obx(() {
            final selectedIndex = controller.selectedRatioIndex.value;
            final ratioWidgets = <Widget>[];
            for (int index = 0;
                index < LongPicEditGridLogic.aspectRatioOptions.length;
                index++) {
              final option = LongPicEditGridLogic.aspectRatioOptions[index];
              final bool isSelected = selectedIndex == index;
              ratioWidgets.add(
                GestureDetector(
                  onTap: () => controller.onAspectRatioChanged(index),
                  child: Column(
                    children: [
                      Container(
                        width: 54.w,
                        height: 64.h,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8.w),
                          border: Border.all(
                            color:
                                isSelected ? Colors.blue : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          option.label,
                          style: TextStyle(
                            color: isSelected ? Colors.blue : Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SizedBox(
              height: 90.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ratioWidgets.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (_, index) => ratioWidgets[index],
              ),
            );
          }),
        ],
      ),
    );
  }
}
