part of client;

class Login {
  final Element loginCard = querySelector('#login-card');
  final InputElement usernameElement = querySelector('#username');

  final ClientWebSocket client;

  StreamSubscription submitSub;

  Login(this.client) {

    client
      ..on(Message.toast, (String msg) {
        toast(msg);
      })
      ..on(Message.loginSuccesful, (_) {
        lobbies.show();

        var path = window.location.pathname.substring(1);
        if (Lobbies.isValidLobbyName(path)) {
          client.send(Message.enterLobby, path);
        }
      });

    querySelector('#login-btn').onClick.listen((_) {
      submit();
    });
  }

  show() {
    hideAllCards();
    loginCard.style.display = '';

    usernameElement.autofocus = true;

    submitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        submit();
      }
    });
  }

  hide() {
    loginCard.style.display = 'none';
    submitSub?.cancel();
  }

  submit() {
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
