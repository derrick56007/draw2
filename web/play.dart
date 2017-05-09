part of client;

class Play {
  static Element playCard = querySelector('#play-card');

  static Element playerListCollection =
      querySelector('#player-list-collection');
  static Element drawNextBtn = querySelector('#draw-next-btn');
  static InputElement chatInput = querySelector('#chat-input');
  static Element currentArtist = querySelector('#current-artist');
  static Element currentWord = querySelector('#current-word');
  static Element currentTime = querySelector('#current-time');
  static Element chatList = querySelector('#chat-list');
  static CanvasElement canvas = querySelector('#canvas');
  static CanvasRenderingContext2D ctx = canvas.context2D;

  static init(ClientWebSocket client) {
    var streamSubscriptions = <StreamSubscription<MouseEvent>>[];

    var brush = new Brush();
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

        streamSubscriptions
          ..add(canvas.onMouseDown.listen((MouseEvent e) {
            var rect = canvas.getBoundingClientRect();
            num x = e.page.x - rect.left;
            num y = e.page.y - rect.top;

            brush
              ..pos.x = x
              ..pos.y = y
              ..prevPos.x = x
              ..prevPos.y = y
              ..pressed = true;

            var color = querySelector('#color').text;
            if (color != null && brush.color != color) {
              brush.color = '$color';
              client.send(Message.changeColor, brush.color);
            }

            _drawPoint(x, y, brush.size, brush.color);
            client.send(Message.drawPoint, brush.pos.toJson());

            const brushInterval = const Duration(milliseconds: 25);
            timer?.cancel();
            timer = new Timer.periodic(brushInterval, (_) {
              if (brush.moved) {
                _drawLine(brush.prevPos.x, brush.prevPos.y, brush.pos.x,
                    brush.pos.y, brush.size, brush.color);
                client.send(Message.drawLine, brush.pos.toJson());

                brush
                  ..prevPos.x = brush.pos.x
                  ..prevPos.y = brush.pos.y
                  ..moved = false;
              }
            });
          }))
          ..add(document.onMouseMove.listen((MouseEvent e) {
            if (brush.pressed) {
              var rect = canvas.getBoundingClientRect();

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
          }));
      })
      ..on(Message.setArtist, (String json) {
        currentArtist.text = '$json is drawing';
        currentWord.text = '';
        currentTime.text = '';

        _clearDrawing();
        for (var sub in streamSubscriptions) {
          sub?.cancel();
        }
        streamSubscriptions.clear();

        timer?.cancel();
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
          ..pos.y = pos.y
          ..prevPos.x = pos.x
          ..prevPos.y = pos.y;

        _drawPoint(brush.pos.x, brush.pos.y, brush.size, brush.color);
      })
      ..on(Message.drawLine, (String json) {
        var pos = new Point.fromJson(json);

        brush
          ..prevPos.x = brush.pos.x
          ..prevPos.y = brush.pos.y
          ..pos.x = pos.x
          ..pos.y = pos.y;

        _drawLine(brush.prevPos.x, brush.prevPos.y, brush.pos.x, brush.pos.y,
            brush.size, brush.color);
      })
      ..on(Message.clearDrawing, (_) {
        _clearDrawing();
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

    document.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode != KeyCode.ENTER) return;

      String guess = chatInput.value.trim();

      if (guess.isNotEmpty) {
        client.send(Message.guess, guess);
      }

      chatInput.value = '';
    });

    drawNextBtn.onClick.listen((_) {
      if (drawNextBtn.classes.contains('disabled')) return;

      drawNextBtn.classes.add('disabled');

      client.send(Message.drawNext, '');
    });
  }

  static void show() {
    hideAllCards();
    playCard.style.display = '';
  }

  static void hide() {
    playCard.style.display = 'none';
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

  static void _drawPoint(num x, num y, num size, String color) {
    ctx
      ..beginPath()
      ..arc(x, y, size / 2, 0, 2 * PI)
      ..closePath()
      ..fillStyle = color
      ..fill();
  }

  static void _drawLine(
      num x1, num y1, num x2, num y2, num size, String color) {
    ctx
      ..beginPath()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2)
      ..closePath()
      ..lineWidth = size
      ..strokeStyle = color
      ..lineCap = 'round'
      ..lineJoin = 'round'
      ..stroke();
  }

  static void _clearDrawing() {
    ctx.clearRect(0, 0, 640, 480);
  }
}
