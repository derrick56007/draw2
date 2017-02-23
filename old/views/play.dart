import '../client_websocket.dart';
import '../common/brush.dart';
import '../common/existing_player.dart';
import '../common/guess.dart';
import '../common/login_info.dart';
import '../common/message.dart';
import '../common/point.dart';
import '../cookie.dart';
import 'dart:async';
import 'dart:html' hide Point;
import 'dart:math' hide Point;

Element playerListCollection = querySelector('#player-list-collection');
InputElement chatInput = querySelector('#chat-input');
Element currentArtist = querySelector('#current-artist');
Element currentWord = querySelector('#current-word');
Element currentTime = querySelector('#current-time');
Element chatList = querySelector('#chat-list');
CanvasElement canvas = querySelector('#canvas');
CanvasRenderingContext2D ctx = canvas.context2D;

main() async {
  var client = new ClientWebSocket();
  await client.start();

  var loginInfo = new LoginInfo.fromJson(
      Cookie.get('loginInfo', ifNull: new LoginInfo().toJson()));
  var streamSubscriptions = <StreamSubscription<MouseEvent>>[];

  var brush = new Brush();
  Timer timer;

  client
    ..onOpen.listen((_) {
      print('sending handshake');

      client.send(Message.handshake, loginInfo.toJson());
    })
    ..on(Message.handshakeSuccessful, (_) {
      print('handshake successful');
    })
    ..on(Message.guess, (String json) {
      var guess = new Guess.fromJson(json);

      addToChat(guess.username, guess.guess);
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
      currentArtist.text = loginInfo.username;
      currentWord.text = json;
      currentTime.text = '';

      clearDrawing();

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

          drawPoint(x, y, brush.size, brush.color);
          client.send(Message._drawPoint, brush.pos.toJson());

          const brushInterval = const Duration(milliseconds: 25);
          timer?.cancel();
          timer = new Timer.periodic(brushInterval, (_) {
            if (brush.moved) {
              drawLine(brush.prevPos.x, brush.prevPos.y, brush.pos.x,
                  brush.pos.y, brush.size, brush.color);
              client.send(Message._drawLine, brush.pos.toJson());

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

      clearDrawing();
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
    ..on(Message._drawPoint, (String json) {
      var pos = new Point.fromJson(json);

      brush
        ..pos.x = pos.x
        ..pos.y = pos.y
        ..prevPos.x = pos.x
        ..prevPos.y = pos.y;

      drawPoint(brush.pos.x, brush.pos.y, brush.size, brush.color);
    })
    ..on(Message._drawLine, (String json) {
      var pos = new Point.fromJson(json);

      brush
        ..prevPos.x = brush.pos.x
        ..prevPos.y = brush.pos.y
        ..pos.x = pos.x
        ..pos.y = pos.y;

      drawLine(brush.prevPos.x, brush.prevPos.y, brush.pos.x, brush.pos.y,
          brush.size, brush.color);
    })
    ..on(Message._clearDrawing, (_) {
      clearDrawing();
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

    if (guess.isNotEmpty &&
        loginInfo.username != null &&
        loginInfo.username.isNotEmpty) {
      client.send(Message.guess, guess);
    }

    chatInput.value = '';
  });
}

void addToChat(String username, String text) {
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

void drawPoint(num x, num y, num size, String color) {
  ctx
    ..beginPath()
    ..arc(x, y, size / 2, 0, 2 * PI)
    ..closePath()
    ..fillStyle = color
    ..fill();
}

void drawLine(num x1, num y1, num x2, num y2, num size, String color) {
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

void clearDrawing() {
  ctx.clearRect(0, 0, 640, 480);
}
