part of client;

class Login {
  static Element loginCard = querySelector('#login-card');
  static InputElement usernameElement = querySelector('#username');
  static StreamSubscription submitSub;
  static ClientWebSocket client;

  static init(ClientWebSocket _client) {
    client = _client;

    client
      ..on(Message.toast, (String msg) {
        toast(msg);
      })
      ..on(Message.loginSuccesful, (_) {
        Lobbies.show();

        var path = window.location.pathname.substring(1);
        if (Lobbies.isValidLobbyName(path)) {
          client.send(Message.enterLobby, path);
        }
      });

    querySelector('#login-btn').onClick.listen((_) {
      submit();
    });
  }

  static void show() {
    hideAllCards();
    loginCard.style.display = '';

    usernameElement.autofocus = true;

    submitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        submit();
      }
    });
  }

  static void hide() {
    loginCard.style.display = 'none';
    submitSub?.cancel();
  }

  static void submit() {
    if (!client.isConnected()) {
      toast('Not connected');
      return;
    }

    String username = usernameElement.value.trim();

    if (username.isEmpty) {
      toast('Not a valid username');
      return;
    }

    client.send(Message.login, username);
  }
}
