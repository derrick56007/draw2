import 'dart:convert';

class LoginInfo {
  String lobbyName;
  String password;

  LoginInfo();

  factory LoginInfo.fromJson(String json) {
    var map = JSON.decode(json) as Map;

    return new LoginInfo()
      ..lobbyName = map['lobbyName']
      ..password = map['password'];
  }

  String toJson() =>
      JSON.encode({'lobbyName': lobbyName, 'password': password});
}
