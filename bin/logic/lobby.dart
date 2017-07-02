part of server;

class Lobby {
  final String name;
  final String password;
  final bool hasPassword;
  final bool hasTimer;
  final int maxPlayers;
  final Map<ServerWebSocket, String> _players = {};

  final bool isDefault;

  Game game;

  Lobby(this.name,
       {this.password = '',
        this.hasTimer = true,
        this.maxPlayers = 15,
        this.isDefault = false})
      : hasPassword = password.isNotEmpty {
    game = new Game(this, hasTimer);
  }

  factory Lobby.fromInfo(CreateLobbyInfo info) => new Lobby(info.name,
      password: info.password,
      hasTimer: info.hasTimer,
      maxPlayers: info.maxPlayers);

  getInfo() =>
      new LobbyInfo(name, hasPassword, hasTimer, maxPlayers, _players.length);

  addPlayer(ServerWebSocket socket, String username) {
    // send info of existing players to the new player
    _players.forEach((ServerWebSocket existingSocket, String existingUsername) {
      // player info
      final existingPlayer =
          new ExistingPlayer(existingUsername, game.scores[existingSocket]);

      socket.send(MessageType.existingPlayer, existingPlayer.toJson());
    });

    // add player to game
    _players[socket] = username;
    game.addPlayer(socket);

    // alert other players of new player
    sendToAll(MessageType.newPlayer, val: username);

    print('$username joined lobby $name');

    sendQueueInfo();
    sendPlayerOrder();

    socket.send(MessageType.clearCanvasLabels);

    if (game.currentArtist != null) {
      final currentArtistName = _players[socket];

      socket.send(
          MessageType.setCanvasLeftLabel, '$currentArtistName is drawing');
    }

    if (game.guesses.isNotEmpty) {
      for (var guess in game.guesses) {
        socket.send(MessageType.guess, guess.toJson());
      }
    }

    if (game.canvasLayers.isNotEmpty) {
      socket.send(
          MessageType.existingCanvasLayers, JSON.encode(game.canvasLayers));
    }
  }

  removePlayer(ServerWebSocket socket) {
    final username = _players[socket];

    sendToAll(MessageType.removePlayer, val: username);

    print('$username left lobby $name');

    game.removePlayer(socket);

    _players.remove(socket);
  }

  sendToAll(MessageType type, {var val, ServerWebSocket excludedSocket}) {
    // send to all players in lobby except for the excluded socket
    for (var socket in _players.keys.where((s) => s != excludedSocket)) {
      socket.send(type, val);
    }
  }

  sendQueueInfo() {
    final list = [];

    for (var i = 0; i < game.artistQueue.length; i++) {
      final socket = game.artistQueue[i];

      final username = usernameFromSocket(socket);

      list.add([username, i + 1]);
    }

    sendToAll(MessageType.setQueue, val: JSON.encode(list));
  }

  sendPlayerOrder() {
    final list = <String>[];

    // current artist will be first in the list
    if (game.currentArtist != null) {
      final username = usernameFromSocket(game.currentArtist);

      list.add(username);
    }

    // add the rest of the artist queue
    for (var socket in game.artistQueue) {
      final username = usernameFromSocket(socket);

      list.add(username);
    }

    // prevent sending empty list
    if (list.isEmpty) {
      return;
    }

    sendToAll(MessageType.setPlayerOrder, val: JSON.encode(list));
  }

  usernameFromSocket(ServerWebSocket socket) => _players[socket];
}
