import 'package:get/get.dart';
import 'long_pic_poster_templates_logic.dart';
class LongPicPosterTemplatesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LongPicPosterTemplatesLogic());
  }
}
