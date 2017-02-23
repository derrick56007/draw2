import '../common/login_info.dart';
import '../cookie.dart';
import 'dart:html';

import '../common/create_lobby_info.dart';
import '../common/message.dart';
import '../client_websocket.dart';
import '../toast.dart';

main() async {
  var client = new ClientWebSocket();
  await client.start();

  var loginInfo = new LoginInfo.fromJson(
      Cookie.get('loginInfo', ifNull: new LoginInfo().toJson()));

  client
    ..on(Message.createLobbySuccessful, (String lobbyName) {
      Cookie.set('loginInfo', loginInfo.toJson());

      window.location.assign('/$lobbyName');
    });

  querySelector('#create-lobby-btn').onClick.listen((_) {
    if (!client.isConnected()) {
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
    window.location.assign('/lobbies');
  });
}
