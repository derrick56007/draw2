import 'dart:convert';

class LoginInfo {
  final String lobbyName;
  final String password;

  const LoginInfo(this.lobbyName, this.password);

  factory LoginInfo.fromJson(var json) {
    var list;

    if (json is List) {
      list = json;
    } else {
      list = jsonDecode(json) as List;
    }

    return LoginInfo(list[lobbyNameIndex], list[passwordIndex]);
  }

  static const lobbyNameIndex = 0;
  static const passwordIndex = 1;

  String toJson() => jsonEncode([lobbyName, password]);
}
