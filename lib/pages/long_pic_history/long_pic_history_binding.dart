import 'package:get/get.dart';
import 'long_pic_history_logic.dart';
class LongPicHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LongPicHistoryLogic());
  }
}
