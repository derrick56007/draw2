import 'dart:convert';

class ExistingPlayer {
  String username;
  int score;

  ExistingPlayer();

  factory ExistingPlayer.fromJson(String json) {
    Map map = JSON.decode(json) as Map;

    return new ExistingPlayer()
      ..username = map['username']
      ..score = map['score'];
  }

  String toJson() => JSON.encode({'username': username, 'score': score});
}
