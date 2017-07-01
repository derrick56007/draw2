part of server;

class SocketReceiver {
  final LoginManager loginManager;
  final ServerWebSocket socket;

  SocketReceiver._internal(this.socket, this.loginManager);

  factory SocketReceiver.handle(
      ServerWebSocket socket, LoginManager loginManager) {
    final sr = new SocketReceiver._internal(socket, loginManager);

    sr._init();

    return sr;
  }

  _init() async {
    await socket.start();

    _onStart();

    await socket.done;

    _onClose();
  }

  _onStart() {
    socket
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
    loginManager.logoutSocket(socket);
  }

  _login(String username) {
    loginManager.loginSocket(socket, username);
  }

  _createLobby(String json) {
    final info = new CreateLobbyInfo.fromJson(json);

    loginManager.createLobby(socket, info);
  }

  _enterLobby(String lobbyName) {
    loginManager.enterLobby(socket, lobbyName);
  }

  _enterLobbyWithPassword(String json) {
    final info = new LoginInfo.fromJson(json);

    loginManager.enterSecureLobby(socket, info);
  }

  _exitLobby() {
    loginManager.exitLobby(socket);
  }

  _drawNext() {
    if (!loginManager.containsSocket(socket)) return;

    final lobby = loginManager.lobbyFromSocket(socket);
    lobby.game.addToQueue(socket);
  }

  _guess(String json) {
    if (!loginManager.containsSocket(socket)) return;

    final lobby = loginManager.lobbyFromSocket(socket);

    final guess = new Guess(loginManager.usernameFromSocket(socket), json);

    lobby.game.onGuess(socket, guess);
  }

  _drawPoint(String json) {
    final lobby = loginManager.lobbyFromSocket(socket);

    if (lobby == null) return;

    lobby.sendToAll(MessageType.drawPoint, val: json, excludedSocket: socket);
    lobby.game.drawPoint(json);
  }

  _drawLine(String json) {
    final lobby = loginManager.lobbyFromSocket(socket);

    if (lobby == null) return;

    lobby.sendToAll(MessageType.drawLine, val: json, excludedSocket: socket);
    lobby.game.drawLine(json);
  }

  _clearDrawing() {
    final lobby = loginManager.lobbyFromSocket(socket);

    if (lobby == null) return;

    lobby.sendToAll(MessageType.clearDrawing, excludedSocket: socket);
    lobby.game.clearDrawing();
  }

  _undoLast() {
    final lobby = loginManager.lobbyFromSocket(socket);

    if (lobby == null) return;

    lobby.sendToAll(MessageType.undoLast, excludedSocket: socket);
    lobby.game.undoLast();
  }

  _fill(String json) {
    final lobby = loginManager.lobbyFromSocket(socket);

    if (lobby == null) return;

    lobby.sendToAll(MessageType.fill, val: json, excludedSocket: socket);
    lobby.game.fill(json);
  }
}
