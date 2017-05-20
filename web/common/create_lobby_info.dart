import 'dart:convert';

class CreateLobbyInfo {
  final String name;
  final String password;
  final bool hasTimer;
  final int maxPlayers;

  const CreateLobbyInfo(
      this.name, this.password, this.hasTimer, this.maxPlayers);

  factory CreateLobbyInfo.fromJson(var json) {
    var map;

    if (json is Map) {
      map = json;
    } else {
      map = JSON.decode(json) as Map;
    }

    return new CreateLobbyInfo(
        map['name'], map['password'], map['hasTimer'], map['maxPlayers']);
  }

  String toJson() => JSON.encode({
        'name': name,
        'password': password,
        'hasTimer': hasTimer,
        'maxPlayers': maxPlayers
      });
}
