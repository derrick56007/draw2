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
      ..game = new Game(lobby, info.hasTimer);
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
    var username = gPlayers[socket];
    sendToAll(Message.removePlayer, username);

    print('$username left lobby $name');

    game.removePlayer(socket);

    players.remove(socket);
  }

  sendToAll(String request, dynamic val, {ServerWebSocket except}) {
    for (var socket in players.keys) {
      if (socket != except) {
        socket.send(request, val);
      }
    }
  }

  getInfo() => new LobbyInfo()
    ..name = name
    ..hasPassword = hasPassword
    ..hasTimer = hasTimer
    ..numberOfPlayers = game.scores.length
    ..maxPlayers = maxPlayers;

  sendQueueInfo() {
    var list = [];

    for (int i = 0; i < game.artistQueue.length; i++) {
      var socket = game.artistQueue[i];

      list.add([gPlayers[socket], i + 1]);
    }

    sendToAll(Message.setQueue, JSON.encode(list));
  }

  sendPlayerOrder() {
    var list = [];

    if (game.currentArtist != null) {
      list.add(gPlayers[game.currentArtist]);
    }

    for (var socket in game.artistQueue) {
      list.add(gPlayers[socket]);
    }

    sendToAll(Message.setPlayerOrder, JSON.encode(list));
  }
}
