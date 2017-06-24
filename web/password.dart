part of client;

class Password {
  final Element passwordCard = querySelector('#password-card');
  final InputElement passwordField = querySelector('#enter-lobby-password');

  final ClientWebSocket client;

  StreamSubscription submitSub;

  String lobbyName;

  Password(this.client) {
    querySelector('#enter-lobby-password-btn').onClick.listen((_) {
      submit();
    });
  }

  show(String _lobbyName) {
    lobbyName = _lobbyName;

    hideAllCards();
    passwordCard.style.display = '';

    passwordField.autofocus = true;

    submitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        submit();
      }
    });
  }

  hide() {
    passwordCard.style.display = 'none';
    submitSub?.cancel();
  }

  submit() {
    if (!client.isConnected()) {
      toast('Not connected');
      return;
    }

    final password = passwordField.value.trim();

    if (password.isEmpty) {
      toast('Invalid input');
      return;
    }

    final loginInfo = new LoginInfo(lobbyName, password);

    client.send(Message.enterLobbyWithPassword, loginInfo.toJson());
  }
}
