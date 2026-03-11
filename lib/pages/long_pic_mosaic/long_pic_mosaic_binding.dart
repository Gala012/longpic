import 'package:get/get.dart';
import 'long_pic_mosaic_logic.dart';
class LongPicMosaicBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LongPicMosaicLogic());
  }
}
