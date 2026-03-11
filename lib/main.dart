import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'db_long_pic/data.dart';
import '../pages/long_pic_home/long_pic_home_binding.dart';
import '../pages/long_pic_home/long_pic_home_view.dart';
import '../pages/long_pic_select_photo/long_pic_select_photo_binding.dart';
import '../pages/long_pic_select_photo/long_pic_select_photo_view.dart';
import '../pages/long_pic_edit_vertical/long_pic_edit_vertical_binding.dart';
import '../pages/long_pic_edit_vertical/long_pic_edit_vertical_view.dart';
import '../pages/long_pic_crop/long_pic_crop_binding.dart';
import '../pages/long_pic_crop/long_pic_crop_view.dart';
import '../pages/long_pic_mosaic/long_pic_mosaic_binding.dart';
import '../pages/long_pic_mosaic/long_pic_mosaic_view.dart';
import '../pages/long_pic_edit_horizontal/long_pic_edit_horizontal_binding.dart';
import '../pages/long_pic_edit_horizontal/long_pic_edit_horizontal_view.dart';
import '../pages/long_pic_edit_grid/long_pic_edit_grid_binding.dart';
import '../pages/long_pic_edit_grid/long_pic_edit_grid_view.dart';
import '../pages/long_pic_history/long_pic_history_binding.dart';
import '../pages/long_pic_history/long_pic_history_view.dart';
import '../pages/long_pic_settings/long_pic_settings_binding.dart';
import '../pages/long_pic_settings/long_pic_settings_view.dart';
import '../pages/long_pic_poster_templates/long_pic_poster_templates_binding.dart';
import '../pages/long_pic_poster_templates/long_pic_poster_templates_view.dart';
import '../pages/long_pic_edit_poster/long_pic_edit_poster_binding.dart';
import '../pages/long_pic_edit_poster/long_pic_edit_poster_view.dart';
import 'services/long_pic_user_preferences.dart';
import 'services/long_pic_guide_service.dart';
const Color primaryColor = Color(0xFF4A90E2);
const Color accentGreen = Color(0xFF50C878);
const Color accentYellow = Color(0xFFFFD166);
const Color bgColor = Color(0xFFF8FAFC);
const Color textPrimary = Color(0xFF1E293B);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Get.putAsync(() => DbLongPic().init());
  await Get.putAsync(() => UserPreferences().init());
  Get.put(GuideService());
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          getPages: Quick,
          initialRoute: '/long_home',
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: primaryColor,
            scaffoldBackgroundColor: bgColor,
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              surface: Color(0xFFFFFFFF),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              backgroundColor: Colors.white,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17.sp,
                color: textPrimary,
              ),
              toolbarHeight: 48.h,
              iconTheme: const IconThemeData(size: 22, color: textPrimary),
            ),
            dividerTheme: DividerThemeData(
              thickness: 1,
              color: Colors.grey[200],
            ),
          ),
        );
      },
    );
  }
}
List<GetPage<dynamic>> Quick = [
  GetPage(
    name: '/long_home',
    page: () => const LongPicHomeView(),
    binding: LongPicHomeBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/long_select_photo',
    page: () => const LongPicSelectPhotoView(),
    binding: LongPicSelectPhotoBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/long_edit_vertical',
    page: () => const LongPicEditVerticalView(),
    binding: LongPicEditVerticalBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/long_crop',
    page: () => const LongPicCropView(),
    binding: LongPicCropBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/long_mosaic',
    page: () => const LongPicMosaicView(),
    binding: LongPicMosaicBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/long_edit_horizontal',
    page: () => const LongPicEditHorizontalView(),
    binding: LongPicEditHorizontalBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/long_edit_grid',
    page: () => const LongPicEditGridView(),
    binding: LongPicEditGridBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/long_history',
    page: () => const LongPicHistoryView(),
    binding: LongPicHistoryBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/long_settings',
    page: () => const LongPicSettingsView(),
    binding: LongPicSettingsBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/long_poster_templates',
    page: () => const LongPicPosterTemplatesView(),
    binding: LongPicPosterTemplatesBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/long_edit_poster',
    page: () => const LongPicEditPosterView(),
    binding: LongPicEditPosterBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
];