import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../web/common/draw_websocket.dart';

class ServerWebSocket extends DrawWebSocket {
  WebSocket _websocket;
  HttpRequest _req;

  Future<dynamic> done;

  ServerWebSocket._internal(HttpRequest req) {
    _req = req;
  }

  factory ServerWebSocket.ugradeRequest(HttpRequest req) =>
      new ServerWebSocket._internal(req);

  start() async {
    _websocket = await WebSocketTransformer.upgrade(_req);

    _websocket
      ..listen((dynamic data) {
        onMessageToDispatch(data);
      });

    done = _websocket.done;
  }

  send(String request, dynamic val) {
    _websocket.add(JSON.encode([request, val]));
  }
}
