import 'dart:io';

import 'package:flutterjsbridgeplugin/init_script.dart';
import 'package:flutterjsbridgeplugin/js_obj.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert' as convert;
import 'package:sprintf/sprintf.dart';

typedef CallBackFunction = void Function(dynamic data);
typedef BridgeHandler = void Function(dynamic data, CallBackFunction function);

class JsBridge {

  WebViewController _webViewController;
  Map<String, CallBackFunction> _callbacks = Map();
  Map<String, BridgeHandler> _handlers = Map();
  int _uniqueId = 0;
  String _returnData = "jsbridge://return/sendMsg/";
  String _dartToJs = "javascript:WebViewJavascriptBridge._handleMessageFromNative('%s');";

  void loadJs(WebViewController controller) {
    _webViewController = controller;
    init();
  }

  void init() {
    if (_webViewController == null) {
      throw "WebViewController must not null";
    }
    if (Platform.isIOS) {
      _loadJs(init_script_ios);
    } else {
      _loadJs(init_script_android);
    }
//    test();
  }

  void handlerUrl(String url) {
    print("handler: $url");
    _handlerReturnData(url);
  }

  void _handlerReturnData(String url) {
    if (url.startsWith(_returnData)) {
      JsMsg msg = JsMsg.formJson(convert
          .jsonDecode(Uri.decodeComponent(url).replaceAll(_returnData, "")));
      if (msg.responseId != null) {} else {
        CallBackFunction function;
        if (msg.callbackId != null) {
          if (msg.callbackId != null) {
            function = (dynamic data) {

              JsMsg callbackMsg = JsMsg();
              callbackMsg.responseId = msg.callbackId;
              callbackMsg.responseData = convert.jsonEncode(data);
              // 发送
              _loadJs(
                  sprintf(_dartToJs, [_replaceJson(callbackMsg.toJson())]));
            };
          }
        } else {
          function = (dynamic data) {};
        }
        BridgeHandler handler;
        if (msg.handlerName != null) {
          handler = _handlers[msg.handlerName];
        }
        if (handler != null) {
          handler.call(msg.data, function);
        }
      }
    } else if (url.contains("queue")) {
      test();
    }
  }

  void callHandler(String handlerName,
      {dynamic data, CallBackFunction onCallBack}) {
    JsRequest request = JsRequest();
    request.handlerName = handlerName;
    if (data != null) {
      if (data is String) {
        request.data = data;
      } else {
        request.data = convert.jsonEncode(data);
      }
    }
    request.callbackId = _generateId();
    if (onCallBack != null) {
      _callbacks[request.callbackId] = onCallBack;
    }
    _loadJs(
        sprintf(_dartToJs, [_replaceJson(request.toJson())]));
  }

  void registerHandler(String handlerName,
      {dynamic data, BridgeHandler onCallBack}) {
    if (onCallBack != null) {
      _handlers[handlerName] = onCallBack;
    }
  }

  void test() {
    _loadJs("WebViewJavascriptBridge._fetchQueue()");
  }

  String _generateId() {
    return "flutter_cb_${_uniqueId++}";
  }

  String _replaceJson(String json) {
    json = json.replaceAll("\\", "\\\\");
    return json;
  }

  void _loadJs(String script) async {
//    _webViewController.evaluateJavascript(script);
//    print(script);
    print(await _webViewController.evaluateJavascript(script));
  }
}
