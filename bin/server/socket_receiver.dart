part of server;

class SocketReceiver {
  final LoginManager _loginManager = LoginManager.getSharedInstance();
  final ServerWebSocket _socket;

  SocketReceiver._internal(this._socket);

  factory SocketReceiver.handle(ServerWebSocket socket) {
    final sr = new SocketReceiver._internal(socket);

    sr._init();

    return sr;
  }

  _init() async {
    await _socket.start();

    _onStart();

    await _socket.done;

    _onClose();
  }

  _onStart() {
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

  _onClose() {
    _loginManager.logoutSocket(_socket);
  }

  _login(String username) {
    _loginManager.loginSocket(_socket, username);
  }

  _createLobby(String json) {
    final info = new CreateLobbyInfo.fromJson(json);

    _loginManager.createLobby(_socket, info);
  }

  _enterLobby(String lobbyName) {
    _loginManager.enterLobby(_socket, lobbyName);
  }

  _enterLobbyWithPassword(String json) {
    final info = new LoginInfo.fromJson(json);

    _loginManager.enterSecureLobby(_socket, info);
  }

  _exitLobby() {
    _loginManager.exitLobby(_socket);
  }

  _drawNext() {
    if (!_loginManager.containsSocket(_socket)) return;

    final lobby = _loginManager.lobbyFromSocket(_socket);
    lobby.game.addToQueue(_socket);
  }

  _guess(String json) {
    if (!_loginManager.containsSocket(_socket)) return;

    final lobby = _loginManager.lobbyFromSocket(_socket);

    final guess = new Guess(_loginManager.usernameFromSocket(_socket), json);

    lobby.game.onGuess(_socket, guess);
  }

  _drawPoint(String json) {
    final lobby = _loginManager.lobbyFromSocket(_socket);

    if (lobby == null) return;

    lobby.sendToAll(MessageType.drawPoint, val: json, excludedSocket: _socket);
    lobby.game.drawPoint(json);
  }

  _drawLine(String json) {
    final lobby = _loginManager.lobbyFromSocket(_socket);

    if (lobby == null) return;

    lobby.sendToAll(MessageType.drawLine, val: json, excludedSocket: _socket);
    lobby.game.drawLine(json);
  }

  _clearDrawing() {
    final lobby = _loginManager.lobbyFromSocket(_socket);

    if (lobby == null) return;

    lobby.sendToAll(MessageType.clearDrawing, excludedSocket: _socket);
    lobby.game.clearDrawing();
  }

  _undoLast() {
    final lobby = _loginManager.lobbyFromSocket(_socket);

    if (lobby == null) return;

    lobby.sendToAll(MessageType.undoLast, excludedSocket: _socket);
    lobby.game.undoLast();
  }

  _fill(String json) {
    final lobby = _loginManager.lobbyFromSocket(_socket);

    if (lobby == null) return;

    lobby.sendToAll(MessageType.fill, val: json, excludedSocket: _socket);
    lobby.game.fill(json);
  }
}
