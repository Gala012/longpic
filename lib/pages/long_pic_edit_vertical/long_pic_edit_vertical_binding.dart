import 'package:get/get.dart';
import 'long_pic_edit_vertical_logic.dart';
class LongPicEditVerticalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LongPicEditVerticalLogic());
  }
}
