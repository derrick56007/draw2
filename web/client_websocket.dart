import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'common/draw_websocket.dart';

class ClientWebSocket extends DrawWebSocket {
  WebSocket _webSocket;

  bool _connected = false;

  isConnected() => _connected;

  Stream<Event> onOpen, onClose, onError;

  ClientWebSocket() {}

  start([int retrySeconds = 2]) async {
    var reconnectScheduled = false;

    var host = window.location.host;
    print('connecting to $host');
    _webSocket = new WebSocket('ws://$host/');

    _scheduleReconnect() {
      if (!reconnectScheduled) {
        new Timer(new Duration(seconds: retrySeconds),
            () async => await start(retrySeconds * 2));
      }
      reconnectScheduled = true;
    }

    _webSocket
      ..onOpen.listen((Event e) {
        print('connected');
        _connected = true;
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
  }

  send(String request, dynamic val) {
    _webSocket.send(JSON.encode([request, val]));
  }
}
