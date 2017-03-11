part of client;

class Login {
  static init(ClientWebSocket client) {
    client
      ..on(Message.toast, (String msg) {
        toast(msg);
      })
      ..on(Message.loginSuccesful, (_) {
        window.history.pushState(null, null, '/lobbies');
        changeCard('lobby-list-card');
      });

    querySelector('#login-btn').onClick.listen((_) {
      if (!client.isConnected()) {
        toast('Not connected');
        return;
      }

      InputElement usernameElement = querySelector('#username');
      String username = usernameElement.value.trim();

      if (username.isEmpty) {
        toast('Not a valid username');
        return;
      }

      client.send(Message.login, username);
    });
  }
}
