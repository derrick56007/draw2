part of state;

class Login extends State {
  final Element loginCard = querySelector('#login-card');
  final InputElement usernameElement = querySelector('#username');

  StreamSubscription submitSub;

  Login(ClientWebSocket client) : super(client) {
    client.on(MessageType.loginSuccesful, _loginSuccesful);

    querySelector('#login-btn').onClick.listen((_) {
      submit();
    });
  }

  @override
  show() {
    loginCard.style.display = '';

    usernameElement.autofocus = true;

    submitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        submit();
      }
    });
  }

  @override
  hide() {
    loginCard.style.display = 'none';
    submitSub?.cancel();
  }

  submit() {
    if (!client.isConnected()) {
      toast('Not connected');
      return;
    }

    final username = usernameElement.value.trim();

    if (username.isEmpty) {
      toast('Not a valid username');
      return;
    }

    client.send(MessageType.login, username);
  }

  _loginSuccesful() {
    final lobbyName = window.location.pathname.substring(1);

    // make sure lobby is not a state name
    if (!StateManager.shared.keys.contains(lobbyName) &&
        Lobbies.isValidLobbyName(lobbyName)) {
      client.send(MessageType.enterLobby, lobbyName);

      return;
    }

    StateManager.shared.pushState('lobbies');
  }
}
