part of server;

class SocketReceiver {
  final ServerWebSocket socket;

  SocketReceiver._internal(this.socket);

  factory SocketReceiver.handle(ServerWebSocket socket) {
    var sr = new SocketReceiver._internal(socket);

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
      ..on(Message.login, (x) => _login(x))
      ..on(Message.createLobby, (x) => _createLobby(x))
      ..on(Message.enterLobby, (x) => _enterLobby(x))
      ..on(Message.enterLobbyWithPassword, (x) => _enterLobbyWithPassword(x))
      ..on(Message.drawNext, (_) => _drawNext())
      ..on(Message.guess, (x) => _guess(x))
      ..on(Message.drawPoint, (x) => _drawPoint(x))
      ..on(Message.drawLine, (x) => _drawLine(x))
      ..on(Message.clearDrawing, (_) => _clearDrawing())
      ..on(Message.undoLast, (_) => _undoLast())
      ..on(Message.fill, (x) => _fill(x));
  }

  _onClose() {
    // check if player was logged in
    if (!gPlayers.containsKey(socket)) return;

    // check if player was in a lobby
    if (gPlayerLobby.containsKey(socket)) {
      var lobby = gPlayerLobby.remove(socket);
      lobby.removePlayer(socket);

      // close lobby if empty and is not default lobby
      if (lobby.players.isEmpty && !defaultLobbies.contains(lobby)) {
        print('closed lobby ${lobby.name}');
        gLobbies.remove(lobby.name);

        // tell all players
        for (var sk in gPlayers.keys) {
          sk.send(Message.lobbyClosed, lobby.name);
        }
      }
    }

    var username = gPlayers.remove(socket);
    print('$username logged out');
  }

  _login(String username) {
    /////////// check if username exists ///////////
    if (gPlayers.containsValue(username)) {
      socket.send(Message.toast, 'Username taken');
      return;
    }
    ////////////////////////////////////////////////

    ///////// check if valid name ////////////////
    if (!isValidLobbyName(username)) {
      socket.send(Message.toast, 'Invalid username');
      return;
    }
    //////////////////////////////////////////////

    gPlayers[socket] = username;

    socket.send(Message.loginSuccesful);

    print('$username logged in');

    // send lobby info
    for (var lobby in gLobbies.values) {
      socket.send(Message.lobbyInfo, lobby.getInfo().toJson());
    }
  }

  _createLobby(String json) {
    var createLobbyInfo = new CreateLobbyInfo.fromJson(json);

    ////////// check if lobby exists /////////////
    if (gLobbies.containsKey(createLobbyInfo.name)) {
      socket.send(Message.toast, 'Lobby already exists');
      return;
    }
    //////////////////////////////////////////////

    ///////// check if valid name ////////////////
    if (!isValidLobbyName(createLobbyInfo.name)) {
      socket.send(Message.toast, 'Invalid lobby name');
      return;
    }
    //////////////////////////////////////////////

    print('new lobby ${createLobbyInfo.toJson()}');

    var lobby = new Lobby(createLobbyInfo);
    gLobbies[createLobbyInfo.name] = lobby;

    for (var otherSocket in gPlayers.keys) {
      otherSocket.send(Message.lobbyInfo, lobby.getInfo().toJson());
    }

    gPlayerLobby[socket] = lobby;
    lobby.addPlayer(socket, gPlayers[socket]);
    socket.send(Message.enterLobbySuccessful, lobby.name);
  }

  _enterLobby(String lobbyName) {
    ////////// check if lobby exists ////////////////
    if (!gLobbies.containsKey(lobbyName)) {
      socket.send(Message.toast, 'Lobby doesn\'t exist');
      socket.send(Message.enterLobbyFailure);
      return;
    }

    var lobby = gLobbies[lobbyName];

    if (lobby.hasPassword) {
      socket.send(Message.requestPassword, lobbyName);
      return;
    }

    gPlayerLobby[socket] = lobby;
    lobby.addPlayer(socket, gPlayers[socket]);
    socket.send(Message.enterLobbySuccessful, lobbyName);
  }

  _enterLobbyWithPassword(String json) {
    var loginInfo = new LoginInfo.fromJson(json);

    if (!gLobbies.containsKey(loginInfo.lobbyName)) {
      socket.send(Message.toast, 'Lobby doesn\'t exist');
      socket.send(Message.enterLobbyFailure);
      return;
    }

    var lobby = gLobbies[loginInfo.lobbyName];

    if (lobby.hasPassword && lobby.password != loginInfo.password) {
      socket.send(Message.toast, 'Password is incorrect');
      socket.send(Message.enterLobbyFailure);
      return;
    }

    gPlayerLobby[socket] = lobby;
    lobby.addPlayer(socket, gPlayers[socket]);
    socket.send(Message.enterLobbySuccessful, loginInfo.lobbyName);
  }

  _drawNext() {
    if (!gPlayerLobby.containsKey(socket)) return;

    var lobby = gPlayerLobby[socket];
    lobby.game.addToQueue(socket);
  }

  _guess(String json) {
    if (!gPlayerLobby.containsKey(socket)) return;

    var lobby = gPlayerLobby[socket];

    var guess = new Guess(gPlayers[socket], json);

    lobby.game.onGuess(socket, guess);
  }

  _drawPoint(String json) {
    var lobby = gPlayerLobby[socket];

    if (lobby == null) return;

    lobby.sendToAll(Message.drawPoint, val: json, except: socket);
    lobby.game.drawPoint(json);
  }

  _drawLine(String json) {
    var lobby = gPlayerLobby[socket];

    if (lobby == null) return;

    lobby.sendToAll(Message.drawLine, val: json, except: socket);
    lobby.game.drawLine(json);
  }

  _clearDrawing() {
    var lobby = gPlayerLobby[socket];

    if (lobby == null) return;

    lobby.sendToAll(Message.clearDrawing, except: socket);
    lobby.game.clearDrawing();
  }

  _undoLast() {
    var lobby = gPlayerLobby[socket];

    if (lobby == null) return;

    lobby.sendToAll(Message.undoLast, except: socket);
    lobby.game.undoLast();
  }

  _fill(String json) {
    var lobby = gPlayerLobby[socket];

    if (lobby == null) return;

    lobby.sendToAll(Message.fill, val: json, except: socket);
    lobby.game.fill(json);
  }
}
