import 'dart:convert';

class CreateLobbyInfo {
  final String name;
  final String password;
  final bool hasTimer;
  final int maxPlayers;

  const CreateLobbyInfo(
      this.name, this.password, this.hasTimer, this.maxPlayers);

  factory CreateLobbyInfo.fromJson(var json) {
    var list;

    if (json is List) {
      list = json;
    } else {
      list = JSON.decode(json) as List;
    }

    return new CreateLobbyInfo(list[nameIndex], list[passwordIndex],
        list[hasTimerIndex], list[maxPlayersIndex]);
  }

  static const nameIndex = 0;
  static const passwordIndex = 1;
  static const hasTimerIndex = 2;
  static const maxPlayersIndex = 3;

  String toJson() => JSON.encode([name, password, hasTimer, maxPlayers]);
}
