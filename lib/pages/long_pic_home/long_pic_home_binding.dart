import 'package:get/get.dart';
import 'long_pic_home_logic.dart';
class LongPicHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LongPicHomeLogic());
  }
}
