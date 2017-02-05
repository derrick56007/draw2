part of server;

class Game {
  Lobby lobby;

  var players = <String, int>{};

  var unusedWordIndices = <int>[];

  var rand = new Random();

  bool hasTimer;
  Timer timer;
  Stopwatch stopwatch;

  String currentArtist;
  String currentWord;

  var artistQueue = <String>[];

  Game(this.lobby, this.hasTimer) {
    for (int i = 0; i < Data.words.length; i++) {
      unusedWordIndices.add(i);
    }

    stopwatch = new Stopwatch();
  }

  addPlayer(String username) {
    players[username] = 0;

    if (currentArtist == null) return;

    // TODO
  }

  removePlayer(String username) {
    players.remove(username);

    if (currentArtist != username) return;

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

      lobby
        ..server.sendToProfile(
            'name', currentArtist, Message.setAsArtist, currentWord)
        ..sendToAll(Message.setArtist, currentArtist,
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

  addToQueue(String username) {
    // stop if already in queue
    if (artistQueue.contains(username)) return;

    // stop if username is empty or is currently artist
    if (username.isNotEmpty && username == currentArtist) return;

    artistQueue.add(username);

    var guess = new Guess()
      ..username = 'Lobby'
      ..guess = '$username added to queue';

    lobby.sendToAll(Message.guess, guess.toJson());

    // stop if user was not
    if (artistQueue.length > 1 || currentArtist != null) return;

    nextArtist();
  }

  onGuess(Guess guess) {
    // current artist can't guess word
    if (guess.username == currentArtist) return;

    if (guess.guess.toLowerCase() == 'draw next') {
      addToQueue(guess.username);

      return;
    }

    ////////////// check for win //////////////////

    if (currentWord == null) return;

    // not a match
    if (guess.guess.toLowerCase() != currentWord.toLowerCase()) return;

    onWin(guess.username, currentWord);
  }

  onWin(String username, String word) {
    // TODO point system
    players[username] += 1;

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
