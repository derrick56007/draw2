part of client;

class Play {
  static Element playCard = querySelector('#play-card');

  static Element playerListCollection =
      querySelector('#player-list-collection');
  static Element drawNextBtn = querySelector('#draw-next-btn');
  static Element undoBtn = querySelector('#undo-btn');
  static Element clearBtn = querySelector('#clear-btn');
  static InputElement chatInput = querySelector('#chat-input');
  static Element currentArtist = querySelector('#current-artist');
  static Element currentWord = querySelector('#current-word');
  static Element currentTime = querySelector('#current-time');
  static Element chatList = querySelector('#chat-list');
  static CanvasElement mainCanvas = querySelector('#canvas');
  static List<CanvasElement> canvasLayers =
      querySelector('#canvas-layers').children;
  static CanvasRenderingContext2D currentContext;
  static int currentCanvasIndex = -1;
  static const maxCanvasLayers = 5;
  static List<StreamSubscription<MouseEvent>> drawSubs = [];
  static List<StreamSubscription> playSubs = [];

  static const brushInterval = const Duration(milliseconds: 25);

  static ClientWebSocket client;

  static List<Point> drawPoints = [];
  static Brush brush = new Brush();

  static init(ClientWebSocket _client) {
    client = _client;

    Timer timer;

    client
      ..on(Message.guess, (String json) {
        var guess = new Guess.fromJson(json);

        _addToChat(guess.username, guess.guess);
      })
      ..on(Message.existingPlayer, (String json) {
        var existingPlayer = new ExistingPlayer.fromJson(json);

        // TODO add queue number to existing info
        _addPlayer(existingPlayer.username, existingPlayer.score, '');
      })
      ..on(Message.newPlayer, (String name) {
        _addPlayer(name, 0, '');
      })
      ..on(Message.removePlayer, (String name) {
        querySelector('#player-$name')?.remove();
      })
      ..on(Message.setAsArtist, (String word) {
        currentArtist.text = 'You are drawing';
        currentWord.text = word;
        currentTime.text = '';

        _clearDrawing();

        drawSubs
          ..add(querySelector('#canvas-layers')
              .onMouseDown
              .listen((MouseEvent e) {
            var rect = mainCanvas.getBoundingClientRect();
            num x = e.page.x - rect.left;
            num y = e.page.y - rect.top;

            brush
              ..pos.x = x
              ..pos.y = y
//              ..prevPos.x = x
//              ..prevPos.y = y
              ..pressed = true;

            var color = querySelector('#color').text;
            if (color != null && brush.color != color) {
              brush.color = '$color';
              client.send(Message.changeColor, brush.color);
            }

            _drawPoint(x, y);
            client.send(Message.drawPoint, brush.pos.toJson());

            timer?.cancel();
            timer = new Timer.periodic(brushInterval, (_) {
              if (brush.moved) {
                _drawLine(brush.pos.x, brush.pos.y);
                client.send(Message.drawLine, brush.pos.toJson());

                brush
//                  ..prevPos.x = brush.pos.x
//                  ..prevPos.y = brush.pos.y
                  ..moved = false;
              }
            });
          }))
          ..add(document.onMouseMove.listen((MouseEvent e) {
            if (brush.pressed) {
              var rect = mainCanvas.getBoundingClientRect();

              brush
                ..pos.x = e.page.x - rect.left
                ..pos.y = e.page.y - rect.top
                ..moved = true;
            }
          }))
          ..add(document.onMouseUp.listen((MouseEvent e) {
            brush
              ..pressed = false
              ..moved = false;

            timer?.cancel();
          }))
          ..add(undoBtn.onClick.listen((_) {
            if (undoBtn.classes.contains('disabled')) return;

            client.send(Message.undoLast, '');
            _undoLast();
          }))
          ..add(clearBtn.onClick.listen((_) {
            client.send(Message.clearDrawing, '');
            _clearDrawing();
          }));
      })
      ..on(Message.setArtist, (String json) {
        currentArtist.text = '$json is drawing';
        currentWord.text = '';
        currentTime.text = '';

        _clearDrawing();
        for (var sub in drawSubs) {
          sub?.cancel();
        }
        drawSubs.clear();

        timer?.cancel();

        clearBtn.classes.add('disabled');
        undoBtn.classes.add('disabled');
      })
      ..on(Message.win, (String json) {
        currentArtist.text = '';
        currentWord.text = json;
        currentTime.text = '';
      })
      ..on(Message.lose, (String json) {
        currentWord.text = json;
      })
      ..on(Message.timerUpdate, (String json) {
        currentTime.text = json;
      })
      ..on(Message.drawPoint, (String json) {
        var pos = new Point.fromJson(json);

        brush
          ..pos.x = pos.x
          ..pos.y = pos.y;

        _drawPoint(brush.pos.x, brush.pos.y);
      })
      ..on(Message.drawLine, (String json) {
        var pos = new Point.fromJson(json);

        brush
          ..pos.x = pos.x
          ..pos.y = pos.y;

        _drawLine(brush.pos.x, brush.pos.y);
      })
      ..on(Message.clearDrawing, (_) {
        _clearDrawing();
      })
      ..on(Message.undoLast, (_) {
        _undoLast();
      })
      ..on(Message.changeColor, (String json) {
        brush.color = json;
      })
      ..on(Message.changeSize, (String json) {
        brush.size = int.parse(json);
      })
      ..on(Message.setQueue, (String json) {
        for (var el in playerListCollection.children) {
          var queueNumber = el.querySelectorAll('.queue-number').first;
          queueNumber.text = '';
        }

        // TODO make separate class for queueInfo
        var queue = JSON.decode(json) as List;

        for (var player in queue) {
          var name = player[0];
          querySelector('#player-$name-queue-number')?.text = '${player[1]}';
        }
      })
      ..on(Message.setPlayerOrder, (String json) {
        var order = JSON.decode(json) as List;
        for (var name in order.reversed) {
          var el = querySelector('#player-$name');

          if (el == null) continue;

          el.remove();
          playerListCollection.children.insert(0, el);
        }
      })
      ..on(Message.enableDrawNext, (_) {
        drawNextBtn.classes.remove('disabled');
      })
      ..on(Message.updatePlayerScore, (String json) {
        var playerScore = JSON.decode(json) as List;
        var name = playerScore[0];
        var score = playerScore[1];

        querySelector('#player-$name-score')?.text = '$score';
      });
  }

