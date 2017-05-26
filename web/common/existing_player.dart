import 'dart:convert';

class ExistingPlayer {
  final String username;
  final int score;

  const ExistingPlayer(this.username, this.score);

  factory ExistingPlayer.fromJson(var json) {
    var list;

    if (json is List) {
      list = json;
    } else {
      list = JSON.decode(json) as List;
    }

    return new ExistingPlayer(list[usernameIndex], list[scoreIndex]);
  }

  static const usernameIndex = 0;
  static const scoreIndex = 1;

  String toJson() => JSON.encode([username, score]);
}
