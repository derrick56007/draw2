import 'dart:async';
import 'dart:convert';
import 'message_type.dart';

abstract class DrawWebSocket {
  static const defaultMessageLength = 2;
  static const messageTypeIndex = 0;
  static const valueIndex = 1;

  final messageDisatchers = new List<Function>(MessageType.values.length);

  Future start();

  void on(MessageType type, Function function) {
    if (messageDisatchers[type.index] != null) {
      print("warning: overriding message dispatcher ${type.index}");
    }

    messageDisatchers[type.index] = function;
  }

  void send(MessageType type, [var val]);

  void onMessageToDispatch(var data) {
    final msg = JSON.decode(data);

    // checks if is [request, data]
    if (msg is List && msg.length == defaultMessageLength) {
      messageDisatchers[msg[messageTypeIndex]](msg[valueIndex]);
    } else if (msg is int){
      messageDisatchers[msg]();
    } else {
      print('No such dispatch exists!: $msg');
    }
  }
}
