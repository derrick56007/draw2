part of server;

class Game {
  static const nextRoundDelay = const Duration(seconds: 10);
  static const maxGameTime = const Duration(minutes: 5);
  static const timerTickInterval = const Duration(seconds: 1);
  static const maxChatLength = 20;
  static const defaultBrushColor = '#000000';
  static const defaultBrushSize = 5;
  static const similarityThreshold = .75;

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

    currentArtist.send(MessageType.enableDrawNext);
    currentArtist = null;
    currentWord = null;

    if (artistQueue.isEmpty) {
      lobby.sendToAll(MessageType.setCanvasRightLabel, val: 'Click draw next!');
    } else {
      nextArtist();
    }
  }

  nextArtist() {
    startTimer(nextRoundDelay, (Duration elapsed) {
      lobby.sendToAll(MessageType.setCanvasRightLabel,
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

      final currentArtistName =
          LoginManager.shared.usernameFromSocket(currentArtist);

      currentArtist
        ..send(MessageType.clearCanvasLabels)
        ..send(MessageType.setCanvasLeftLabel, 'You are drawing')
        ..send(MessageType.setCanvasMiddleLabel, currentWord)
        ..send(MessageType.setAsArtist);

      lobby
        ..sendToAll(MessageType.clearCanvasLabels,
            excludedSocket: currentArtist)
        ..sendToAll(MessageType.setCanvasLeftLabel,
            val: '$currentArtistName is drawing', excludedSocket: currentArtist)
        ..sendToAll(MessageType.setArtist, excludedSocket: currentArtist);

      if (!hasTimer) return;

      startTimer(maxGameTime, (Duration elapsed) {
        String twoDigits(int n) {
          if (n >= 10) return '$n';
          return '0$n';
        }

        final twoDigitMinutes =
            twoDigits(maxGameTime.inMinutes - elapsed.inMinutes);
        final twoDigitSeconds = twoDigits(
            (maxGameTime.inSeconds - elapsed.inSeconds)
                .remainder(Duration.SECONDS_PER_MINUTE));

        lobby.sendToAll(MessageType.setCanvasRightLabel,
            val: 'Time left $twoDigitMinutes:$twoDigitSeconds');
      }, () => onLose(currentWord));
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

    lobby.sendToAll(MessageType.guess, val: guess.toJson());

    ////////////// check for win //////////////////

    if (socket == currentArtist) return;

    if (currentWord == null) return;

    // check for match
    if (guess.guess.trim().toLowerCase() == currentWord.trim().toLowerCase()) {
      onWin(socket, guess.username, currentWord);
    } else {
      // check similarity
      final similarity = WordSimilarity.similarity(guess.guess, currentWord);

      if (similarity >= similarityThreshold) {
        final serverMsg =
            new Guess('Server', '${guess.username}\'s guess was close!');

        lobby.sendToAll(MessageType.guess, val: serverMsg.toJson());
      }
    }
  }

  onWin(ServerWebSocket socket, String username, String word) {
    // TODO point system
    scores[socket] += 1;

    lobby
      ..sendToAll(MessageType.clearCanvasLabels)
      ..sendToAll(MessageType.setCanvasMiddleLabel,
          val: '$username guessed \"$word\" correctly!')
      ..sendToAll(MessageType.win)
      ..sendToAll(MessageType.updatePlayerScore,
          val: JSON.encode([username, scores[socket]]));

    removeArtist();
  }

  onLose(String word) {
    lobby
      ..sendToAll(MessageType.lose)
      ..sendToAll(MessageType.setCanvasMiddleLabel,
          val: 'The word was \"$currentWord\"');

    removeArtist();
  }

  startTimer(Duration duration, Function repeating(Duration elapsed),
      Function onFinish()) {
    timer?.cancel();

    stopwatch
      ..reset()
      ..start();

    timer = new Timer.periodic(timerTickInterval, (_) {
      if (stopwatch.elapsedMilliseconds > duration.inMilliseconds) {
        timer?.cancel();
        stopwatch.stop();

        onFinish();
      } else {
        repeating(stopwatch.elapsed);
      }
    });
  }

  drawPoint(String json) {
    final drawPoint = new DrawPoint.fromJson(json);

    final layer =
        new BrushLayer([drawPoint.pos], drawPoint.color, drawPoint.size);

    canvasLayers.add(layer);
  }

  drawLine(String json) {
    if (canvasLayers.isNotEmpty && canvasLayers.last is BrushLayer) {
      final point = new Point.fromJson(json);

      (canvasLayers.last as BrushLayer).points.add(point);
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

  fill(String json) {
    final fillLayer = new FillLayer.fromJson(json);

    canvasLayers.add(fillLayer);
  }
}
