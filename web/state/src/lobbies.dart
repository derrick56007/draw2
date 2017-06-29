part of state;

class Lobbies extends State {
  static RegExp lobbyNameRegex = new RegExp(DrawRegExp.lobbyName);

  final Element lobbiesCard = querySelector('#lobby-list-card');
  final Element lobbyListCollection = querySelector('#lobby-list-collection');

  StreamSubscription submitSub;

  Lobbies(ClientWebSocket client) : super(client) {
    client
      ..on(MessageType.lobbyInfo, _lobbyInfo)
      ..on(MessageType.lobbyClosed, _lobbyClosed)
      ..on(MessageType.requestPassword, _requestPassword)
      ..on(MessageType.enterLobbySuccessful, _enterLobbySuccessful)
      ..on(MessageType.enterLobbyFailure, _enterLobbyFailure);

    querySelector('#create-lobby-card-btn').onClick.listen((_) {
      StateManager.shared.pushState('create');
    });
  }

  @override
  show() {
    lobbiesCard.style.display = '';

    submitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        submit();
      }
    });
  }

  @override
  hide() {
    lobbiesCard.style.display = 'none';
    submitSub?.cancel();
  }

  submit() {
    if (!client.isConnected()) {
      toast('Not connected');
      return;
    }

    StateManager.shared.pushState('create');
  }

  static bool isValidLobbyName(String lobbyName) {
    final lobbyMatches = lobbyNameRegex.firstMatch(lobbyName);

    return lobbyMatches != null && lobbyMatches[0] == lobbyName;
  }

  _lobbyInfo(String json) {
    querySelector('#lobby-list-progress')?.remove();

    final lobbyInfo = new LobbyInfo.fromJson(json);

    final el = new Element.html('''
          <a id="lobby-${lobbyInfo.name}" class="collection-item lobby-list-item">
            <span class="badge">${lobbyInfo.numberOfPlayers}/${lobbyInfo.maxPlayers}</span>
            
            ${lobbyInfo.hasPassword ?
                '<i class="material-icons lock">lock</i>' :
                '<i class="material-icons lock">lock_open</i>'}
                
            ${lobbyInfo.hasTimer ?
                '<i class="material-icons hourglass">hourglass_empty</i>' :
                ''}
            
            ${lobbyInfo.name}
          </a>''')
      ..onClick.listen((_) => client.send(MessageType.enterLobby, lobbyInfo.name));

    lobbyListCollection.children.add(el);
  }

  _lobbyClosed(String lobbyName) {
    querySelector('#lobby-$lobbyName')?.remove();
  }

  _requestPassword(String lobbyName) {
    // TODO fix
//    password
//      ..lobbyName = lobbyName
//      ..show(lobbyName);
  }

  _enterLobbySuccessful(String lobbyName) {
    StateManager.shared.pushState('play', lobbyName);
  }

  _enterLobbyFailure() {
    StateManager.shared.pushState('lobbies');
  }
}
