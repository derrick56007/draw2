part of state;

class Create extends State {
  final Element createLobbyCard = querySelector('#create-lobby-card');
  final InputElement lobbyNameElement = querySelector('#lobby-name');
  StreamSubscription submitSub;

  Create(ClientWebSocket client) : super(client) {
    querySelector('#create-lobby-btn').onClick.listen((_) {
      submit();
    });

    querySelector('#back-to-lobbies-list-btn').onClick.listen((_) {
      StateManager.shared.pushState('lobbies');
    });
  }

  @override
  show() {
    createLobbyCard.style.display = '';

    submitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        submit();
      }
    });

    lobbyNameElement.focus();
  }

  @override
  hide() {
    createLobbyCard.style.display = 'none';

    submitSub?.cancel();
  }

  submit() {
    if (!client.isConnected()) {
      toast('Not connected');
      return;
    }

    final lobbyName = lobbyNameElement.value.trim();

    if (lobbyName.isEmpty) {
      toast('Not a valid lobby name');
      return;
    }

    final passwordElement =
        querySelector('#create-lobby-password') as InputElement;
    final password = passwordElement.value.trim();

    final selectNumPlayersEl =
        querySelector('#number-of-players') as SelectElement;
    final maxPlayers = int.parse(selectNumPlayersEl.value);

    final timerElement = querySelector('#timer-switch') as InputElement;
    final hasTimer = timerElement.checked;

    final lobbyInfo =
        new CreateLobbyInfo(lobbyName, password, hasTimer, maxPlayers);

    client.send(MessageType.createLobby, lobbyInfo.toJson());
  }
}
