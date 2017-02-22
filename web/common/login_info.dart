import 'dart:convert';

class LoginInfo {
  String username;
  String lobbyName;
  String password;

  LoginInfo();

  factory LoginInfo.fromJson(String json) {
    Map map = JSON.decode(json) as Map;

    return new LoginInfo()
      ..username = map['username']
      ..lobbyName = map['lobbyName']
      ..password = map['password'];
  }

  String toJson() => JSON.encode(
      {'username': username, 'lobbyName': lobbyName, 'password': password});
}
