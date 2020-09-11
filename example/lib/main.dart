import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_jsbridge_plugin/flutterjsbridgeplugin.dart';
import 'package:flutter_jsbridge_plugin/js_bridge.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  final JsBridge _jsBridge = JsBridge();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Flutterjsbridgeplugin.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: WebView(
            initialUrl: "https://www.baidu.com?timeStamp=${new DateTime.now().millisecondsSinceEpoch}",
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) async {
              _jsBridge.loadJs(webViewController);
              _controller.complete(webViewController);
              _jsBridge.registerHandler("getToken", onCallBack: (data, func) {
                // return token to js
                func({"token": "token"});
              });
              _jsBridge.registerHandler("IAPpayment", onCallBack: (data, func) {
                print("js call flutter iap");
              });
              _jsBridge.registerHandler("back", onCallBack: (data, func) {
                print("js call flutter back");
              });

            },
            navigationDelegate: (NavigationRequest request) {
              if (_jsBridge.handlerUrl(request.url)) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
            onPageStarted: (url) {
              _jsBridge.init();
            },
          )),
    );
  }
}
