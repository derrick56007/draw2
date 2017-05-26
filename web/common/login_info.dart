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
      list = JSON.decode(json) as List;
    }

    return new LoginInfo(list[lobbyNameIndex], list[passwordIndex]);
  }

  static const lobbyNameIndex = 0;
  static const passwordIndex = 1;

  String toJson() => JSON.encode([lobbyName, password]);
}
