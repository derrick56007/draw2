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
      ..on(Message.login, _login)
      ..on(Message.createLobby, _createLobby)
      ..on(Message.enterLobby, _enterLobby)
      ..on(Message.enterLobbyWithPassword, _enterLobbyWithPassword)
      ..on(Message.drawNext, _drawNext)
      ..on(Message.guess, _guess)
      ..on(Message.drawPoint, _drawPoint)
      ..on(Message.drawLine, _drawLine)
      ..on(Message.clearDrawing, _clearDrawing)
      ..on(Message.undoLast, _undoLast)
      ..on(Message.changeColor, _changeColor)
      ..on(Message.changeSize, _changeSize);
  }

  _onClose() {
    // check if player was logged in
    if (!gPlayers.containsKey(socket)) return;

    // check if player was in a lobby
    if (gPlayerLobby.containsKey(socket)) {
      var lobby = gPlayerLobby.remove(socket);
      lobby.removePlayer(socket);

      // close lobby if empty
      if (lobby.players.isEmpty) {
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

    socket.send(Message.loginSuccesful, '');

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
      socket.send(Message.enterLobbyFailure, '');
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
      socket.send(Message.enterLobbyFailure, '');
      return;
    }

    var lobby = gLobbies[loginInfo.lobbyName];

    if (lobby.hasPassword && lobby.password != loginInfo.password) {
      socket.send(Message.toast, 'Password is incorrect');
      socket.send(Message.enterLobbyFailure, '');
      return;
    }

    gPlayerLobby[socket] = lobby;
    lobby.addPlayer(socket, gPlayers[socket]);
    socket.send(Message.enterLobbySuccessful, loginInfo.lobbyName);
  }

  _drawNext(_) {
    if (!gPlayerLobby.containsKey(socket)) return null;

    var lobby = gPlayerLobby[socket];
    lobby.game.addToQueue(socket);
  }

  _guess(String json) {
    if (!gPlayerLobby.containsKey(socket)) return null;

    var lobby = gPlayerLobby[socket];

    var guess = new Guess()
      ..username = gPlayers[socket]
      ..guess = json;

    lobby.game.onGuess(socket, guess);
  }

  _drawPoint(String json) {
    var lobby = gPlayerLobby[socket];
    lobby?.sendToAll(Message.drawPoint, json, except: socket);
  }

  _drawLine(String json) {
    var lobby = gPlayerLobby[socket];
    lobby?.sendToAll(Message.drawLine, json, except: socket);
  }

  _clearDrawing(String json) {
    var lobby = gPlayerLobby[socket];
    lobby?.sendToAll(Message.clearDrawing, json, except: socket);
  }

  _undoLast(String json) {
    var lobby = gPlayerLobby[socket];
    lobby?.sendToAll(Message.undoLast, json, except: socket);
  }

  _changeColor(String json) {
    var lobby = gPlayerLobby[socket];
    lobby?.sendToAll(Message.changeColor, json, except: socket);
  }

  _changeSize(String json) {
    var lobby = gPlayerLobby[socket];
    lobby?.sendToAll(Message.changeSize, json, except: socket);
  }
}
