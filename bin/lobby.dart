part of server;

class Lobby {
  String name;
  String password;
  bool hasPassword;
  bool hasTimer;
  int maxPlayers;

  Map<ServerWebSocket, String> players = {};
  Game game;

  Lobby._internal() {}

  factory Lobby(CreateLobbyInfo info) {
    var lobby = new Lobby._internal();
    return lobby
      ..name = info.name
      ..password = info.password
      ..hasPassword = info.password.isNotEmpty
      ..hasTimer = info.hasTimer
      ..maxPlayers = info.maxPlayers
      ..game = new Game(lobby, lobby.hasTimer);
  }

  String usernameFromSocket(ServerWebSocket socket) {
    return players[socket];
  }

  addPlayer(ServerWebSocket socket, String username) {
    players.forEach((ServerWebSocket existingSocket, String existingUsername) {
      var existingPlayer = new ExistingPlayer()
        ..username = existingUsername
        ..score = game.scores[existingSocket];

      socket.send(Message.existingPlayer, existingPlayer.toJson());
    });

    players[socket] = username;
    game.addPlayer(socket);

    sendToAll(Message.newPlayer, username);

    print('$username joined lobby $name');
  }

  removePlayer(ServerWebSocket socket) {
    sendToAll(Message.removePlayer, usernameFromSocket(socket));

    print('$socket left lobby $name');

    game.removePlayer(socket);

    players.remove(socket);
  }

  sendToAll(String request, dynamic val, {ServerWebSocket except}) {
    for (ServerWebSocket socket in players.keys) {
      if (socket != except) {
        socket.send(request, val);
      }
    }
  }

  onGuess(ServerWebSocket socket, Guess guess) {
    sendToAll(Message.guess, guess.toJson());

    game.onGuess(socket, guess);
  }

  LobbyInfo getInfo() => new LobbyInfo()
    ..name = name
    ..hasPassword = hasPassword
    ..hasTimer = hasTimer
    ..numberOfPlayers = game.scores.length
    ..maxPlayers = maxPlayers;
}
