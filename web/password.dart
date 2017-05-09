part of client;

class Password {
  static Element passwordCard = querySelector('#password-card');
  static InputElement passwordField = querySelector('#enter-lobby-password');
  static StreamSubscription submitSub;
  static ClientWebSocket client;
  static String lobbyName;

  static void init(ClientWebSocket _client) {
    client = _client;

    querySelector('#enter-lobby-password-btn').onClick.listen((_) {
      submit();
    });
  }

  static void show(String _lobbyName) {
    hideAllCards();
    passwordCard.style.display = '';

    passwordField.autofocus = true;

    lobbyName = _lobbyName;

    submitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        submit();
      }
    });
  }

  static void hide() {
    passwordCard.style.display = 'none';
    submitSub?.cancel();
  }

  static void submit() {
    var password = passwordField.value.trim();

    if (password.isEmpty) {
      toast('Invalid input');
      return;
    }

    var loginInfo = new LoginInfo()
      ..lobbyName = lobbyName
      ..password = password;

    client.send(Message.enterLobbyWithPassword, loginInfo.toJson());
  }
}