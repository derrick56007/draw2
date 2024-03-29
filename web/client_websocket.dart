import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'common/draw_websocket.dart';
import 'common/message_type.dart';

class ClientWebSocket extends DrawWebSocket {
  WebSocket _webSocket;

  bool _connected = false;

  bool isConnected() => _connected;

  Stream<Event> onOpen, onClose, onError;

  ClientWebSocket();

  @override
  Future start([int retrySeconds = 2]) {
    final completer = Completer();

    var reconnectScheduled = false;

    final host = window.location.host;
    print('connecting to $host');
    _webSocket = WebSocket('wss://$host/');

    void _scheduleReconnect() {
      if (!reconnectScheduled) {
        Timer(Duration(seconds: retrySeconds),
            () async => await start(retrySeconds * 2));
      }
      reconnectScheduled = true;
    }

    _webSocket
      ..onOpen.listen((Event e) {
        print('connected');
        _connected = true;

        completer.complete();
      })
      ..onMessage.listen((MessageEvent e) {
        onMessageToDispatch(e.data);
      })
      ..onClose.listen((Event e) {
        print('disconnected');
        _connected = false;
        _scheduleReconnect();
      })
      ..onError.listen((Event e) {
        print('error ${e.type}');
        _connected = false;
        _scheduleReconnect();
      });

    onOpen = _webSocket.onOpen;
    onClose = _webSocket.onClose;
    onError = _webSocket.onError;

    return completer.future;
  }

  @override
  void send(MessageType type, [var val]) {
    if (val == null) {
      _webSocket.send(type.index.toString());
    } else {
      _webSocket.send(jsonEncode([type.index, val]));
    }
  }
}
