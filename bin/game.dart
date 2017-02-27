part of server;

class Game {
  Lobby lobby;

  var scores = <ServerWebSocket, int>{};

  var unusedWordIndices = <int>[];

  var rand = new Random();

  bool hasTimer;
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

    currentArtist = null;
    currentWord = null;

    if (artistQueue.isEmpty) return;

    nextArtist();
  }

  nextArtist() {
    const interval = const Duration(seconds: 1);
    const nextArtistDelay = const Duration(seconds: 10);
    const maxGameTime = const Duration(minutes: 5);

    startTimer(interval, nextArtistDelay, (Duration elapsed) {
      lobby.sendToAll(Message.timerUpdate,
          'Next game in ${nextArtistDelay.inSeconds - elapsed.inSeconds}s');
    }, () {
      currentArtist = artistQueue.removeAt(0);

      int randIndex = rand.nextInt(unusedWordIndices.length);

      currentWord = Data.words[unusedWordIndices.removeAt(randIndex)];

      currentArtist.send(Message.setAsArtist, currentWord);
      lobby.sendToAll(
          Message.setArtist, lobby.usernameFromSocket(currentArtist),
          except: currentArtist);

      if (!hasTimer) return;

      startTimer(interval, maxGameTime, (Duration elapsed) {
        String twoDigits(int n) {
          if (n >= 10) return "$n";
          return "0$n";
        }

        String twoDigitMinutes =
            twoDigits(maxGameTime.inMinutes - elapsed.inMinutes);
        String twoDigitSeconds = twoDigits(
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

  addToQueue(ServerWebSocket socket, String username) {
    // stop if already in queue
    if (artistQueue.contains(socket)) return;

    // stop if username is empty or is currently artist
    if (socket == currentArtist) return;

    artistQueue.add(socket);

    var guess = new Guess()
      ..username = 'Lobby'
      ..guess = '$username added to queue';

    lobby.sendToAll(Message.guess, guess.toJson());

    // stop if user was not
    if (artistQueue.length > 1 || currentArtist != null) return;

    nextArtist();
  }

  onGuess(ServerWebSocket socket, Guess guess) {
    if (socket == currentArtist) {
      return;
    }

    if (guess.guess.toLowerCase() == 'draw next') {
      addToQueue(socket, guess.username);

      return;
    }

    lobby.sendToAll(Message.guess, guess.toJson());

    ////////////// check for win //////////////////

    if (currentWord == null) return;

    // not a match
    if (guess.guess.toLowerCase() != currentWord.toLowerCase()) return;

    onWin(socket, guess.username, currentWord);
  }

  onWin(ServerWebSocket socket, String username, String word) {
    // TODO point system
    scores[socket] += 1;

    lobby.sendToAll(Message.win, '$username guessed \"$word\" correctly!');

    removeArtist();
  }

  startTimer(Duration interval, Duration duration, dynamic fn, dynamic done) {
    timer?.cancel();
    stopwatch
      ..reset()
      ..start();

    timer = new Timer.periodic(interval, (_) {
      fn(stopwatch.elapsed);

      if (stopwatch.elapsedMilliseconds > duration.inMilliseconds) {
        timer?.cancel();
        stopwatch.stop();

        done();
      }
    });
  }
}
