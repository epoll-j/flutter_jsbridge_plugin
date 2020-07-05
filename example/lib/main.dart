import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutterjsbridgeplugin/flutterjsbridgeplugin.dart';
import 'package:flutterjsbridgeplugin/js_bridge.dart';
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
            initialUrl: "http://bridge.bobolaile.com/openVip?timeStamp=${new DateTime.now().millisecondsSinceEpoch}",
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) async {
              _jsBridge.loadJs(webViewController);
              _controller.complete(webViewController);
              _jsBridge.registerHandler("getToken", onCallBack: (data, func) {
                func({"token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhZ2VudCI6IlZJUCIsInJvbGUiOltdLCJwYXNzIjoidlorM2dkSTV5QjFVU1hsZUo3MlZURUVWbGFTQVVvS0tXbDYyUGVORDlrWXljZmx6ajY2SFowbGRMMTFPQVR5dSIsIm1vZGVsIjoiaU9TIiwicmlkIjoicnxERUJCNjNCRkIwMEY0MkVBQTQzNzdERjRERDREMTUyMyIsInVzZXJJZCI6Ijk4ZWVjYTNhZDQ1NDRlNmE4M2M1MDZjMWRjZjMyM2E2IiwiYWdlbnRMZXZlbCI6MX0.UCFZKSFZ8UoIiD9dAb10v6XX0gCZOP7VoUwKMQXTX10", "identity": 1, "phoneType": "iOS"});
              });
              _jsBridge.registerHandler("IAPpayment", onCallBack: (data, func) {
                print("iap");
                _jsBridge.callHandler("getPayState", data: "0");
              });
              _jsBridge.registerHandler("back", onCallBack: (data, func) {
                print("back");
              });

            },
            navigationDelegate: (NavigationRequest request) {
              _jsBridge.handlerUrl(request.url);
              if (request.url.startsWith('https://www.youtube.com/')) {
                print('blocking navigation to $request}');
                return NavigationDecision.prevent;
              }
              print('allowing navigation to $request');
              return NavigationDecision.navigate;
            },
            onPageStarted: (url) {
              _jsBridge.init();
            },
          )),
    );
  }
}
