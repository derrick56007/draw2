part of state;

class Lobbies extends State {
  static RegExp lobbyNameRegex = RegExp(DrawRegExp.lobbyName);

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
  void show() {
    lobbiesCard.style.display = '';

    submitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        submit();
      }
    });
  }

  @override
  void hide() {
    lobbiesCard.style.display = 'none';
    submitSub?.cancel();
  }

  void submit() {
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

  void _lobbyInfo(String json) {
    querySelector('#lobby-list-progress')?.remove();

    final lobbyInfo = LobbyInfo.fromJson(json);

    final el = Element.html('''
          <a id="lobby-${lobbyInfo.name}" class="collection-item lobby-list-item">
            <span class="badge">${lobbyInfo.numberOfPlayers}/${lobbyInfo.maxPlayers}</span>
            
            ${lobbyInfo.hasPassword ? '<i class="material-icons lock">lock</i>' : '<i class="material-icons lock">lock_open</i>'}
                
            ${lobbyInfo.hasTimer ? '<i class="material-icons hourglass">hourglass_empty</i>' : ''}
            
            ${lobbyInfo.name}
          </a>''')
      ..onClick
          .listen((_) => client.send(MessageType.enterLobby, lobbyInfo.name));

    lobbyListCollection.children.add(el);
  }

  void _lobbyClosed(String lobbyName) {
    querySelector('#lobby-$lobbyName')?.remove();
  }

  void _requestPassword(String lobbyName) async {
    final password = await Password.show();

    final loginInfo = LoginInfo(lobbyName, password);

    client.send(MessageType.enterLobbyWithPassword, loginInfo.toJson());
  }

  void _enterLobbySuccessful(String lobbyName) {
    StateManager.shared.pushState('play', lobbyName);

    //
    document.getElementById('invite-players-text').text =
        '${window.location.host.toString() /*.replaceFirst('https', 'http')*/}/$lobbyName';
  }

  void _enterLobbyFailure() {
    StateManager.shared.pushState('lobbies');
  }
}