  static void show() {
    hideAllCards();
    playCard.style.display = '';

    playSubs
      ..add(document.onKeyPress.listen((KeyboardEvent e) {
        if (e.keyCode != KeyCode.ENTER) return;

        String guess = chatInput.value.trim();

        if (guess.isNotEmpty) {
          client.send(Message.guess, guess);
        }

        chatInput.value = '';
      }))
      ..add(drawNextBtn.onClick.listen((_) {
        if (drawNextBtn.classes.contains('disabled')) return;

        drawNextBtn.classes.add('disabled');

        client.send(Message.drawNext, '');
      }));
  }

  static void hide() {
    playCard.style.display = 'none';

    for (var sub in playSubs) {
      sub?.cancel();
    }
    playSubs.clear();
  }

  static void _addPlayer(String name, int score, var queueNumber) {
    var el = new Element.html('''
      <a id="player-$name" class="collection-item player-item">
        <span id="player-$name-queue-number" class="queue-number">$queueNumber</span>
        <span id="player-$name-score" class="player-score">$score</span>
        $name
      </a>''');

    playerListCollection.children.add(el);
  }

  static void _addToChat(String username, String text) {
    var el = new Element.html('''
      <a class="collection-item chat-item">
        <div class="chat-username">$username</div>
        <div class="chat-text">$text</div>
      </a>''');

    chatList
      ..children.add(el)
      ..scrollTop = chatList.scrollHeight;

    if (chatList.children.length < 200) return;

    chatList.children.removeAt(0);
  }

  static void _drawPoint(num x, num y) {
    nextCanvasLayer();

    drawPoints.add(new Point(x, y));

    _strokeDrawPoints();
  }

  static void _drawLine(num x, num y) {
    drawPoints.add(new Point(x, y));

    _strokeDrawPoints();
  }

  // smooth draw path
  static void _strokeDrawPoints() {
    currentContext.clearRect(0, 0, 640, 480);

    var p1 = drawPoints.first;

    if (drawPoints.length == 1) {
      currentContext
        ..beginPath()
        ..arc(p1.x, p1.y, brush.size / 2, 0, 2 * PI)
        ..closePath()
        ..fillStyle = brush.color
        ..fill();
    } else if (drawPoints.length > 1) {
      var p2 = drawPoints[1];

      currentContext
        ..beginPath()
        ..moveTo(p1.x, p1.y);

      for (int i = 1; i < drawPoints.length - 1; i++) {
        var midPoint = Point.midPoint(p1, p2);

        currentContext.quadraticCurveTo(p1.x, p1.y, midPoint.x, midPoint.y);

        p1 = drawPoints[i];
        p2 = drawPoints[i + 1];
      }

      currentContext
        ..lineTo(p1.x, p1.y)
        ..lineWidth = brush.size
        ..strokeStyle = brush.color
        ..lineCap = 'round'
        ..lineJoin = 'round'
        ..stroke();
    }
  }

  static void _clearDrawing() {
    mainCanvas.context2D.clearRect(0, 0, 640, 480);

    for (CanvasElement layer in canvasLayers) {
      layer.context2D.clearRect(0, 0, 640, 480);
    }

    currentCanvasIndex = 0;

    undoBtn.classes.add('disabled');
    clearBtn.classes.add('disabled');
  }

  static void _undoLast() {
    currentContext.clearRect(0, 0, 640, 480);

    if (currentCanvasIndex > 0) {
      currentCanvasIndex--;

      var prevLayer = canvasLayers[currentCanvasIndex % maxCanvasLayers];

      currentContext = prevLayer.context2D;
    }

    if (currentCanvasIndex == 0) {
      undoBtn.classes.add('disabled');
    }
  }

  static void nextCanvasLayer() {
    undoBtn.classes.remove('disabled');
    clearBtn.classes.remove('disabled');

    currentCanvasIndex++;

    var nextLayer = canvasLayers[currentCanvasIndex % maxCanvasLayers]
      ..style.zIndex = '${currentCanvasIndex + 1}';

    currentContext = nextLayer.context2D;

    if (currentCanvasIndex >= maxCanvasLayers) {
      mainCanvas.context2D.drawImage(nextLayer, 0, 0);
      currentContext.clearRect(0, 0, 640, 480);
    }

    drawPoints.clear();
  }
}
