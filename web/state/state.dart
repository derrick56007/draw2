library state;

import 'dart:async';
import 'dart:html';

import '../common/create_lobby_info.dart';
import '../common/draw_regex.dart';
import '../common/lobby_info.dart';
import '../common/login_info.dart';
import '../common/message_type.dart';

import '../client_websocket.dart';
import '../toast.dart';

part 'src/create.dart';
part 'src/lobbies.dart';
part 'src/login.dart';
part 'src/password.dart';

part 'state_manager.dart';

abstract class State {
  final ClientWebSocket client;

  State(this.client);

  show();
  hide();
}