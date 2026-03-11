import 'package:get/get.dart';
import 'long_pic_select_photo_logic.dart';
class LongPicSelectPhotoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LongPicSelectPhotoLogic());
  }
}
