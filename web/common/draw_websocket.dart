import 'dart:async';
import 'dart:convert';
import 'message_type.dart';

abstract class DrawWebSocket {
  static const defaultMessageLength = 2;
  static const messageTypeIndex = 0;
  static const valueIndex = 1;

  final messageDispatchers = new List<Function>(MessageType.values.length);

  Future start();

  void on(MessageType type, Function function) {
    if (messageDispatchers[type.index] != null) {
      print("warning: overriding message dispatcher ${type.index}");
    }

    messageDispatchers[type.index] = function;
  }

  void send(MessageType type, [var val]);

  void onMessageToDispatch(var data) {
    final msg = jsonDecode(data);

    // checks if is [request, data]
    if (msg is List && msg.length == defaultMessageLength) {
      messageDispatchers[msg[messageTypeIndex]](msg[valueIndex]);
    } else if (msg is int){
      messageDispatchers[msg]();
    } else {
      print('No such dispatch exists!: $msg');
    }
  }
}
