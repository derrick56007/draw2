part of server;

class ServerWebSocket extends DrawWebSocket {
  final HttpRequest _req;

  WebSocket _webSocket;

  Future done;

  ServerWebSocket.ugradeRequest(this._req);

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
