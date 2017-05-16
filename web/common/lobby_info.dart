import 'dart:convert';

class LobbyInfo {
  String name;
  bool hasPassword;
  bool hasTimer;
  int numberOfPlayers;
  int maxPlayers;

  LobbyInfo();

  factory LobbyInfo.fromJson(var json) {
    var map;

    if (json is Map) {
      map = json;
    } else {
      map = JSON.decode(json) as Map;
    }

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
