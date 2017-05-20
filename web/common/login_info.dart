import 'dart:convert';

class LoginInfo {
  final String lobbyName;
  final String password;

  const LoginInfo(this.lobbyName, this.password);

  factory LoginInfo.fromJson(var json) {
    var map;

    if (json is Map) {
      map = json;
    } else {
      map = JSON.decode(json) as Map;
    }

    return new LoginInfo(map['lobbyName'], map['password']);
  }

  String toJson() =>
      JSON.encode({'lobbyName': lobbyName, 'password': password});
}
