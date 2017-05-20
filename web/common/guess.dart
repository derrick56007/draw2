import 'dart:convert';

class Guess {
  final String username;
  final String guess;

  const Guess(this.username, this.guess);

  factory Guess.fromJson(var json) {
    var map;

    if (json is Map) {
      map = json;
    } else {
      map = JSON.decode(json) as Map;
    }

    return new Guess(map['username'], map['guess']);
  }

  String toJson() => JSON.encode({'username': username, 'guess': guess});
}
