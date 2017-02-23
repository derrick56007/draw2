part of client;

class Lobbies {
  static Element lobbyListCollection = querySelector('#lobby-list-collection');

  static init(ClientWebSocket client) {

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
          <span class="badge">${lobbyInfo.numberOfPlayers}/${lobbyInfo
            .maxPlayers}</span>
          ${lobbyInfo.name}
      </a>''');

        // TODO
        el.onClick.listen((_) {
          myInfo.lobbyName = lobbyInfo.name;

          if (lobbyInfo.hasPassword) {
            changeState('password-card');
          } else {
            client.send(Message.enterLobby, lobbyInfo.name);
          }
        });

        lobbyListCollection.children.add(el);
      })
      ..on(Message.lobbyClosed, (String json) {
        querySelector('#lobby-${json}')?.remove();

        if (lobbyListCollection.children.isEmpty) {
          changeState('lobby-list-state');
          client.send(Message.requestLobbyList, '');
        }
      })
      ..on(Message.enterLobbySuccessful, (String lobbyName) {
        myInfo.lobbyName = lobbyName;

        window.history.pushState(null, null, '/$lobbyName');
        changeState('play-card');
      })
      ..on(Message.enterLobbyFailure, (_) {
        changeState('lobby-list-state');
      });

    querySelector('#enter-lobby-password-btn').onClick.listen((_) {
      var el = querySelector('#enter-lobby-password') as InputElement;
      var password = el.value.trim();

      if (password.isEmpty) {
        toast('Invalid input');
        return;
      }

      var loginInfo = new LoginInfo()
        ..lobbyName = myInfo.lobbyName
        ..password = password;

      client.send(Message.enterLobbyWithPassword, loginInfo.toJson());
    });

    querySelector('#create-lobby-card-btn').onClick.listen((_) {
      window.history.pushState(null, null, '/create');
      changeState('create-lobby-card');
    });
  }
}
