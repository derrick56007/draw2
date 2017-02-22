import '../client_websocket.dart';
import '../common/login_info.dart';
import '../common/message.dart';
import '../cookie.dart';
import 'dart:convert';
import 'dart:html';

import '../toast.dart';

main() async {
  var client = new ClientWebSocket();
  await client.start();

  Cookie.reset();

  var loginInfo = new LoginInfo.fromJson(
      Cookie.get('loginInfo', ifNull: new LoginInfo().toJson()));
  client
    ..on(Message.toast, (msg) {
      toast(msg);
    })
    ..on(Message.loginSuccesful, (_) {
      print('logged in!');

      Cookie.set('username', loginInfo.username);

      window.location.assign('/lobbies');
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

    loginInfo.username = username;
    Cookie.set('loginInfo', loginInfo.toJson());
    client.send(Message.login, loginInfo.username);
  });
}
