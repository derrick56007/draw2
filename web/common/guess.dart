import 'dart:convert';

class Guess {
  final String username;
  final String guess;

  const Guess(this.username, this.guess);

  factory Guess.fromJson(var json) {
    var list;

    if (json is List) {
      list = json;
    } else {
      list = jsonDecode(json) as List;
    }

    return new Guess(list[usernameIndex], list[guessIndex]);
  }

  static const usernameIndex = 0;
  static const guessIndex = 1;

  String toJson() => jsonEncode([username, guess]);
}
