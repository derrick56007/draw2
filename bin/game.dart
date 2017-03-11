part of server;

class Game {
  final Lobby lobby;

  var scores = <ServerWebSocket, int>{};

  var unusedWordIndices = <int>[];

  var rand = new Random();

  final bool hasTimer;
  Timer timer;
  Stopwatch stopwatch;

  ServerWebSocket currentArtist;
  String currentWord;

  var artistQueue = <ServerWebSocket>[];

  Game(this.lobby, this.hasTimer) {
    for (int i = 0; i < Data.words.length; i++) {
      unusedWordIndices.add(i);
    }

    stopwatch = new Stopwatch();
  }

  addPlayer(ServerWebSocket socket) {
    scores[socket] = 0;
  }

  removePlayer(ServerWebSocket socket) {
    scores.remove(socket);

    if (currentArtist != socket) return;

    removeArtist();
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
    const nextRoundDelay = const Duration(seconds: 10);
    const maxGameTime = const Duration(minutes: 5);

    startTimer(nextRoundDelay, (Duration elapsed) {
      lobby.sendToAll(Message.timerUpdate,
          'Next game in ${nextRoundDelay.inSeconds - elapsed.inSeconds}s');
    }, () {
      currentArtist = artistQueue.removeAt(0);

      lobby.sendQueueInfo();
      lobby.sendPlayerOrder();

      int randIndex = rand.nextInt(unusedWordIndices.length);

      currentWord = Data.words[unusedWordIndices.removeAt(randIndex)];

      var currentArtistName = gPlayers[currentArtist];

      currentArtist.send(Message.setAsArtist, currentWord);
      lobby.sendToAll(Message.setArtist, currentArtistName,
          except: currentArtist);

      if (!hasTimer) return;

      startTimer(maxGameTime, (Duration elapsed) {
        String twoDigits(int n) {
          if (n >= 10) return "$n";
          return "0$n";
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
    lobby.sendToAll(Message.updatePlayerScore, JSON.encode([username, scores[socket]]));

    removeArtist();
  }

  startTimer(Duration duration, dynamic repeating, dynamic onFinish) {
    const interval = const Duration(seconds: 1);

    timer?.cancel();
    stopwatch
      ..reset()
      ..start();

    timer = new Timer.periodic(interval, (_) {
      repeating(stopwatch.elapsed);

      if (stopwatch.elapsedMilliseconds > duration.inMilliseconds) {
        timer?.cancel();
        stopwatch.stop();

        onFinish();
      }
    });
  }
}
