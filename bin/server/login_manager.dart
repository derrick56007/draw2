part of server;

class LoginManager {
  // shared instance
  static final shared = LoginManager._internal();

  final _lobbies = <String, Lobby>{};
  final _socketForUsername = <ServerWebSocket, String>{};
  final _socketForLobby = <ServerWebSocket, Lobby>{};

  // create singleton
  LoginManager._internal();

  // returns true if socket is logged in
  bool containsSocket(ServerWebSocket socket) =>
      _socketForUsername.containsKey(socket);

  // returns true if username is logged in
  bool containsUsername(String username) =>
      _socketForUsername.containsValue(username);

  // returns true if lobby name exists
  bool containsLobbyName(String lobbyName) => _lobbies.containsKey(lobbyName);

  // returns true if socket is in lobby
  bool socketIsCurrentlyInLobby(ServerWebSocket socket) =>
      _socketForLobby.containsKey(socket);

  // returns lobby from socket
  Lobby lobbyFromSocket(ServerWebSocket socket) => _socketForLobby[socket];

  // returns username from socket
  String usernameFromSocket(ServerWebSocket socket) =>
      _socketForUsername[socket];

  // get all sockets
  Iterable<ServerWebSocket> getSockets() => _socketForUsername.keys;

  // get all lobbies
  Iterable<Lobby> getLobbies() => _lobbies.values;

  // get all usernames
  Iterable<String> getUsernames() => _socketForUsername.values;

  // add lobby and alert others of new lobby
  void addLobby(Lobby lobby) {
    _lobbies[lobby.name] = lobby;

    // send lobby info to others
    for (var socket in getSockets()) {
      socket.send(MessageType.lobbyInfo, lobby.getInfo().toJson());
    }
  }

  // logs in socket with username
  void loginSocket(ServerWebSocket socket, String username) {
    // logout socket if previously logged in
    if (containsSocket(socket)) {
      logoutSocket(socket);
    }

    // check for null username
    if (username == null ||
        username.trim().isEmpty ||
        username.toLowerCase() == 'null') {
      socket.send(MessageType.toast, 'Invalid username');
      return;
    }

    // check if valid name
    if (!ValidateString.isValidUsername(username)) {
      socket.send(MessageType.toast, 'Invalid username');
      return;
    }

    // check if username already exists
    if (containsUsername(username)) {
      socket.send(MessageType.toast, 'Username taken');
      return;
    }

    // add user
    _socketForUsername[socket] = username;

    // alert successful login
    socket.send(MessageType.loginSuccessful);

    print('$username logged in');

    // TODO have the client request the info
    // send lobby info
    for (var lobby in getLobbies()) {
      socket.send(MessageType.lobbyInfo, lobby.getInfo().toJson());
    }
  }

  // logs out socket
  void logoutSocket(ServerWebSocket socket) {
    // check if socket is logged in
    if (!containsSocket(socket)) return;

    exitLobby(socket);

    final username = _socketForUsername.remove(socket);
    print('$username logged out');
  }

  // create lobby from info
  void createLobby(ServerWebSocket socket, CreateLobbyInfo info) {
    // check if lobby name already exists
    if (_lobbies.containsKey(info.lobbyName)) {
      socket.send(MessageType.toast, 'Lobby already exists');
      return;
    }

    if (!ValidateString.isValidLobbyName(info.lobbyName)) {
      socket.send(MessageType.toast, 'Invalid lobby name');
      return;
    }

    final lobby = Lobby.fromInfo(info);
    addLobby(lobby);

    _socketForLobby[socket] = lobby;
    lobby.addPlayer(socket, _socketForUsername[socket]);
    socket.send(MessageType.enterLobbySuccessful, lobby.name);
  }

  // enter lobby
  void enterLobby(ServerWebSocket socket, String lobbyName) {
    if (!_lobbies.containsKey(lobbyName)) {
      socket.send(MessageType.toast, 'Lobby doesn\'t exist');
      socket.send(MessageType.enterLobbyFailure);
      return;
    }

    final lobby = _lobbies[lobbyName];

    if (lobby.hasPassword) {
      socket.send(MessageType.requestPassword, lobbyName);
      return;
    }

    _socketForLobby[socket] = lobby;
    lobby.addPlayer(socket, _socketForUsername[socket]);
    socket.send(MessageType.enterLobbySuccessful, lobbyName);
  }

  // enter lobby with password
  void enterSecureLobby(ServerWebSocket socket, LoginInfo info) {
    if (!_lobbies.containsKey(info.lobbyName)) {
      socket.send(MessageType.toast, 'Lobby doesn\'t exist');
      socket.send(MessageType.enterLobbyFailure);
      return;
    }

    final lobby = _lobbies[info.lobbyName];

    if (lobby.hasPassword && lobby.password != info.password) {
      socket.send(MessageType.toast, 'Password is incorrect');
      socket.send(MessageType.enterLobbyFailure);
      return;
    }

    _socketForLobby[socket] = lobby;
    lobby.addPlayer(socket, usernameFromSocket(socket));
    socket.send(MessageType.enterLobbySuccessful, info.lobbyName);
  }

  void exitLobby(ServerWebSocket socket) {
    // check if socket is logged in
    if (!containsSocket(socket)) return;

    // check if socket was in a lobby
    if (!socketIsCurrentlyInLobby(socket)) return;

    final lobby = lobbyFromSocket(socket);
    lobby.removePlayer(socket);

    // check for empty lobby, ignore if default lobby
    if (lobby._players.isNotEmpty || lobby.isDefaultLobby) return;

    // remove empty lobby
    _lobbies.remove(lobby.name);
    print('closed lobby ${lobby.name}');

    // alert players of closed lobby
    for (var socket in getSockets()) {
      socket.send(MessageType.lobbyClosed, lobby.name);
    }
  }
}
