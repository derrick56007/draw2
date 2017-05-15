part of client;

class Lobbies {
  static var lobbyNameRegex = new RegExp(DrawRegExp.lobbyName);

  Element lobbiesCard = querySelector('#lobby-list-card');
  Element lobbyListCollection = querySelector('#lobby-list-collection');

  StreamSubscription submitSub;

  Lobbies(ClientWebSocket client) {
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
        password.show(lobbyName);
      })
      ..on(Message.enterLobbySuccessful, (String lobbyName) {
        window.history.pushState(null, null, '/$lobbyName');
        play.show();
      })
      ..on(Message.enterLobbyFailure, (_) {
        window.history.pushState(null, null, '/');
        lobbies.show();
      });

    querySelector('#create-lobby-card-btn').onClick.listen((_) {
      create.show();
    });
  }

  show() {
    hideAllCards();
    lobbiesCard.style.display = '';

    submitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        create.show();
      }
    });
  }

  hide() {
    lobbiesCard.style.display = 'none';
    submitSub?.cancel();
  }

  static bool isValidLobbyName(String lobbyName) {
    var lobbyMatches = lobbyNameRegex.firstMatch(lobbyName);

    return lobbyMatches != null && lobbyMatches[0] == lobbyName;
  }
}
