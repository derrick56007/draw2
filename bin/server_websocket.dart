part of server;

class ServerWebSocket extends DrawWebSocket {
  WebSocket _webSocket;
  HttpRequest _req;

  Future<dynamic> done;

  ServerWebSocket._internal(HttpRequest req) {
    _req = req;
  }

  factory ServerWebSocket.ugradeRequest(HttpRequest req) => new ServerWebSocket._internal(req);

  start() async {
    _webSocket = await WebSocketTransformer.upgrade(_req);

    _webSocket.listen((var data) {
      onMessageToDispatch(data);
    });

    done = _webSocket.done;
  }

  send(String request, [var val = '']) {
    _webSocket.add(JSON.encode([request, val]));
  }
}
