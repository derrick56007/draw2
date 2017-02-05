part of server;

class Lobby {
  ForceServer server;

  String name;
  String password;
  bool hasPassword;
  bool hasTimer;
  int maxPlayers;

  Game game;

  Lobby(this.server, CreateLobbyInfo info) {
    name = info.name;
    password = info.password;
    hasPassword = info.password.isNotEmpty;
    hasTimer = info.hasTimer;
    maxPlayers = info.maxPlayers;

    game = new Game(this, hasTimer);

    print('Created lobby ${getInfo().toString()}');
  }

  addPlayer(String username) {
    for (String user in game.players.keys) {
      var existingPlayer = new ExistingPlayer()
        ..username = user
        ..score = game.players[user];

      server.sendToProfile(
          'name', username, Message.existingPlayer, existingPlayer.toJson());
    }

    game.addPlayer(username);

    sendToAll(Message.newPlayer, username);

    print('$username joined lobby $name');
  }

  removePlayer(String username) {
    sendToAll(Message.removePlayer, username);

    print('$username left lobby $name');

    game.removePlayer(username);
  }

  sendToAll(String message, dynamic val, {String except = ''}) {
    for (String name in game.players.keys) {
      if (name != except) {
        server.sendToProfile('name', name, message, val);
      }
    }
  }

  onGuess(Guess guess) {
    sendToAll(Message.guess, guess.toJson());

    game.onGuess(guess);
  }

  LobbyInfo getInfo() => new LobbyInfo()
    ..name = name
    ..hasPassword = hasPassword
    ..hasTimer = hasTimer
    ..numberOfPlayers = game.players.length
    ..maxPlayers = maxPlayers;
}
