part of client;

class Play {
  static Element playerListCollection =
      querySelector('#player-list-collection');
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

        var el = new Element.html('''
        <a id="player-${existingPlayer.username}" class="collection-item player-item">
          <span class="badge">${existingPlayer.score}</span>
          ${existingPlayer.username}
        </a>''');

        playerListCollection.children.add(el);
      })
      ..on(Message.newPlayer, (String json) {
        var el = new Element.html('''
        <a id="player-${json}" class="collection-item player-item">
          <span class="badge">0</span>
          ${json}
        </a>''');

        playerListCollection.children.add(el);

        print('added new player');
      })
      ..on(Message.removePlayer, (String json) {
        querySelector('#player-${json}')?.remove();
      })
      ..on(Message.setAsArtist, (String json) {
        currentArtist.text = myInfo.username;
        currentWord.text = json;
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
        currentArtist.text = json;
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
      });

    document.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode != KeyCode.ENTER) return;

      String guess = chatInput.value.trim();

      if (guess.isNotEmpty) {
        client.send(Message.guess, guess);
      }

      chatInput.value = '';
    });
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
