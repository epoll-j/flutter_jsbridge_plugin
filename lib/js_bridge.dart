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
  static final String _protocolScheme = "jsbridge://";
  final String _fetchData = "${_protocolScheme}return/fetch";
  final String _returnData = "${_protocolScheme}return/sendMsg/";
  String _dartToJs =
      "javascript:WebViewJavascriptBridge._handleMessageFromNative('%s');";

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

  bool handlerUrl(String url) {
    return _handlerReturnData(url);
  }

  bool _handlerReturnData(String url) {
    if (url.startsWith(_protocolScheme)) {
      if (url == _fetchData) {
        _fetchQueue();
      } else {
        List list = JsMsg.fromList(convert
            .jsonDecode(Uri.decodeComponent(url).replaceAll(_returnData, "")));
        print(list);
        for (JsMsg msg in list) {
          print(msg);
          if (msg.responseId != null) {

          } else {
            CallBackFunction function;
            if (msg.callbackId != null) {
              if (msg.callbackId != null) {
                function = (dynamic data) {
                  JsMsg callbackMsg = JsMsg();
                  callbackMsg.responseId = msg.callbackId;
                  callbackMsg.responseData = convert.jsonEncode(data);
                  // 发送
                  _loadJs(sprintf(_dartToJs, [_replaceJson(callbackMsg.toJson())]));
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
        }
      }
      return false;
    }
    return true;
  }

  void _fetchQueue() {
    _loadJs("WebViewJavascriptBridge._fetchQueue()");
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
    _loadJs(sprintf(_dartToJs, [_replaceJson(request.toJson())]));
  }

  void registerHandler(String handlerName,
      {dynamic data, BridgeHandler onCallBack}) {
    if (onCallBack != null) {
      _handlers[handlerName] = onCallBack;
    }
  }

  String _generateId() {
    return "flutter_cb_${_uniqueId++}";
  }

  String _replaceJson(String json) {
    json = json.replaceAll("\\", "\\\\");
    return json;
  }

  void _loadJs(String script) {
    _webViewController.evaluateJavascript(script);
  }
}
