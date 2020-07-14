import 'dart:convert' as convert;

class JsRequest {
  String callbackId;
  String data;
  String handlerName;

  String toJson() {
    return convert.jsonEncode({
      "callbackId": callbackId == null ? "" : callbackId,
      "data": data == null ? "" : data,
      "handlerName": handlerName == null ? "" : handlerName
    });
  }
}

class JsMsg {
  String callbackId; //callbackId
  String responseId; //responseId
  String responseData; //responseData
  String data; //data of message
  String handlerName;

  JsMsg();

  static List<JsMsg> fromList(List list) {
    List<JsMsg> msgList = [];
    for (Map json in list) {
      JsMsg msg = JsMsg();
      msg.callbackId = json["callbackId"];
      msg.responseId = json["responseId"];
      msg.responseData = convert.jsonEncode(json["responseData"]);
      msg.data = convert.jsonEncode(json["data"]);
      msg.handlerName = json["handlerName"];
      msgList.add(msg);
    }
    return msgList;
  }

  factory JsMsg.formJson(Map json) {
    JsMsg msg = JsMsg();
    msg.callbackId = json["callbackId"];
    msg.responseId = json["responseId"];
    msg.responseData = convert.jsonEncode(json["responseData"]);
    msg.data = convert.jsonEncode(json["data"]);
    msg.handlerName = json["handlerName"];
    return msg;
  }

  String toJson() {
    return convert.jsonEncode({
      "callbackId": callbackId == null ? "" : callbackId,
      "responseId": responseId == null ? "" : responseId,
      "responseData": responseData == null ? "" : responseData,
      "data": data == null ? "" : data,
      "handlerName": handlerName == null ? "" : handlerName
    });
  }
}
