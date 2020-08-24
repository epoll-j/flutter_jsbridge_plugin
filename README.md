# Add JsBridge Plugin to the WebView

[A Flutter plugin that provides a JsBridge on WebView widget.](https://pub.dev/packages/bridge_webview_flutter)

This plugin must introduce  [webview_flutter](https://pub.dev/packages/webview_flutter)


## Usage
Add `flutter_jsbridge_plugin` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

```
BridgeWebView(
    initialUrl: 'https://flutter.dev',
    javascriptMode: JavascriptMode.unrestricted,
    onWebViewCreated: (WebViewController webViewController) {
        _controller.complete(webViewController);
        webViewController.registerHandler("methodName", response: "r1", onCallBack: (callBackData) {
            print(callBackData.name); // handler name
            print(callBackData.data); // callback data ({'param': '1'})
        });
        webViewController.callHandler("methodName", data: "sendData", onCallBack: (callBackData) {
            print(callBackData.name); // handler name
            print(callBackData.data); // callback data (r2)
        });
    },
    onPageStarted: (String url) {
        print('Page started loading: $url');
    },
    onPageFinished: (String url) {
        print('Page finished loading: $url');
    }
)
```

### Register a Flutter handler function so that js can call
```
...
final JsBridge _jsBridge = JsBridge();
...
WebView(
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
))

```
#### js can call this handler method "methodName" through:
```
WebViewJavascriptBridge.callHandler(
    'methodName'
    , {'param': '1'}
    , function(data) {
        // data is r1
    }
);
```

### Register a JavaScript handler function so that flutter can call
```
WebViewJavascriptBridge.registerHandler("methodName", function(data, responseCallback) {
    // data is 'sendData'
    responseCallback('r2');
});
```
#### flutter can call this js handler function "methodName" through:
```
onWebViewCreated: (WebViewController webViewController) {
    _controller.complete(webViewController);
    webViewController.callHandler("methodName", data: "sendData", onCallBack: (callBackData) {
        print(callBackData.name); // handler name
        print(callBackData.data); // callback data (r2)
    });
}
```
