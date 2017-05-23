part of client;

class Play {
  static const canvasWidth = 640;
  static const canvasHeight = 480;
  static const maxChatLength = 20;
  static const brushInterval = const Duration(milliseconds: 25);

  final Element playCard = querySelector('#play-card');
  final Element playerListCollection = querySelector('#player-list-collection');
  final Element canvasLeftLabel = querySelector('#canvas-left-label');
  final Element canvasMiddleLabel = querySelector('#canvas-middle-label');
  final Element canvasRightLabel = querySelector('#canvas-right-label');
  final Element chatList = querySelector('#chat-list');
  final Element artistOptions = querySelector('#artist-options');
  final Element drawNextBtn = querySelector('#draw-next-btn');
  final Element undoBtn = querySelector('#undo-btn');
  final Element clearBtn = querySelector('#clear-btn');

  final InputElement chatInput = querySelector('#chat-input');

  static final CanvasElement canvas = querySelector('#canvas');
  final CanvasRenderingContext2D ctx = canvas.context2D;

  final List<StreamSubscription<MouseEvent>> drawSubs = [];
  final List<StreamSubscription> playSubs = [];

  final ClientWebSocket client;

  final List<CanvasLayer> canvasLayers = [];

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
        querySelector('#color').text = Brush.defaultColor;
        // TODO set default size

        artistOptions.classes
          ..remove('scale-out')
          ..add('scale-in');

        _clearDrawing();

        var brush = new Brush();

        drawSubs.addAll([
          canvas.onMouseDown.listen((MouseEvent e) {
            var rect = canvas.getBoundingClientRect();
            num x = e.page.x - rect.left;
            num y = e.page.y - rect.top;

            brush
              ..pos.x = x
              ..pos.y = y
              ..pressed = true;

            var color = querySelector('#color').text;

            _drawPoint(color, Brush.defaultSize, x, y);

            var drawPoint = new DrawPoint(color, Brush.defaultSize, brush.pos);
            client.send(Message.drawPoint, drawPoint.toJson());

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
              var rect = canvas.getBoundingClientRect();

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

            if (canvasLayers.length > 0) {
              undoBtn.classes.remove('disabled');
              clearBtn.classes.remove('disabled');
            }
          }),
          undoBtn.onClick.listen((_) {
            if (undoBtn.classes.contains('disabled')) return;

            client.send(Message.undoLast);
            _undoLast();
          }),
          clearBtn.onClick.listen((_) {
            client.send(Message.clearDrawing);
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
      ..on(Message.lose, (_) {})
      ..on(Message.setCanvasLeftLabel, (String json) {
        canvasLeftLabel.text = json;
      })
      ..on(Message.setCanvasMiddleLabel, (String json) {
        canvasMiddleLabel.text = json;
      })
      ..on(Message.setCanvasRightLabel, (String json) {
        canvasRightLabel.text = json;
      })
      ..on(Message.clearCanvasLabels, (_) {
        canvasLeftLabel.text = '';
        canvasMiddleLabel.text = '';
        canvasRightLabel.text = '';
      })
      ..on(Message.drawPoint, (String json) {
        var drawPoint = new DrawPoint.fromJson(json);

        _drawPoint(
            drawPoint.color, drawPoint.size, drawPoint.pos.x, drawPoint.pos.y);
      })
      ..on(Message.drawLine, (String json) {
        var pos = new Point.fromJson(json);

        _drawLine(pos.x, pos.y);
      })
      ..on(Message.clearDrawing, (_) {
        _clearDrawing();
      })
      ..on(Message.undoLast, (_) {
        _undoLast();
      })
      ..on(Message.setQueue, (String json) {
        for (var el in playerListCollection.children) {
          var queueNumber = el.querySelectorAll('.queue-number').first;
          queueNumber.text = '';
        }

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

        client.send(Message.drawNext);
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

  _drawPoint(String color, int size, num x, num y) {
    var layer = new CanvasLayer([new Point(x, y)], color, size);
    canvasLayers.add(layer);

    _strokeDrawPoints();
  }

  _drawLine(num x, num y) {
    if (canvasLayers.length > 0) {
      canvasLayers.last.points.add(new Point(x, y));
    }
    _strokeDrawPoints();
  }

  // smooth draw path
  _strokeDrawPoints() {
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    for (var layer in canvasLayers) {
      var p1 = layer.points.first;

      if (layer.points.length == 1) {
        ctx
          ..beginPath()
          ..arc(p1.x, p1.y, layer.brushSize / 2, 0, 2 * PI)
          ..closePath()
          ..fillStyle = layer.brushColor
          ..fill();
      } else if (layer.points.length > 1) {
        var p2 = layer.points[1];

        ctx
          ..beginPath()
          ..moveTo(p1.x, p1.y);

        for (int i = 1; i < layer.points.length - 1; i++) {
          var midPoint = Point.midPoint(p1, p2);

          ctx.quadraticCurveTo(p1.x, p1.y, midPoint.x, midPoint.y);

          p1 = layer.points[i];
          p2 = layer.points[i + 1];
        }

        ctx
          ..lineTo(p1.x, p1.y)
          ..lineWidth = layer.brushSize
          ..strokeStyle = layer.brushColor
          ..lineCap = 'round'
          ..lineJoin = 'round'
          ..stroke();
      }
    }
  }

  _clearDrawing() {
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    canvasLayers.clear();

    undoBtn.classes.add('disabled');
    clearBtn.classes.add('disabled');
  }

  _undoLast() {
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    if (canvasLayers.length > 0) {
      canvasLayers.removeLast();

      _strokeDrawPoints();

      if (canvasLayers.length == 0) {
        undoBtn.classes.add('disabled');
        clearBtn.classes.add('disabled');
      }
    }
  }
}
