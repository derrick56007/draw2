import 'dart:convert';

class ExistingPlayer {
  final String username;
  final int score;

  const ExistingPlayer(this.username, this.score);

  factory ExistingPlayer.fromJson(var json) {
    var map;

    if (json is Map) {
      map = json;
    } else {
      map = JSON.decode(json) as Map;
    }

    return new ExistingPlayer(map['username'], map['score']);
  }

  String toJson() => JSON.encode({'username': username, 'score': score});
}
