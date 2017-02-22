import '../client_websocket.dart';
import '../common/lobby_info.dart';
import '../common/login_info.dart';
import '../cookie.dart';
import 'dart:html';

import '../common/message.dart';
import '../toast.dart';

Element lobbyListCollection = querySelector('#lobby-list-collection');

main() async {
  var client = new ClientWebSocket();
  await client.start();

  var loginInfo = new LoginInfo.fromJson(
      Cookie.get('loginInfo', ifNull: new LoginInfo().toJson()));

  void passwordState() {
    querySelector('#password-card').style.display = '';
    querySelector('#lobby-list-card').style.display = 'none';
  }

  void lobbyListState() {
    querySelector('#password-card').style.display = 'none';
    querySelector('#lobby-list-card').style.display = '';
  }

  client
    ..onOpen.listen((_) {
      if (!client.isConnected()) {
        toast('Not connected');
        return;
      }

      client.send(Message.requestLobbyList, '');
    })
    ..on(Message.lobbyOpened, (dynamic data) {
      querySelector('#lobby-list-progress')?.remove();

      var lobbyInfo = new LobbyInfo.fromJson(data);

      var el = new Element.html('''
      <a id="lobby-${lobbyInfo.name}" class="collection-item lobby-list-item">
          <span class="badge">${lobbyInfo.numberOfPlayers}/${lobbyInfo.maxPlayers}</span>
          ${lobbyInfo.name}
      </a>''');

      // TODO
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
    ..on(Message.lobbyClosed, (String json) {
      querySelector('#lobby-${json}')?.remove();

      if (lobbyListCollection.children.isEmpty) {
        lobbyListState();
        client.send(Message.requestLobbyList, '');
      }
    })
    ..on(Message.enterLobbySuccessful, (String lobbyName) {
      loginInfo.lobbyName = lobbyName;
      Cookie.set('loginInfo', loginInfo.toJson());

      window.location.assign('/$lobbyName');
    })
    ..on(Message.enterLobbyFailure, (_) {
      lobbyListState();
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

  querySelector('#create-lobby-card-btn').onClick.listen((_) {
    window.location.assign('/create');
  });
}
