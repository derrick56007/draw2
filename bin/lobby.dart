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

    // create a lobby with info
    return lobby
      ..name = info.name
      ..password = info.password
      ..hasPassword = info.password.isNotEmpty
      ..hasTimer = info.hasTimer
      ..maxPlayers = info.maxPlayers
      ..game = new Game(lobby, info.hasTimer);
  }

  addPlayer(ServerWebSocket socket, String username) {
    // send info of existing players to the new player
    players.forEach((ServerWebSocket existingSocket, String existingUsername) {

      // player info
      var existingPlayer = new ExistingPlayer()
        ..username = existingUsername
        ..score = game.scores[existingSocket];

      socket.send(Message.existingPlayer, existingPlayer.toJson());
    });

    // add player to game
    players[socket] = username;
    game.addPlayer(socket);

    // alert other players of new player
    sendToAll(Message.newPlayer, username);

    print('$username joined lobby $name');

    sendPlayerOrder();
  }

  removePlayer(ServerWebSocket socket) {
    var username = players[socket];

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

      list.add([players[socket], i + 1]);
    }

    sendToAll(Message.setQueue, JSON.encode(list));
  }

  sendPlayerOrder() {
    var list = [];

    if (game.currentArtist != null) {
      list.add(players[game.currentArtist]);
    }

    for (var socket in game.artistQueue) {
      list.add(players[socket]);
    }

    sendToAll(Message.setPlayerOrder, JSON.encode(list));
  }
}
