library client;

import 'dart:async';
import 'dart:convert';
import 'dart:html' hide Point;
import 'dart:math' hide Point;

import 'common/canvas_layer.dart';
import 'common/create_lobby_info.dart';
import 'common/draw_point.dart';
import 'common/draw_regex.dart';
import 'common/existing_player.dart';
import 'common/guess.dart';
import 'common/lobby_info.dart';
import 'common/login_info.dart';
import 'common/message.dart';
import 'common/point.dart';

import 'brush.dart';
import 'client_websocket.dart';
import 'toast.dart';

part 'create.dart';
part 'lobbies.dart';
part 'login.dart';
part 'password.dart';
part 'play.dart';

var login, lobbies, create, play, password;

main() async {
  var client = new ClientWebSocket();
  await client.start();

  login = new Login(client);
  lobbies = new Lobbies(client);
  create = new Create(client);
  play = new Play(client);
  password = new Password(client);

  login.show();
}

hideAllCards() {
  login.hide();
  lobbies.hide();
  create.hide();
  play.hide();
  password.hide();
}
