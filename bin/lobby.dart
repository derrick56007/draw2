part of server;

class Lobby {
  final String name;
  final String password;
  final bool hasPassword;
  final bool hasTimer;
  final int maxPlayers;
  final Map<ServerWebSocket, String> players = {};

  Game game;

  Lobby._internal(this.name, this.password, this.hasPassword, this.hasTimer,
      this.maxPlayers) {
    game = new Game(this, hasTimer);
  }

  factory Lobby(CreateLobbyInfo info) {
    var lobby;
    lobby = new Lobby._internal(info.name, info.password,
        info.password.isNotEmpty, info.hasTimer, info.maxPlayers);

    return lobby;
  }

  getInfo() =>
      new LobbyInfo(name, hasPassword, hasTimer, maxPlayers, players.length);

  addPlayer(ServerWebSocket socket, String username) {
    // send info of existing players to the new player
    players.forEach((ServerWebSocket existingSocket, String existingUsername) {
      // player info
      var existingPlayer =
          new ExistingPlayer(existingUsername, game.scores[existingSocket]);

      socket.send(Message.existingPlayer, existingPlayer.toJson());
    });

    // add player to game
    players[socket] = username;
    game.addPlayer(socket);

    // alert other players of new player
    sendToAll(Message.newPlayer, val: username);

    print('$username joined lobby $name');

    sendQueueInfo();
    sendPlayerOrder();
  }

  removePlayer(ServerWebSocket socket) {
    var username = players[socket];

    sendToAll(Message.removePlayer, val: username);

    print('$username left lobby $name');

    game.removePlayer(socket);

    players.remove(socket);
  }

  sendToAll(String request, {var val, ServerWebSocket except}) {
    for (var socket in players.keys) {
      if (socket != except) {
        if (val != null) {
          socket.send(request, val);
        } else {
          socket.send(request);
        }
      }
    }
  }

  sendQueueInfo() {
    var list = [];

    for (int i = 0; i < game.artistQueue.length; i++) {
      var socket = game.artistQueue[i];

      list.add([players[socket], i + 1]);
    }

    sendToAll(Message.setQueue, val: JSON.encode(list));
  }

  sendPlayerOrder() {
    var list = [];

    if (game.currentArtist != null) {
      list.add(players[game.currentArtist]);
    }

    for (var socket in game.artistQueue) {
      list.add(players[socket]);
    }

    sendToAll(Message.setPlayerOrder, val: JSON.encode(list));
  }
}
