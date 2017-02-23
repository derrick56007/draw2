library client;

import 'dart:async';
import 'dart:html' hide Point;
import 'dart:math' hide Point;

//import 'package:css_animation/css_animation.dart';

import 'common/brush.dart';
import 'common/create_lobby_info.dart';
import 'common/existing_player.dart';
import 'common/guess.dart';
import 'common/lobby_info.dart';
import 'common/login_info.dart';
import 'common/message.dart';
import 'common/point.dart';

import 'client_websocket.dart';
import 'toast.dart';

part 'create.dart';
part 'lobbies.dart';
part 'login.dart';
part 'play.dart';

class Info {
  String username, lobbyName;

  Info() {}
}

var myInfo = new Info();

main() async {
  var client = new ClientWebSocket();
  await client.start();

  Login.init(client);
  Lobbies.init(client);
  Create.init(client);
  Play.init(client);

  changeState('login-card');
}

changeState(String elementName) {
  var els = <Element>[
    querySelector('#login-card'),
    querySelector('#play-card'),
    querySelector('#password-card'),
    querySelector('#lobby-list-card'),
    querySelector('#create-lobby-card')
  ];

  for (var el in els) {
    if (el.id != elementName) {
      el.style.display = 'none';
    }
  }

  querySelector('#$elementName').style.display = '';
}
