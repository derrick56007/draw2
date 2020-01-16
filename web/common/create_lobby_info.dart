import 'dart:convert';

class CreateLobbyInfo {
  final String lobbyName;
  final String password;
  final bool hasTimer;
  final int maxPlayers;

  const CreateLobbyInfo(
      this.lobbyName, this.password, this.hasTimer, this.maxPlayers);

  factory CreateLobbyInfo.fromJson(var json) {
    var list;

    if (json is List) {
      list = json;
    } else {
      list = jsonDecode(json) as List;
    }

    return  CreateLobbyInfo(list[lobbyNameIndex], list[passwordIndex],
        list[hasTimerIndex], list[maxPlayersIndex]);
  }

  static const lobbyNameIndex = 0;
  static const passwordIndex = 1;
  static const hasTimerIndex = 2;
  static const maxPlayersIndex = 3;

  String toJson() => jsonEncode([lobbyName, password, hasTimer, maxPlayers]);
}
