import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../main.dart';
import '../../services/long_pic_guide_service.dart';
import 'long_pic_home_logic.dart';
class LongPicHomeView extends GetView<LongPicHomeLogic> {
  const LongPicHomeView({super.key});
  static const List<Map<String, dynamic>> _modes = [
    {
      'title': 'Stitch Long\nPhoto',
      'subtitle': 'Vertical long photo',
      'icon': Icons.view_agenda_rounded,
      'color': Color(0xFF4A90E2),
      'lightColor': Color(0xFF6AB0F3),
      'route': '/long_select_photo',
      'mode': 'vertical',
    },
    {
      'title': 'Smart\nStitch',
      'subtitle': 'Deduplicate & stitch',
      'icon': Icons.auto_awesome_rounded,
      'color': Color(0xFF50C878),
      'lightColor': Color(0xFF7FE0A0),
      'route': '/long_select_photo',
      'mode': 'smart',
    },
    {
      'title': 'Horizontal\nStitch',
      'subtitle': 'Horizontal photo',
      'icon': Icons.view_week_rounded,
      'color': Color(0xFFFFD166),
      'lightColor': Color(0xFFFFE599),
      'route': '/long_select_photo',
      'mode': 'horizontal',
    },
    {
      'title': 'Poster\nScreenshot',
      'subtitle': 'Beautiful templates',
      'icon': Icons.photo_filter_rounded,
      'color': Color(0xFFE87040),
      'lightColor': Color(0xFFFF9B73),
      'route': '/long_poster_templates',
      'mode': '',
    },
    {
      'title': 'Grid Collage',
      'subtitle': 'Multiple grid styles',
      'icon': Icons.grid_view_rounded,
      'color': Color(0xFF9B59B6),
      'lightColor': Color(0xFFB97FCE),
      'route': '/long_select_photo',
      'mode': 'grid',
    },
  ];
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GuideService.to.showHomeGuide(context);
    });
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [
                primaryColor.withValues(alpha: 0.06),
                bgColor,
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: Column(
            children: [
              _buildCustomHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                  child: _buildModeGrid(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12.h,
        left: 20.w,
        right: 20.w,
        bottom: 24.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.w)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6AB0F3), primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15.w),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.photo_library_rounded,
                        color: Colors.white, size: 26.w),
                  ),
                  SizedBox(width: 14.w),
                  Text(
                    'Long Pic',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildHeaderIcon(Icons.history_rounded,
                      () => Get.toNamed('/long_history')),
                  SizedBox(width: 10.w),
                  _buildHeaderIcon(Icons.settings_rounded,
                      () => Get.toNamed('/long_settings')),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            'Create Your\nMasterpiece',
            style: TextStyle(
              fontSize: 34.sp,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              height: 1.15,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Select a mode to start stitching your photos',
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child:
            Icon(icon, color: textPrimary.withValues(alpha: 0.7), size: 21.w),
      ),
    );
  }
  Widget _buildModeGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildModeCard(_modes[0], isLarge: true)),
            SizedBox(width: 14.w),
            Expanded(child: _buildModeCard(_modes[1], isLarge: true)),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(child: _buildModeCard(_modes[2])),
            SizedBox(width: 14.w),
            Expanded(child: _buildModeCard(_modes[3])),
          ],
        ),
        SizedBox(height: 14.h),
        _buildModeCard(_modes[4], isWide: true),
        SizedBox(height: 30.h),
      ],
    );
  }
  Widget _buildModeCard(Map<String, dynamic> mode,
      {bool isLarge = false, bool isWide = false}) {
    final Color color = mode['color'] as Color;
    final Color lightColor = mode['lightColor'] as Color;
    return GestureDetector(
      onTap: () {
        if (mode['mode'] == '') {
          Get.toNamed(mode['route'] as String);
        } else {
          Get.toNamed(
            mode['route'] as String,
            parameters: {'mode': mode['mode'] as String},
          );
        }
      },
      child: Container(
        height: isLarge ? 170.h : (isWide ? 110.h : 155.h),
        padding: EdgeInsets.all(isWide ? 20.w : 18.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(28.w),
          border: Border.all(
            color: color.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isWide
            ? Row(
                children: [
                  _buildIconContainer(
                      mode['icon'] as IconData, color, lightColor,
                      isLarge: false),
                  SizedBox(width: 18.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mode['title'] as String,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          mode['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: color, size: 18.w),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildIconContainer(
                      mode['icon'] as IconData, color, lightColor,
                      isLarge: isLarge),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mode['title'] as String,
                          style: TextStyle(
                            fontSize: isLarge ? 18.sp : 16.sp,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          mode['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  Widget _buildIconContainer(IconData icon, Color color, Color lightColor,
      {bool isLarge = false}) {
    final double size = isLarge ? 64.w : 56.w;
    final double iconSize = isLarge ? 32.w : 28.w;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightColor, color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.w),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
