import 'dart:async';

import 'package:flutter/services.dart';

class Flutterjsbridgeplugin {
  static const MethodChannel _channel =
  const MethodChannel('flutterjsbridgeplugin');

  Flutterjsbridgeplugin() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> get scrpit async {
    final String initScript = await _channel.invokeMethod("getScript");
    return "javascript:$initScript";
  }

  Future<bool> isMainThread() async {
    return await _channel.invokeMethod("isMainThread");
  }

  Future<String> handlerReturnData(String url) async {
    return await _channel.invokeMethod("handlerReturnData", url);
  }

  Future<bool> _onMethodCall(MethodCall call) async {}
}
