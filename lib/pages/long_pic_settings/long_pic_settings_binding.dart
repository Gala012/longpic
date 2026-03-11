import 'package:get/get.dart';
import 'long_pic_settings_logic.dart';
class LongPicSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LongPicSettingsLogic());
  }
}
