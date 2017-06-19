library client;

import 'card.dart';
import 'dart:async';
import 'dart:html';

import 'common/create_lobby_info.dart';
import 'common/draw_regex.dart';
import 'common/lobby_info.dart';
import 'common/login_info.dart';
import 'common/message.dart';

import 'client_websocket.dart';
import 'play.dart';
import 'toast.dart';

part 'create.dart';
part 'lobbies.dart';
part 'login.dart';
part 'password.dart';

var login, lobbies, create, play, panelLeft, panelRight, password;

main() async {
  var client = new ClientWebSocket();
  await client.start();

  login = new Login(client);
  lobbies = new Lobbies(client);
  create = new Create(client);
  play = new Play(client);
  panelLeft = new PanelLeft(client);
  panelRight = new PanelRight(client);
  password = new Password(client);


  login.show();

  client.on(Message.toast, (x) => toast(x));
}

hideAllCards() {
  login.hide();
  lobbies.hide();
  create.hide();
  play.hide();
  password.hide();
}
