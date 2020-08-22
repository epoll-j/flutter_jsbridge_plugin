// ignore: non_constant_identifier_names
String init_script_android = '''
(function() {
    if (window.WebViewJavascriptBridge) {
        return;
    }
  
    var lastCallTime = 0;
    var stoId = null;
    var FETCH_QUEUE = 50;
  
    var messagingIframe;
    var sendMessageQueue = [];
    var receiveMessageQueue = [];
    var messageHandlers = {};
    var timer = null;
    
    var CUSTOM_PROTOCOL_SCHEME = 'jsbridge';
    var QUEUE_HAS_MESSAGE = '__QUEUE_MESSAGE__/';

    var responseCallbacks = {};
    var uniqueId = 1;

    var base64encodechars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function base64encode(str) {
        if (str === undefined) {
            return str;
        }

        var out, i, len;
        var c1, c2, c3;
        len = str.length;
        i = 0;
        out = "";
        while (i < len) {
            c1 = str.charCodeAt(i++) & 0xff;
            if (i == len) {
                out += base64encodechars.charAt(c1 >> 2);
                out += base64encodechars.charAt((c1 & 0x3) << 4);
                out += "==";
                break;
            }
            c2 = str.charCodeAt(i++);
            if (i == len) {
                out += base64encodechars.charAt(c1 >> 2);
                out += base64encodechars.charAt(((c1 & 0x3) << 4) | ((c2 & 0xf0) >> 4));
                out += base64encodechars.charAt((c2 & 0xf) << 2);
                out += "=";
                break;
            }
            c3 = str.charCodeAt(i++);
            out += base64encodechars.charAt(c1 >> 2);
            out += base64encodechars.charAt(((c1 & 0x3) << 4) | ((c2 & 0xf0) >> 4));
            out += base64encodechars.charAt(((c2 & 0xf) << 2) | ((c3 & 0xc0) >> 6));
            out += base64encodechars.charAt(c3 & 0x3f);
        }
        return out;
    }


    function _createQueueReadyIframe(doc) {
//        messagingIframe = doc.createElement('iframe');
//        messagingIframe.style.display = 'none';
//        doc.documentElement.appendChild(messagingIframe);
    }

    function isAndroid() {
        var ua = navigator.userAgent.toLowerCase();
        var isA = ua.indexOf("android") > -1;
        if (isA) {
            return true;
        }
        return false;
    }

    function isIphone() {
        var ua = navigator.userAgent.toLowerCase();
        var isIph = ua.indexOf("iphone") > -1;
        if (isIph) {
            return true;
        }
        return false;
    }

    //set default messageHandler
    function init(messageHandler) {
        if (WebViewJavascriptBridge._messageHandler) {
            throw new Error('WebViewJavascriptBridge.init called twice');
        }
        WebViewJavascriptBridge._messageHandler = messageHandler;
        var receivedMessages = receiveMessageQueue;
        receiveMessageQueue = null;
        for (var i = 0; i < receivedMessages.length; i++) {
            _dispatchMessageFromNative(receivedMessages[i]);
        }
    }

    function send(data, responseCallback) {
        _doSend({
            data: data
        }, responseCallback);
    }

    function registerHandler(handlerName, handler) {
        messageHandlers[handlerName] = handler;
    }

    function callHandler(handlerName, data, responseCallback) {
        console.log(handlerName);
        _doSend({
            handlerName: handlerName,
            data: data
        }, responseCallback);
    }

    //sendMessage add message, 触发native处理 sendMessage
    function _doSend(message, responseCallback) {
        console.log('send');        
        if (responseCallback) {
            var callbackId = 'cb_' + (uniqueId++) + '_' + new Date().getTime();
            responseCallbacks[callbackId] = responseCallback;
            message.callbackId = callbackId;
        }
        sendMessageQueue.push(message);
        if (!timer) {
          timer = setTimeout(function() {
            _getIframe().src = CUSTOM_PROTOCOL_SCHEME + '://return/sendMsg/' + encodeURIComponent(JSON.stringify(sendMessageQueue));
            sendMessageQueue = [];
            timer = null;
          }, 30);  
        }
    }

    // 提供给native调用,该函数作用:获取sendMessageQueue返回给native,由于android不能直接获取返回的内容,所以使用url shouldOverrideUrlLoading 的方式返回内容
    function _fetchQueue() {
      if (sendMessageQueue.length === 0) {
        return;
      }
 
      if (new Date().getTime() - lastCallTime < FETCH_QUEUE) {
        if (!stoId) {
          stoId = setTimeout(_fetchQueue, FETCH_QUEUE);
        }
        return;
      }
 
      lastCallTime = new Date().getTime();
      stoId = null;
    
		  var messageQueueString = JSON.stringify(sendMessageQueue);
		  sendMessageQueue = [];
		  if (messageQueueString === '[]') {
		    return;
		  }
		  
		  _getIframe().src = CUSTOM_PROTOCOL_SCHEME + '://return/sendMsg/' + encodeURIComponent(messageQueueString);

//        var messageQueueString = JSON.stringify(sendMessageQueue);
//        sendMessageQueue = [];
//        //add by hq
//        if (isIphone()) {
//            return messageQueueString;
//            //android can't read directly the return data, so we can reload iframe src to communicate with java
//        } else if (isAndroid()) {
//            messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://return/sendMsg/' + encodeURIComponent(messageQueueString);
//        }
    }

    //提供给native使用,
    function _dispatchMessageFromNative(messageJSON) {
        setTimeout(function() {
            var message = JSON.parse(messageJSON);
            var responseCallback;
            //java call finished, now need to call js callback function
            if (message.responseId) {
                responseCallback = responseCallbacks[message.responseId];
                if (!responseCallback) {
                    return;
                }
                responseCallback(message.responseData);
                delete responseCallbacks[message.responseId];
            } else {
                //直接发送
                if (message.callbackId) {
                    var callbackResponseId = message.callbackId;
                    responseCallback = function(responseData) {
                        _doSend({
                            responseId: callbackResponseId,
                            responseData: responseData
                        });
                    };
                }
                var handler = WebViewJavascriptBridge._messageHandler;
                if (message.handlerName) {
                    handler = messageHandlers[message.handlerName];
                }
                //查找指定handler
                try {
                    handler(message.data, responseCallback);
                } catch (exception) {
                    if (typeof console != 'undefined') {
                        console.log("WebViewJavascriptBridge: WARNING: javascript handler threw.", message, exception);
                    }
                }
            }
        });
    }

    //提供给native调用,receiveMessageQueue 在会在页面加载完后赋值为null,所以
    function _handleMessageFromNative(messageJSON) {
//        if (receiveMessageQueue) {
//            receiveMessageQueue.push(messageJSON);
//        } else {
            _dispatchMessageFromNative(messageJSON);
//        }
    }
    
    function _getIframe() {
      if (typeof(messagingIframe) == 'undefined') {
        messagingIframe = document.createElement('iframe');
	      messagingIframe.style.display = 'none';
	      document.documentElement.appendChild(messagingIframe);
      }
      return messagingIframe;
    }
    
    var WebViewJavascriptBridge = window.WebViewJavascriptBridge = {
        init: init,
        send: send,
        registerHandler: registerHandler,
        callHandler: callHandler,
        _handleMessageFromNative: _handleMessageFromNative,
        _fetchQueue: _fetchQueue
    };

    var doc = document;
//    _createQueueReadyIframe(doc);
    var readyEvent = doc.createEvent('Events');
    readyEvent.initEvent('WebViewJavascriptBridgeReady');
    readyEvent.bridge = WebViewJavascriptBridge;
    doc.dispatchEvent(readyEvent);
})();''';

