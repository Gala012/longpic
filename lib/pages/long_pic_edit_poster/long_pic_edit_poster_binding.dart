import 'package:get/get.dart';
import 'long_pic_edit_poster_logic.dart';
class LongPicEditPosterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LongPicEditPosterLogic());
  }
}
