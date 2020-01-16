library client;

import 'common/message_type.dart';

import 'state/src/play/play.dart';
import 'state/state.dart';

import 'client_websocket.dart';
import 'toast.dart';

void main() async {
  final client =  ClientWebSocket();

  await client.start();

  client.on(MessageType.toast, toast);

  StateManager.shared.addAll( {
    'login':  Login(client),
    'lobbies':  Lobbies(client),
    'create':  Create(client),
    'play':  Play(client)
  });

  StateManager.shared.pushState('login', '');
//  panelLeft = new PanelLeft(client);
//  panelRight = new PanelRight(client);
//  password = new Password(client);
}