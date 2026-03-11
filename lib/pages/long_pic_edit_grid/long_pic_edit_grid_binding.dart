import 'package:get/get.dart';
import 'long_pic_edit_grid_logic.dart';
class LongPicEditGridBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LongPicEditGridLogic());
  }
}
