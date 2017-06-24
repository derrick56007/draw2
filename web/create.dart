part of client;

class Create extends Card {
  final Element createLobbyCard = querySelector('#create-lobby-card');
  final InputElement lobbyNameElement = querySelector('#lobby-name');
  StreamSubscription submitSub;
  ClientWebSocket client;

  Create(this.client) {
    querySelector('#create-lobby-btn').onClick.listen((_) {
      submit();
    });

    querySelector('#back-to-lobbies-list-btn').onClick.listen((_) {
      lobbies.show();
    });
  }

  show() {
    hideAllCards();
    createLobbyCard.style.display = '';

    submitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        submit();
      }
    });

    lobbyNameElement.focus();
  }

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

    client.send(Message.createLobby, lobbyInfo.toJson());
  }
}
