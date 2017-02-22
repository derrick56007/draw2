// Copyright (c) 2017, derri. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library client;

import 'dart:math' hide Point;
import 'dart:async';
import 'dart:html' hide Point;
import 'dart:js';

//import 'package:force/force_browser.dart';

//import 'common/common.dart';
//
//Element loginCard = querySelector('#login-card');
//Element lobbyListCard = querySelector('#lobby-list-card');
//Element lobbyListCollection = querySelector('#lobby-list-collection');
//Element createLobbyCard = querySelector('#create-lobby-card');
//Element passwordCard = querySelector('#password-card');
//Element playCard = querySelector('#play-card');
//Element playerListCollection = querySelector('#player-list-collection');
//InputElement chatInput = querySelector('#chat-input');
//Element currentArtist = querySelector('#current-artist');
//Element currentWord = querySelector('#current-word');
//Element currentTime = querySelector('#current-time');
//Element chatList = querySelector('#chat-list');
//CanvasElement canvas = querySelector('#canvas');
//CanvasRenderingContext2D ctx = canvas.context2D;

void main() {
  WebSocket webSocket = new WebSocket('ws://localhost:8080/ws');
  webSocket
    ..onOpen.listen((Event e) {
      print('connected');
    })
    ..onMessage.listen((MessageEvent e) {
      print(e.data);
    })
    ..onClose.listen((Event e) {
      print('disconnected');
    })
    ..onError.listen((Event e) {
      print('error ${e.type}');
    });

  return;
  ForceClient client = new ForceClient();
  client.connect();

  bool connected = false;

  LoginInfo loginInfo = new LoginInfo();

  var streamSubscriptions = <StreamSubscription<MouseEvent>>[];

  var brush = new Brush();
  Timer timer;

  client
    ..onConnected.listen((_) {
      toast('Connected');
      connected = true;

      if (loginInfo.username != null && loginInfo.username.isNotEmpty) {
        // TODO login
      }
    })
    ..onDisconnected.listen((_) {
      toast('Disconnected');
      connected = false;

      if (loginCard.style.display == 'none') {
//        loginState();
      }
    })
    ..on(Message.toast, (mp, _) {
      toast(mp.json);
    })
    ..on(Message.loginSuccesful, (mp, _) {
      toast('Logged in');

      loginInfo.username = mp.json;

      client.initProfileInfo({'name': loginInfo.username});

      lobbyListState();
      client.send(Message.requestLobbyList, '');
    })
    ..on(Message.lobbyOpened, (mp, _$) {
      querySelector('#lobby-list-progress')?.remove();

      LobbyInfo lobbyInfo = new LobbyInfo.fromJson(mp.json);

      var el = new Element.html('''
          <a id="lobby-${lobbyInfo.name}" class="collection-item lobby-list-item">
            <span class="badge">${lobbyInfo.numberOfPlayers}/${lobbyInfo.maxPlayers}</span>
            ${lobbyInfo.name}
          </a>''');

      el.onClick.listen((_) {
        loginInfo.lobbyName = lobbyInfo.name;

        if (lobbyInfo.hasPassword) {
          passwordState();
        } else {
          client.send(Message.enterLobby, loginInfo.toJson());
        }
      });

      lobbyListCollection.children.add(el);
    })
    ..on(Message.lobbyClosed, (mp, _) {
      querySelector('#lobby-${mp.json}')?.remove();

      if (lobbyListCollection.children.isEmpty) {
        lobbyListState();
        client.send(Message.requestLobbyList, '');
      }
    })
    ..on(Message.createLobbySuccessful, (_, _$) {
      client.send(Message.enterLobby, loginInfo.toJson());
    })
    ..on(Message.enterLobbySuccessful, (mp, _) {
      String lobbyName = mp.json;

      loginInfo.lobbyName = lobbyName;

      client.initProfileInfo({'name': loginInfo.username, 'lobby': lobbyName});

      toast('Joined lobby $lobbyName');

      playState();
    })
    ..on(Message.enterLobbyFailure, (_, _$) {
      loginInfo
        ..lobbyName = ''
        ..password = '';

      lobbyListState();
      client.send(Message.requestLobbyList, '');
    })
    ..on(Message.guess, (mp, _) {
      var guess = new Guess.fromJson(mp.json);

      addToChat(guess.username, guess.guess);
    })
    ..on(Message.existingPlayer, (mp, _) {
      var existingPlayer = new ExistingPlayer.fromJson(mp.json);

      var el = new Element.html('''
        <a id="player-${existingPlayer.username}" class="collection-item player-item">
          <span class="badge">${existingPlayer.score}</span>
          ${existingPlayer.username}
        </a>''');

      playerListCollection.children.add(el);
    })
    ..on(Message.newPlayer, (mp, _) {
      var el = new Element.html('''
        <a id="player-${mp.json}" class="collection-item player-item">
          <span class="badge">0</span>
          ${mp.json}
        </a>''');

      playerListCollection.children.add(el);

      print('added new player');
    })
    ..on(Message.removePlayer, (mp, _) {
      querySelector('#player-${mp.json}')?.remove();
    })
    ..on(Message.setAsArtist, (mp, _) {
      currentArtist.text = loginInfo.username;
      currentWord.text = mp.json;
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
          client.send(Message.drawPoint, brush.pos.toJson());

          const brushInterval = const Duration(milliseconds: 25);
          timer?.cancel();
          timer = new Timer.periodic(brushInterval, (_) {
            if (brush.moved) {
              drawLine(brush.prevPos.x, brush.prevPos.y, brush.pos.x,
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
    ..on(Message.setArtist, (mp, _) {
      currentArtist.text = mp.json;
      currentWord.text = '';
      currentTime.text = '';

      clearDrawing();
      for (var sub in streamSubscriptions) {
        sub?.cancel();
      }
      streamSubscriptions.clear();

      timer?.cancel();
    })
    ..on(Message.win, (mp, _) {
      currentArtist.text = '';
      currentWord.text = mp.json;
      currentTime.text = '';
    })
    ..on(Message.lose, (mp, _) {
      currentWord.text = mp.json;
    })
    ..on(Message.timerUpdate, (mp, _) {
      currentTime.text = mp.json;
    })
    ..on(Message.drawPoint, (mp, _) {
      var pos = new Point.fromJson(mp.json);

      brush
        ..pos.x = pos.x
        ..pos.y = pos.y
        ..prevPos.x = pos.x
        ..prevPos.y = pos.y;

      drawPoint(brush.pos.x, brush.pos.y, brush.size, brush.color);
    })
    ..on(Message.drawLine, (mp, _) {
      var pos = new Point.fromJson(mp.json);

      brush
        ..prevPos.x = brush.pos.x
        ..prevPos.y = brush.pos.y
        ..pos.x = pos.x
        ..pos.y = pos.y;

      drawLine(brush.prevPos.x, brush.prevPos.y, brush.pos.x, brush.pos.y,
          brush.size, brush.color);
    })
    ..on(Message.clearDrawing, (_, _$) {
      clearDrawing();
    })
    ..on(Message.changeColor, (mp, _) {
      brush.color = mp.json;
    })
    ..on(Message.changeSize, (mp, _) {
      brush.size = int.parse(mp.json);
    });

  querySelector('#login-btn').onClick.listen((_) {
    if (!connected) {
      toast('Not connected');
      return;
    }

    InputElement usernameElement = querySelector('#username');
    String username = usernameElement.value.trim();

    if (username.isEmpty) {
      toast('Not a valid username');
      return;
    }

    client.send(Message.login, username);
  });

  querySelector('#create-lobby-card-btn').onClick.listen((_) {
    createLobbyState();
  });

  querySelector('#create-lobby-btn').onClick.listen((_) {
    if (!connected) {
      toast('Not connected');
      return;
    }

    var lobbyNameElement = querySelector('#lobby-name') as InputElement;
    String lobbyName = lobbyNameElement.value.trim();

    if (lobbyName.isEmpty) {
      toast('Not a valid lobby name');
      return;
    }

    var passwordElement =
        querySelector('#create-lobby-password') as InputElement;
    String password = passwordElement.value.trim();

    var selectNumPlayersEl =
        querySelector('#number-of-players') as SelectElement;
    int maxPlayers = int.parse(selectNumPlayersEl.value);

    var timerElement = querySelector('#timer-switch') as InputElement;
    bool hasTimer = timerElement.checked;

    var lobbyInfo = new CreateLobbyInfo()
      ..name = lobbyName
      ..password = password
      ..hasTimer = hasTimer
      ..maxPlayers = maxPlayers;

    loginInfo
      ..lobbyName = lobbyName
      ..password = password;

    client.send(Message.createLobby, lobbyInfo.toJson());
  });

  querySelector('#back-to-lobbies-list-btn').onClick.listen((_) {
    lobbyListState();
    client.send(Message.requestLobbyList, '');
  });

  querySelector('#enter-lobby-password-btn').onClick.listen((_) {
    var el = querySelector('#enter-lobby-password') as InputElement;
    var input = el.value.trim();

    if (input.isEmpty) {
      toast('Invalid input');

      return;
    }

    loginInfo.password = input;

    client.send(Message.enterLobby, loginInfo.toJson());
  });

  document.onKeyPress.listen((KeyboardEvent e) {
    if (e.keyCode != KeyCode.ENTER) return;

    if (playCard.style.display.isEmpty) {
      String guess = chatInput.value.trim();

      if (guess.isNotEmpty &&
          loginInfo.username != null &&
          loginInfo.username.isNotEmpty) {
        client.send(Message.guess, guess);
      }

      chatInput.value = '';
    }
  });
}
//
//void toast(String message, [int duration = 2500]) {
//  print(message);
//  context['Materialize'].callMethod('toast', [message, duration]);
//}
//
//void loginState() {
//  loginCard.style.display = '';
//  passwordCard.style.display = 'none';
//  lobbyListCard.style.display = 'none';
//  createLobbyCard.style.display = 'none';
//  playCard.style.display = 'none';
//}
//
//void lobbyListState() {
//  loginCard.style.display = 'none';
//  passwordCard.style.display = 'none';
//  lobbyListCard.style.display = '';
//  createLobbyCard.style.display = 'none';
//  playCard.style.display = 'none';
//
//  lobbyListCollection.children.clear();
//
//  var progress = new Element.html('''
//  <div id="lobby-list-progress" class="progress">
//      <div class="indeterminate"></div>
//  </div>''');
//
//  lobbyListCollection.children.add(progress);
//}
//
//void createLobbyState() {
//  loginCard.style.display = 'none';
//  passwordCard.style.display = 'none';
//  lobbyListCard.style.display = 'none';
//  createLobbyCard.style.display = '';
//  playCard.style.display = 'none';
//}
//
//void playState() {
//  loginCard.style.display = 'none';
//  passwordCard.style.display = 'none';
//  lobbyListCard.style.display = 'none';
//  createLobbyCard.style.display = 'none';
//  playCard.style.display = '';
//}
//
//void passwordState() {
//  loginCard.style.display = 'none';
//  passwordCard.style.display = '';
//  lobbyListCard.style.display = 'none';
//  createLobbyCard.style.display = 'none';
//  playCard.style.display = 'none';
//}
//
//void addToChat(String username, String text) {
//  var el = new Element.html('''
//    <a class="collection-item chat-item">
//      <div class="chat-username">$username</div>
//      <div class="chat-text">$text</div>
//     </a>''');
//
//  chatList
//    ..children.add(el)
//    ..scrollTop = chatList.scrollHeight;
//
//  if (chatList.children.length < 200) return;
//
//  chatList.children.removeAt(0);
//}
//
//void drawPoint(num x, num y, num size, String color) {
//  ctx
//    ..beginPath()
//    ..arc(x, y, size / 2, 0, 2 * PI)
//    ..closePath()
//    ..fillStyle = color
//    ..fill();
//}
//
//void drawLine(num x1, num y1, num x2, num y2, num size, String color) {
//  ctx
//    ..beginPath()
//    ..moveTo(x1, y1)
//    ..lineTo(x2, y2)
//    ..closePath()
//    ..lineWidth = size
//    ..strokeStyle = color
//    ..lineCap = 'round'
//    ..lineJoin = 'round'
//    ..stroke();
//}
//
//void clearDrawing() {
//  ctx.clearRect(0, 0, 640, 480);
//}
