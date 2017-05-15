part of client;

class Password {
  Element passwordCard = querySelector('#password-card');
  InputElement passwordField = querySelector('#enter-lobby-password');
  StreamSubscription submitSub;
  ClientWebSocket client;
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
