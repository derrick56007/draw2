import 'dart:async';
import 'dart:convert';

abstract class DrawWebSocket {
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
      if (msg.length == 2 && messageDisatchers.containsKey(msg[0])) {
        messageDisatchers[msg[0]](msg[1]);
      } else {
        print('No such dispatch exists!: $msg');
      }
    } else {
      print('No such dispatch exists!: $msg');
    }
  }
}
