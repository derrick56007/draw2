part of server;

class Game {
  static const nextRoundDelay = const Duration(seconds: 10);
  static const maxGameTime = const Duration(minutes: 5);
  static const timerTickInterval = const Duration(seconds: 1);

  final Lobby lobby;
  final bool hasTimer;

  var scores = <ServerWebSocket, int>{};

  List<int> unusedWordIndices;

  Timer timer;
  Stopwatch stopwatch;

  ServerWebSocket currentArtist;
  String currentWord;

  var artistQueue = <ServerWebSocket>[];

  Game(this.lobby, this.hasTimer) {
    unusedWordIndices = new List<int>.generate(Data.words.length, (i) => i);
    unusedWordIndices.shuffle();

    stopwatch = new Stopwatch();
  }

  addPlayer(ServerWebSocket socket) {
    scores[socket] = 0;
  }

  removePlayer(ServerWebSocket socket) {
    scores.remove(socket);

    // check if leaving player is current artist
    if (currentArtist == socket) {
      removeArtist();
    }
  }

  removeArtist() {
    timer?.cancel();

    currentArtist.send(Message.enableDrawNext, '');
    currentArtist = null;
    currentWord = null;

    if (artistQueue.isEmpty) return;

    nextArtist();
  }

  nextArtist() {
    startTimer(nextRoundDelay, (Duration elapsed) {
      lobby.sendToAll(Message.timerUpdate,
          'Next game in ${nextRoundDelay.inSeconds - elapsed.inSeconds}s');
    }, () {
      currentArtist = artistQueue.removeAt(0);

      lobby.sendQueueInfo();
      lobby.sendPlayerOrder();

      currentWord = Data.words[unusedWordIndices.removeLast()];

      var currentArtistName = lobby.players[currentArtist];

      currentArtist.send(Message.setAsArtist, currentWord);
      lobby.sendToAll(Message.setArtist, currentArtistName,
          except: currentArtist);

      if (!hasTimer) return;

      startTimer(maxGameTime, (Duration elapsed) {
        String twoDigits(int n) {
          if (n >= 10) return '$n';
          return '0$n';
        }

        var twoDigitMinutes =
            twoDigits(maxGameTime.inMinutes - elapsed.inMinutes);
        var twoDigitSeconds = twoDigits(
            (maxGameTime.inSeconds - elapsed.inSeconds)
                .remainder(Duration.SECONDS_PER_MINUTE));

        lobby.sendToAll(
            Message.timerUpdate, 'Time left $twoDigitMinutes:$twoDigitSeconds');
      }, () {
        lobby.sendToAll(Message.lose, 'The word was \"$currentWord\"');

        removeArtist();
      });
    });
  }

  addToQueue(ServerWebSocket socket) {
    // stop if already in queue
    if (artistQueue.contains(socket)) return;

    // stop if username is empty or is currently artist
    if (socket == currentArtist) return;

    artistQueue.add(socket);

    lobby.sendQueueInfo();
    lobby.sendPlayerOrder();

    // stop if user was not
    if (artistQueue.length > 1 || currentArtist != null) return;

    nextArtist();
  }

  onGuess(ServerWebSocket socket, Guess guess) {
    lobby.sendToAll(Message.guess, guess.toJson());

    ////////////// check for win //////////////////
    if (socket == currentArtist) return;

    if (currentWord == null) return;

    // not a match
    if (guess.guess.toLowerCase() != currentWord.toLowerCase()) return;

    onWin(socket, guess.username, currentWord);
  }

  onWin(ServerWebSocket socket, String username, String word) {
    // TODO point system
    scores[socket] += 1;

    lobby.sendToAll(Message.win, '$username guessed \"$word\" correctly!');
    lobby.sendToAll(
        Message.updatePlayerScore, JSON.encode([username, scores[socket]]));

    removeArtist();
  }

  startTimer(Duration duration, Function repeating(Duration elapsed),
      Function onFinish()) {

    timer?.cancel();

    stopwatch
      ..reset()
      ..start();

    timer = new Timer.periodic(timerTickInterval, (_) {
      repeating(stopwatch.elapsed);

      if (stopwatch.elapsedMilliseconds > duration.inMilliseconds) {
        timer?.cancel();
        stopwatch.stop();

        onFinish();
      }
    });
  }
}
