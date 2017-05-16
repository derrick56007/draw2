import 'dart:convert';

class LobbyInfo {
  String name;
  bool hasPassword;
  bool hasTimer;
  int numberOfPlayers;
  int maxPlayers;

  LobbyInfo();

  factory LobbyInfo.fromJson(String json) {
    var map = JSON.decode(json);

    return new LobbyInfo()
      ..name = map['name']
      ..hasPassword = map['hasPassword']
      ..hasTimer = map['hasTimer']
      ..numberOfPlayers = map['numberOfPlayers']
      ..maxPlayers = map['maxPlayers'];
  }

  String toJson() => JSON.encode({
        'name': name,
        'hasPassword': hasPassword,
        'hasTimer': hasTimer,
        'numberOfPlayers': numberOfPlayers,
        'maxPlayers': maxPlayers
      });
}
