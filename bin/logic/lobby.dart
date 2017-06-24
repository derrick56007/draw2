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
      final existingPlayer =
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

    socket.send(Message.clearCanvasLabels);

    if (game.currentArtist != null) {
      final currentArtistName = players[socket];

      socket.send(Message.setCanvasLeftLabel, '$currentArtistName is drawing');
    }

    if (game.guesses.isNotEmpty) {
      for (var guess in game.guesses) {
        socket.send(Message.guess, guess.toJson());
      }
    }

    if (game.canvasLayers.isNotEmpty) {
      socket.send(Message.existingCanvasLayers, JSON.encode(game.canvasLayers));
    }
  }

  removePlayer(ServerWebSocket socket) {
    final username = players[socket];

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
    final list = [];

    for (var i = 0; i < game.artistQueue.length; i++) {
      final socket = game.artistQueue[i];

      list.add([players[socket], i + 1]);
    }

    sendToAll(Message.setQueue, val: JSON.encode(list));
  }

  sendPlayerOrder() {
    final list = [];

    if (game.currentArtist != null) {
      list.add(players[game.currentArtist]);
    }

    for (var socket in game.artistQueue) {
      list.add(players[socket]);
    }

    sendToAll(Message.setPlayerOrder, val: JSON.encode(list));
  }
}
