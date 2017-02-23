part of client;

class Create {
  static init(ClientWebSocket client) {
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

      client.send(Message.createLobby, lobbyInfo.toJson());
    });

    querySelector('#back-to-lobbies-list-btn').onClick.listen((_) {
      window.history.pushState(null, null, '/lobbies');
      changeState('lobby-list-card');
    });
  }
}