String init_script_ios = '''
(function() {
	if (window.WebViewJavascriptBridge) {
		return;
	}

	if (!window.onerror) {
		window.onerror = function(msg, url, line) {
			console.log("WebViewJavascriptBridge: ERROR:" + msg + "@" + url + ":" + line);
		}
	}
	var WebViewJavascriptBridge = window.WebViewJavascriptBridge = {
		registerHandler: registerHandler,
		callHandler: callHandler,
		disableJavscriptAlertBoxSafetyTimeout: disableJavscriptAlertBoxSafetyTimeout,
		_handleMessageFromNative: _handleMessageFromNative,
		_fetchQueue: _fetchQueue
	};

	var messagingIframe;
	var sendMessageQueue = [];
	var messageHandlers = {};
	
	var CUSTOM_PROTOCOL_SCHEME = 'jsbridge';
	
	var responseCallbacks = {};
	var uniqueId = 1;
	var dispatchMessagesWithTimeoutSafety = true;

	function registerHandler(handlerName, handler) {
		messageHandlers[handlerName] = handler;
	}
	
	function callHandler(handlerName, data, responseCallback) {
		if (arguments.length == 2 && typeof data == 'function') {
			responseCallback = data;
			data = null;
		}
		_doSend({ handlerName:handlerName, data:data }, responseCallback);
	}
	
	function disableJavscriptAlertBoxSafetyTimeout() {
		dispatchMessagesWithTimeoutSafety = false;
	}
	
	function _doSend(message, responseCallback) {
		if (responseCallback) {
			var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
			responseCallbacks[callbackId] = responseCallback;
			message['callbackId'] = callbackId;
		}
		sendMessageQueue.push(message);
		_getIframe().src = 'jsbridge://return/fetch'
	}

	function _dispatchMessageFromNative(messageJSON) {
		if (dispatchMessagesWithTimeoutSafety) {
			setTimeout(_doDispatchMessageFromNative, 0);
		} else {
			 _doDispatchMessageFromNative();
		}
		
		function _doDispatchMessageFromNative() {
			var message = JSON.parse(messageJSON);
			var messageHandler;
			var responseCallback;

			if (message.responseId) {
				responseCallback = responseCallbacks[message.responseId];
				if (!responseCallback) {
					return;
				}
				responseCallback(message.responseData);
				delete responseCallbacks[message.responseId];
			} else {
				if (message.callbackId) {
					var callbackResponseId = message.callbackId;
					responseCallback = function(responseData) {
						_doSend({ handlerName:message.handlerName, responseId:callbackResponseId, responseData:responseData });
					};
				}
				
				var handler = messageHandlers[message.handlerName];
				if (!handler) {
					console.log("WebViewJavascriptBridge: WARNING: no handler for message from ObjC:", message);
				} else {
					handler(message.data, responseCallback);
				}
			}
		}
	}
	
	function _fetchQueue() {
	  if (Array.isArray(sendMessageQueue) && sendMessageQueue.length === 0) {
	    return;
	  }
		var messageQueueString = JSON.stringify(sendMessageQueue);
		sendMessageQueue = [];
		if (messageQueueString === '[]') {
		  return;
		}
		_getIframe().src = CUSTOM_PROTOCOL_SCHEME + '://return/sendMsg/' + encodeURIComponent(messageQueueString);
	}
	
	function _handleMessageFromNative(messageJSON) {
    _dispatchMessageFromNative(messageJSON);
	}
  
  function _getIframe() {
    if (typeof(messagingIframe) == 'undefined') {
      messagingIframe = document.createElement('iframe');
	    messagingIframe.style.display = 'none';
	    messagingIframe.src = 'jsbridge://return/fetch'
	    document.documentElement.appendChild(messagingIframe);
    }
    return messagingIframe;
  }
  
	registerHandler("_disableJavascriptAlertBoxSafetyTimeout", disableJavscriptAlertBoxSafetyTimeout);
	setTimeout(_callWVJBCallbacks, 0);

	function _callWVJBCallbacks() {
		var callbacks = window.WVJBCallbacks;
		delete window.WVJBCallbacks;
		for (var i=0; i<callbacks.length; i++) {
			callbacks[i](window.WebViewJavascriptBridge);
		}
	}
})();''';