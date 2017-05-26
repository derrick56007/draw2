import 'dart:async';
import 'dart:convert';

abstract class DrawWebSocket {
  static const defaultMessageLength = 2;
  static const requestIndex = 0;
  static const valueIndex = 1;

  Map<String, Function> messageDisatchers = {};

  Future start();

  void on(String request, dynamic action(var data)) {
    messageDisatchers[request] = action;
  }

  void send(String request, var val);

  void onMessageToDispatch(var data) {
    var msg = JSON.decode(data);

    // checks if is [request, data]
    if (msg is List) {
      // check if dispatch is valid
      if (msg.length == defaultMessageLength &&
          messageDisatchers.containsKey(msg[requestIndex])) {
        messageDisatchers[msg[requestIndex]](msg[valueIndex]);
      } else {
        print('No such dispatch exists!: $msg');
      }
    } else {
      print('No such dispatch exists!: $msg');
    }
  }
}
