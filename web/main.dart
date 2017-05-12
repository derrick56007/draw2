library client;

import 'dart:async';
import 'dart:convert';
import 'dart:html' hide Point;
import 'dart:math' hide Point;

import 'common/create_lobby_info.dart';
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

main() async {
  var client = new ClientWebSocket();
  await client.start();

  Login.init(client);
  Lobbies.init(client);
  Create.init(client);
  Play.init(client);
  Password.init(client);

  Login.show();
}

hideAllCards() {
  Login.hide();
  Lobbies.hide();
  Create.hide();
  Play.hide();
  Password.hide();
}
