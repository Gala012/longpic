import 'package:get/get.dart';
import 'long_pic_edit_horizontal_logic.dart';
class LongPicEditHorizontalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LongPicEditHorizontalLogic());
  }
}
