import 'dart:convert';

class Guess {
  String username;
  String guess;

  Guess();

  factory Guess.fromJson(var json) {
    var map;

    if (json is Map) {
      map = json;
    } else {
      map = JSON.decode(json) as Map;
    }

    return new Guess()
      ..username = map['username']
      ..guess = map['guess'];
  }

  String toJson() => JSON.encode({'username': username, 'guess': guess});
}
