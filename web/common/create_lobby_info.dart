import 'dart:convert';

class CreateLobbyInfo {
  String name;
  String password;
  bool hasTimer;
  int maxPlayers;

  CreateLobbyInfo();

  factory CreateLobbyInfo.fromJson(String json) {
    Map map = JSON.decode(json) as Map;

    return new CreateLobbyInfo()
      ..name = map['name']
      ..password = map['password']
      ..hasTimer = map['hasTimer']
      ..maxPlayers = map['maxPlayers'];
  }

  String toJson() => JSON.encode({
        'name': name,
        'password': password,
        'hasTimer': hasTimer,
        'maxPlayers': maxPlayers
      });
}
