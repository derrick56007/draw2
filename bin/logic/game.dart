part of server;

class Game {
  static const nextRoundDelay = const Duration(seconds: 10);
  static const maxGameTime = const Duration(minutes: 5);
  static const timerTickInterval = const Duration(seconds: 1);
  static const maxChatLength = 20;
  static const defaultBrushColor = '#000000';
  static const defaultBrushSize = 5;

  final Lobby lobby;
  final bool hasTimer;

  var scores = <ServerWebSocket, int>{};

  Timer timer;
  final Stopwatch stopwatch;

  ServerWebSocket currentArtist;
  String currentWord;

  var artistQueue = <ServerWebSocket>[];

  List<Guess> guesses = [];

  List<CanvasLayer> canvasLayers = [];

  String brushColor = defaultBrushColor;
  int brushSize = defaultBrushSize;

  final Words words;

  Game(this.lobby, this.hasTimer)
      : stopwatch = new Stopwatch(),
        // TODO word genres
        words = new Words('cat1');

  addPlayer(ServerWebSocket socket) {
    scores[socket] = 0;
  }

  removePlayer(ServerWebSocket socket) {
    scores.remove(socket);

    // remove from queue
    artistQueue.remove(socket);

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

    if (artistQueue.isEmpty) {
      lobby.sendToAll(Message.setCanvasRightLabel, val: 'Click draw next!');
    } else {
      nextArtist();
    }
  }

  nextArtist() {
    startTimer(nextRoundDelay, (Duration elapsed) {
      lobby.sendToAll(Message.setCanvasRightLabel,
          val: 'Next game in ${nextRoundDelay.inSeconds - elapsed.inSeconds}s');
    }, () {
      currentArtist = artistQueue.removeAt(0);

      // clear the canvas
      canvasLayers.clear();

      brushColor = defaultBrushColor;
      brushSize = defaultBrushSize;

      lobby
        ..sendQueueInfo()
        ..sendPlayerOrder();

      // TODO check for end game
      currentWord = words.list.removeLast();

      var currentArtistName = lobby.players[currentArtist];

      currentArtist
        ..send(Message.clearCanvasLabels)
        ..send(Message.setCanvasLeftLabel, 'You are drawing')
        ..send(Message.setCanvasMiddleLabel, currentWord)
        ..send(Message.setAsArtist);

      lobby
        ..sendToAll(Message.clearCanvasLabels, except: currentArtist)
        ..sendToAll(Message.setCanvasLeftLabel,
            val: '$currentArtistName is drawing', except: currentArtist)
        ..sendToAll(Message.setArtist, except: currentArtist);

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

        lobby.sendToAll(Message.setCanvasRightLabel,
            val: 'Time left $twoDigitMinutes:$twoDigitSeconds');
      }, () {
        lobby
          ..sendToAll(Message.lose)
          ..sendToAll(Message.setCanvasMiddleLabel,
              val: 'The word was \"$currentWord\"');

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
    guesses.add(guess);

    if (guesses.length > maxChatLength) {
      guesses.removeAt(0);
    }

    lobby.sendToAll(Message.guess, val: guess.toJson());

    ////////////// check for win //////////////////

    if (socket == currentArtist) return;

    if (currentWord == null) return;

    // not a match
    if (guess.guess.trim().toLowerCase() != currentWord.trim().toLowerCase())
      return;

    onWin(socket, guess.username, currentWord);
  }

  onWin(ServerWebSocket socket, String username, String word) {
    // TODO point system
    scores[socket] += 1;

    lobby
      ..sendToAll(Message.clearCanvasLabels)
      ..sendToAll(Message.setCanvasMiddleLabel,
          val: '$username guessed \"$word\" correctly!')
      ..sendToAll(Message.win)
      ..sendToAll(Message.updatePlayerScore,
          val: JSON.encode([username, scores[socket]]));

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

  drawPoint(String json) {
    var drawPoint = new DrawPoint.fromJson(json);

    var layer =
        new CanvasLayer([drawPoint.pos], drawPoint.color, drawPoint.size);

    canvasLayers.add(layer);
  }

  drawLine(String json) {
    if (canvasLayers.isNotEmpty) {
      var point = new Point.fromJson(json);

      canvasLayers.last.points.add(point);
    }
  }

  clearDrawing() {
    canvasLayers.clear();
  }

  undoLast() {
    if (canvasLayers.isNotEmpty) {
      canvasLayers.removeLast();
    }
  }
}
