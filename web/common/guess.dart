import 'dart:convert';

class Guess {
  String username;
  String guess;

  Guess();

  factory Guess.fromJson(String json) {
    var map = JSON.decode(json) as Map;

    return new Guess()
      ..username = map['username']
      ..guess = map['guess'];
  }

  String toJson() => JSON.encode({'username': username, 'guess': guess});
}
