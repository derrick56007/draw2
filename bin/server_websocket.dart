part of server;

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
      ..listen((var data) {
        onMessageToDispatch(data);
      });

    done = _websocket.done;
  }

  send(String request, var val) {
    _websocket.add(JSON.encode([request, val]));
  }
}
