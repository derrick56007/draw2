part of client;

class Lobbies {
  static Element lobbyListCollection = querySelector('#lobby-list-collection');

  static init(ClientWebSocket client) {
    StreamSubscription sub;

    client
      ..on(Message.lobbyInfo, (String json) {
        querySelector('#lobby-list-progress')?.remove();

        var lobbyInfo = new LobbyInfo.fromJson(json);

        var el = new Element.html('''
        <a id="lobby-${lobbyInfo.name}" class="collection-item lobby-list-item">
            <span class="badge">${lobbyInfo.numberOfPlayers}/${lobbyInfo.maxPlayers}</span>
            ${lobbyInfo.name}
        </a>''');

        el.onClick
            .listen((_) => client.send(Message.enterLobby, lobbyInfo.name));

        lobbyListCollection.children.add(el);
      })
      ..on(Message.lobbyClosed, (String lobbyName) {
        querySelector('#lobby-$lobbyName')?.remove();
      })
      ..on(Message.requestPassword, (String lobbyName) {
        sub?.cancel();

        sub = querySelector('#enter-lobby-password-btn').onClick.listen((_) {
          var el = querySelector('#enter-lobby-password') as InputElement;
          var password = el.value.trim();

          if (password.isEmpty) {
            toast('Invalid input');
            return;
          }

          var loginInfo = new LoginInfo()
            ..lobbyName = lobbyName
            ..password = password;

          client.send(Message.enterLobbyWithPassword, loginInfo.toJson());
        });
        changeCard('password-card');
      })
      ..on(Message.enterLobbySuccessful, (String lobbyName) {
        window.history.pushState(null, null, '/${lobbyName}');
        changeCard('play-card');
      })
      ..on(Message.enterLobbyFailure, (_) {
        changeCard('lobby-list-card');
      });

    querySelector('#create-lobby-card-btn').onClick.listen((_) {
      window.history.pushState(null, null, '/create');
      changeCard('create-lobby-card');
    });
  }
}
