import 'dart:convert';

class LobbyInfo {
  final String name;
  final bool hasPassword;
  final bool hasTimer;
  final int maxPlayers;
  final int numberOfPlayers;

  const LobbyInfo(this.name, this.hasPassword, this.hasTimer, this.maxPlayers, this.numberOfPlayers);

  factory LobbyInfo.fromJson(var json) {
    var map;

    if (json is Map) {
      map = json;
    } else {
      map = JSON.decode(json) as Map;
    }

    return new LobbyInfo(
        map['name'], map['hasPassword'], map['hasTimer'], map['maxPlayers'], map['numberOfPlayers']);
  }

  String toJson() => JSON.encode({
        'name': name,
        'hasPassword': hasPassword,
        'hasTimer': hasTimer,
        'maxPlayers': maxPlayers,
        'numberOfPlayers': numberOfPlayers
      });
}
