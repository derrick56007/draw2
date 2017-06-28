part of server;

class ServerWebSocket extends DrawWebSocket {
  WebSocket _webSocket;
  HttpRequest _req;

  Future<dynamic> done;

  ServerWebSocket._internal(HttpRequest req) {
    _req = req;
  }

  factory ServerWebSocket.ugradeRequest(HttpRequest req) =>
      new ServerWebSocket._internal(req);

  @override
  start() async {
    _webSocket = await WebSocketTransformer.upgrade(_req)
      ..listen(onMessageToDispatch);

    done = _webSocket.done;
  }

  @override
  send(MessageType type, [var val]) {
    if (val == null) {
      _webSocket.add(type.index.toString());
    } else {
      _webSocket.add(JSON.encode([type.index, val]));
    }
  }
}
