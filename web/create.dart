part of client;

class Create {
  Element createLobbyCard = querySelector('#create-lobby-card');
  InputElement lobbyNameElement = querySelector('#lobby-name');
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

    var lobbyInfo =
        new CreateLobbyInfo(lobbyName, password, hasTimer, maxPlayers);

    client.send(Message.createLobby, lobbyInfo.toJson());
  }
}
