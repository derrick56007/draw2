part of client;

class Play {
  static const maxCanvasLayers = 5;
  static const canvasWidth = 640;
  static const canvasHeight = 480;
  static const maxChatLength = 200;
  static const brushInterval = const Duration(milliseconds: 25);

  Element playCard = querySelector('#play-card');
  Element playerListCollection = querySelector('#player-list-collection');
  Element canvasLeftLabel = querySelector('#canvas-left-label');
  Element canvasMiddleLabel = querySelector('#canvas-middle-label');
  Element canvasRightLabel = querySelector('#canvas-right-label');
  Element chatList = querySelector('#chat-list');
  Element artistOptions = querySelector('#artist-options');
  Element drawNextBtn = querySelector('#draw-next-btn');
  Element undoBtn = querySelector('#undo-btn');
  Element clearBtn = querySelector('#clear-btn');

  InputElement chatInput = querySelector('#chat-input');
  CanvasElement mainCanvas = querySelector('#canvas');
  CanvasRenderingContext2D currentContext;

  int currentCanvasIndex = -1;

  List<CanvasElement> canvasLayers = querySelector('#canvas-layers').children;
  List<StreamSubscription<MouseEvent>> drawSubs = [];
  List<StreamSubscription> playSubs = [];
  List<Point> drawPoints = [];

  ClientWebSocket client;

  Brush brush = new Brush();

  Play(this.client) {
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
      ..on(Message.setAsArtist, (_) {
        artistOptions.classes
          ..remove('scale-out')
          ..add('scale-in');

        _clearDrawing();

        drawSubs.addAll([
          querySelector('#canvas-layers').onMouseDown.listen((MouseEvent e) {
            var rect = mainCanvas.getBoundingClientRect();
            num x = e.page.x - rect.left;
            num y = e.page.y - rect.top;

            brush
              ..pos.x = x
              ..pos.y = y
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

                brush.moved = false;
              }
            });
          }),
          document.onMouseMove.listen((MouseEvent e) {
            if (brush.pressed) {
              var rect = mainCanvas.getBoundingClientRect();

              brush
                ..pos.x = e.page.x - rect.left
                ..pos.y = e.page.y - rect.top
                ..moved = true;
            }
          }),
          document.onMouseUp.listen((MouseEvent e) {
            brush
              ..pressed = false
              ..moved = false;

            timer?.cancel();
          }),
          undoBtn.onClick.listen((_) {
            if (undoBtn.classes.contains('disabled')) return;

            client.send(Message.undoLast, '');
            _undoLast();
          }),
          clearBtn.onClick.listen((_) {
            client.send(Message.clearDrawing, '');
            _clearDrawing();
          })
        ]);
      })
      ..on(Message.setArtist, (_) {
        artistOptions.classes
          ..remove('scale-in')
          ..add('scale-out');

        _clearDrawing();
        for (var sub in drawSubs) {
          sub?.cancel();
        }
        drawSubs.clear();

        timer?.cancel();

        clearBtn.classes.add('disabled');
        undoBtn.classes.add('disabled');
      })
      ..on(Message.win, (_) {})
      ..on(Message.lose, (String json) {})
      ..on(Message.setCanvasLeftLabel, (String json) {
        canvasLeftLabel.text = json;
      })
      ..on(Message.setCanvasMiddleLabel, (String json) {
        canvasMiddleLabel.text = json;
      })
      ..on(Message.setCanvasRightLabel, (String json) {
        canvasRightLabel.text = json;
      })
      ..on(Message.clearCanvasLabels, (String json) {
        canvasLeftLabel.text = '';
        canvasMiddleLabel.text = '';
        canvasRightLabel.text = '';
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

  show() {
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

  hide() {
    playCard.style.display = 'none';

    for (var sub in playSubs) {
      sub?.cancel();
    }
    playSubs.clear();
  }

  _addPlayer(String name, int score, var queueNumber) {
    var el = new Element.html('''
      <a id="player-$name" class="collection-item player-item">
        <span id="player-$name-queue-number" class="queue-number">$queueNumber</span>
        <span id="player-$name-score" class="player-score">$score</span>
        $name
      </a>''');

    playerListCollection.children.add(el);
  }

  _addToChat(String username, String text) {
    var el = new Element.html('''
      <a class="collection-item chat-item">
        <div class="chat-username">$username</div>
        <div class="chat-text">$text</div>
      </a>''');

    chatList
      ..children.add(el)
      ..scrollTop = chatList.scrollHeight;

    if (chatList.children.length < maxChatLength) return;

    chatList.children.removeAt(0);
  }

  _drawPoint(num x, num y) {
    nextCanvasLayer();

    drawPoints.add(new Point(x, y));

    _strokeDrawPoints();
  }

  _drawLine(num x, num y) {
    drawPoints.add(new Point(x, y));

    _strokeDrawPoints();
  }

  // smooth draw path
  _strokeDrawPoints() {
    currentContext.clearRect(0, 0, canvasWidth, canvasHeight);

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

  _clearDrawing() {
    mainCanvas.context2D.clearRect(0, 0, canvasWidth, canvasHeight);

    for (CanvasElement layer in canvasLayers) {
      layer.context2D.clearRect(0, 0, canvasWidth, canvasHeight);
    }

    currentCanvasIndex = 0;

    undoBtn.classes.add('disabled');
    clearBtn.classes.add('disabled');
  }

  _undoLast() {
    currentContext.clearRect(0, 0, canvasWidth, canvasHeight);

    if (currentCanvasIndex > 0) {
      currentCanvasIndex--;

      var prevLayer = canvasLayers[currentCanvasIndex % maxCanvasLayers];

      currentContext = prevLayer.context2D;
    }

    if (currentCanvasIndex == 0) {
      undoBtn.classes.add('disabled');
    }
  }

  nextCanvasLayer() {
    undoBtn.classes.remove('disabled');
    clearBtn.classes.remove('disabled');

    currentCanvasIndex++;

    var nextLayer = canvasLayers[currentCanvasIndex % maxCanvasLayers]..style.zIndex = '${currentCanvasIndex + 1}';

    currentContext = nextLayer.context2D;

    if (currentCanvasIndex >= maxCanvasLayers) {
      mainCanvas.context2D.drawImage(nextLayer, 0, 0);
      currentContext.clearRect(0, 0, canvasWidth, canvasHeight);
    }

    drawPoints.clear();
  }
}
