import 'dart:async';
import 'dart:convert';

abstract class DrawWebSocket {
  Map<String, Function> messageDisatchers = {};

  Future start();

  void on(String request, Function action(dynamic data)) {
    messageDisatchers[request] = action;
  }

  void send(String request, dynamic val);

  void onMessageToDispatch(dynamic data) {
    var msg = JSON.decode(data);

    // checks if is [request, data]
    if (msg is List &&
        msg.length == 2 &&
        messageDisatchers.containsKey(msg[0])) {
      messageDisatchers[msg[0]](msg[1]);
    } else {
      // raw string
    }
  }
}
