import 'package:get/get.dart';
import 'long_pic_crop_logic.dart';
class LongPicCropBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LongPicCropLogic());
  }
}
