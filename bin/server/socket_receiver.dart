part of server;

class SocketReceiver {
  static final LoginManager _loginManager = LoginManager.shared;
  final ServerWebSocket _socket;

  SocketReceiver._internal(this._socket);

  factory SocketReceiver.handle(ServerWebSocket socket) {
    final sr = SocketReceiver._internal(socket);

    sr._init();

    return sr;
  }

  Future _init() async {
    await _socket.start();

    _onStart();

    await _socket.done;

    _onClose();
  }

  void _onStart() {
    _socket
      ..on(MessageType.login, _login)
      ..on(MessageType.createLobby, _createLobby)
      ..on(MessageType.enterLobby, _enterLobby)
      ..on(MessageType.enterLobbyWithPassword, _enterLobbyWithPassword)
      ..on(MessageType.exitLobby, _exitLobby)
      ..on(MessageType.drawNext, _drawNext)
      ..on(MessageType.guess, _guess)
      ..on(MessageType.drawPoint, _drawPoint)
      ..on(MessageType.drawLine, _drawLine)
      ..on(MessageType.clearDrawing, _clearDrawing)
      ..on(MessageType.undoLast, _undoLast)
      ..on(MessageType.fill, _fill);
  }

  void _onClose() {
    _loginManager.logoutSocket(_socket);
  }

  void _login(String username) {
    _loginManager.loginSocket(_socket, username);
  }

  void _createLobby(String json) {
    final info = CreateLobbyInfo.fromJson(json);

    _loginManager.createLobby(_socket, info);
  }

  void _enterLobby(String lobbyName) {
    _loginManager.enterLobby(_socket, lobbyName);
  }

  void _enterLobbyWithPassword(String json) {
    final info = LoginInfo.fromJson(json);

    _loginManager.enterSecureLobby(_socket, info);
  }

  void _exitLobby() {
    _loginManager.exitLobby(_socket);
  }

  void _drawNext() {
    if (!_loginManager.containsSocket(_socket)) return;

    final lobby = _loginManager.lobbyFromSocket(_socket);
    lobby.game.addToQueue(_socket);
  }

  void _guess(String json) {
    if (!_loginManager.containsSocket(_socket)) return;

    final lobby = _loginManager.lobbyFromSocket(_socket);

    final guess = Guess(_loginManager.usernameFromSocket(_socket), json);

    lobby.game.onGuess(_socket, guess);
  }

  void _drawPoint(String json) {
    final lobby = _loginManager.lobbyFromSocket(_socket);

    if (lobby == null) return;

    // check if current artist
    if (lobby.game.currentArtist != _socket) return;

    lobby.sendToAll(MessageType.drawPoint, val: json, excludedSocket: _socket);
    lobby.game.drawPoint(json);
  }

  void _drawLine(String json) {
    final lobby = _loginManager.lobbyFromSocket(_socket);

    if (lobby == null) return;

    // check if current artist
    if (lobby.game.currentArtist != _socket) return;

    lobby.sendToAll(MessageType.drawLine, val: json, excludedSocket: _socket);
    lobby.game.drawLine(json);
  }

  void _clearDrawing() {
    final lobby = _loginManager.lobbyFromSocket(_socket);

    if (lobby == null) return;

    // check if current artist
    if (lobby.game.currentArtist != _socket) return;

    lobby.sendToAll(MessageType.clearDrawing, excludedSocket: _socket);
    lobby.game.clearDrawing();
  }

  void _undoLast() {
    final lobby = _loginManager.lobbyFromSocket(_socket);

    if (lobby == null) return;

    // check if current artist
    if (lobby.game.currentArtist != _socket) return;

    lobby.sendToAll(MessageType.undoLast, excludedSocket: _socket);
    lobby.game.undoLast();
  }

  void _fill(String json) {
//    return;
//    final lobby = _loginManager.lobbyFromSocket(_socket);
//
//    if (lobby == null) return;
//
//    // check if current artist
//    if (lobby.game.currentArtist != _socket) return;
//
//    lobby.sendToAll(MessageType.fill, val: json, excludedSocket: _socket);
//    lobby.game.fill(json);
  }
}
