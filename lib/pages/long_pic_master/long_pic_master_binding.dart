import 'package:get/get.dart';

import 'long_pic_master_logic.dart';

class LongPicMasterBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      LongPicMasterLogic(),
      permanent: true,
    );
  }
}
