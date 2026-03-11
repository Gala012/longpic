import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../main.dart';
import '../../db_long_pic/db_long_pic_entity.dart';
import 'long_pic_history_logic.dart';
class LongPicHistoryView extends GetView<LongPicHistoryLogic> {
  const LongPicHistoryView({super.key});
  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: bgColor,
          appBar: _buildAppBar(),
          body: _buildBody(),
          bottomNavigationBar: controller.isSelectMode.value
              ? _buildBottomBar()
              : null,
        ));
  }
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: textPrimary, size: 20.w),
        onPressed: () => Get.back(),
      ),
      title: Obx(() => Text(
            controller.isSelectMode.value
                ? 'Selected ${controller.selectedIds.length} item(s)'
                : 'History',
            style: TextStyle(
                fontSize: 17.sp, fontWeight: FontWeight.bold, color: textPrimary),
          )),
      actions: [
        Obx(() => TextButton(
              onPressed: controller.onToggleSelectMode,
              child: Text(
                controller.isSelectMode.value ? 'Cancel' : 'Select',
                style: TextStyle(color: primaryColor, fontSize: 15.sp),
              ),
            )),
      ],
    );
  }
  Widget _buildBody() {
    return Obx(() {
      if (controller.historyList.isEmpty) {
        return _buildEmpty();
      }
      return ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: controller.historyList.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (_, index) =>
            _buildHistoryItem(controller.historyList[index]),
      );
    });
  }
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: Colors.grey[300], size: 72.w),
          SizedBox(height: 16.h),
          Text(
            'No history yet',
            style: TextStyle(color: Colors.grey[400], fontSize: 16.sp),
          ),
        ],
      ),
    );
  }
  Widget _buildHistoryItem(HistoryRecord record) {
    final Color color = _getColorByType(record.type);
    final bool isSelected = controller.selectedIds.contains(record.id);
    return GestureDetector(
      onTap: controller.isSelectMode.value
          ? () => controller.onToggleSelect(record.id!)
          : null,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.w),
          border: controller.isSelectMode.value && isSelected
              ? Border.all(color: primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (controller.isSelectMode.value) ...[
              Obx(() => SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: Checkbox(
                      value: controller.selectedIds.contains(record.id),
                      onChanged: (_) => controller.onToggleSelect(record.id!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.w)),
                      activeColor: primaryColor,
                    ),
                  )),
              SizedBox(width: 10.w),
            ],
            _buildThumbnail(record, color),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    controller.formatCreatedAt(record.createdAt),
                    style: TextStyle(
                        fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            if (!controller.isSelectMode.value)
              IconButton(
                icon: Icon(Icons.more_horiz,
                    color: const Color(0xFF94A3B8), size: 22.w),
                onPressed: () => controller.onShowItemMenu(record),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildThumbnail(HistoryRecord record, Color color) {
    return Container(
      width: 72.w,
      height: 72.w,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10.w),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.w),
        child: File(record.thumbnail).existsSync()
            ? Image.file(
                File(record.thumbnail),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(color),
              )
            : _buildPlaceholder(color),
      ),
    );
  }
  Widget _buildPlaceholder(Color color) {
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      mainAxisSpacing: 3.w,
      crossAxisSpacing: 3.w,
      children: List.generate(
          4,
          (i) => Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.35 + i * 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
              )),
    );
  }
  Color _getColorByType(String type) {
    switch (type) {
      case 'vertical':
        return const Color(0xFF4A90E2);
      case 'horizontal':
        return const Color(0xFFFFD166);
      case 'grid':
        return const Color(0xFF9B59B6);
      case 'smart':
        return const Color(0xFF50C878);
      case 'poster':
        return const Color(0xFFE87040);
      default:
        return const Color(0xFF4A90E2);
    }
  }
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: controller.onBatchDeleteTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE74C3C),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.w),
            ),
            elevation: 0,
          ),
          child: Text(
            'Delete Selected',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
