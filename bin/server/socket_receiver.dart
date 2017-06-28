part of server;

class SocketReceiver {
  final ServerWebSocket socket;

  SocketReceiver._internal(this.socket);

  factory SocketReceiver.handle(ServerWebSocket socket) {
    final sr = new SocketReceiver._internal(socket);

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
      ..on(MessageType.drawNext, _drawNext)
      ..on(MessageType.guess, _guess)
      ..on(MessageType.drawPoint, _drawPoint)
      ..on(MessageType.drawLine, _drawLine)
      ..on(MessageType.clearDrawing, _clearDrawing)
      ..on(MessageType.undoLast, _undoLast)
      ..on(MessageType.fill, _fill);
  }

  _onClose() {
    // check if player was logged in
    if (!gPlayers.containsKey(socket)) return;

    // check if player was in a lobby
    if (gPlayerLobby.containsKey(socket)) {
      final lobby = gPlayerLobby.remove(socket);
      lobby.removePlayer(socket);

      // close lobby if empty and is not default lobby
      if (lobby.players.isEmpty && !defaultLobbies.contains(lobby)) {
        print('closed lobby ${lobby.name}');
        gLobbies.remove(lobby.name);

        // tell all players
        for (var sk in gPlayers.keys) {
          sk.send(MessageType.lobbyClosed, lobby.name);
        }
      }
    }

    final username = gPlayers.remove(socket);
    print('$username logged out');
  }

  _login(String username) {
    // check for null
    if (username == null || username.isEmpty || username == 'null') {
      socket.send(MessageType.toast, 'Invalid username');
      return;
    }

    /////////// check if username exists ///////////
    if (gPlayers.containsValue(username)) {
      socket.send(MessageType.toast, 'Username taken');
      return;
    }
    ////////////////////////////////////////////////

    ///////// check if valid name ////////////////
    if (!isValidLobbyName(username)) {
      socket.send(MessageType.toast, 'Invalid username');
      return;
    }
    //////////////////////////////////////////////

    gPlayers[socket] = username;

    socket.send(MessageType.loginSuccesful);

    print('$username logged in');

    // send lobby info
    for (var lobby in gLobbies.values) {
      socket.send(MessageType.lobbyInfo, lobby.getInfo().toJson());
    }
  }

  _createLobby(String json) {
    final createLobbyInfo = new CreateLobbyInfo.fromJson(json);

    ////////// check if lobby exists /////////////
    if (gLobbies.containsKey(createLobbyInfo.name)) {
      socket.send(MessageType.toast, 'Lobby already exists');
      return;
    }
    //////////////////////////////////////////////

    ///////// check if valid name ////////////////
    if (!isValidLobbyName(createLobbyInfo.name)) {
      socket.send(MessageType.toast, 'Invalid lobby name');
      return;
    }
    //////////////////////////////////////////////

    print('new lobby ${createLobbyInfo.toJson()}');

    final lobby = new Lobby(createLobbyInfo);
    gLobbies[createLobbyInfo.name] = lobby;

    for (var otherSocket in gPlayers.keys) {
      otherSocket.send(MessageType.lobbyInfo, lobby.getInfo().toJson());
    }

    gPlayerLobby[socket] = lobby;
    lobby.addPlayer(socket, gPlayers[socket]);
    socket.send(MessageType.enterLobbySuccessful, lobby.name);
  }

  _enterLobby(String lobbyName) {
    ////////// check if lobby exists ////////////////
    if (!gLobbies.containsKey(lobbyName)) {
      socket.send(MessageType.toast, 'Lobby doesn\'t exist');
      socket.send(MessageType.enterLobbyFailure);
      return;
    }

    final lobby = gLobbies[lobbyName];

    if (lobby.hasPassword) {
      socket.send(MessageType.requestPassword, lobbyName);
      return;
    }

    gPlayerLobby[socket] = lobby;
    lobby.addPlayer(socket, gPlayers[socket]);
    socket.send(MessageType.enterLobbySuccessful, lobbyName);
  }

  _enterLobbyWithPassword(String json) {
    final loginInfo = new LoginInfo.fromJson(json);

    if (!gLobbies.containsKey(loginInfo.lobbyName)) {
      socket.send(MessageType.toast, 'Lobby doesn\'t exist');
      socket.send(MessageType.enterLobbyFailure);
      return;
    }

    final lobby = gLobbies[loginInfo.lobbyName];

    if (lobby.hasPassword && lobby.password != loginInfo.password) {
      socket.send(MessageType.toast, 'Password is incorrect');
      socket.send(MessageType.enterLobbyFailure);
      return;
    }

    gPlayerLobby[socket] = lobby;
    lobby.addPlayer(socket, gPlayers[socket]);
    socket.send(MessageType.enterLobbySuccessful, loginInfo.lobbyName);
  }

  _drawNext() {
    if (!gPlayerLobby.containsKey(socket)) return;

    final lobby = gPlayerLobby[socket];
    lobby.game.addToQueue(socket);
  }

  _guess(String json) {
    if (!gPlayerLobby.containsKey(socket)) return;

    final lobby = gPlayerLobby[socket];

    final guess = new Guess(gPlayers[socket], json);

    lobby.game.onGuess(socket, guess);
  }

  _drawPoint(String json) {
    final lobby = gPlayerLobby[socket];

    if (lobby == null) return;

    lobby.sendToAll(MessageType.drawPoint, val: json, excludedSocket: socket);
    lobby.game.drawPoint(json);
  }

  _drawLine(String json) {
    final lobby = gPlayerLobby[socket];

    if (lobby == null) return;

    lobby.sendToAll(MessageType.drawLine, val: json, excludedSocket: socket);
    lobby.game.drawLine(json);
  }

  _clearDrawing() {
    final lobby = gPlayerLobby[socket];

    if (lobby == null) return;

    lobby.sendToAll(MessageType.clearDrawing, excludedSocket: socket);
    lobby.game.clearDrawing();
  }

  _undoLast() {
    final lobby = gPlayerLobby[socket];

    if (lobby == null) return;

    lobby.sendToAll(MessageType.undoLast, excludedSocket: socket);
    lobby.game.undoLast();
  }

  _fill(String json) {
    final lobby = gPlayerLobby[socket];

    if (lobby == null) return;

    lobby.sendToAll(MessageType.fill, val: json, excludedSocket: socket);
    lobby.game.fill(json);
  }
}
