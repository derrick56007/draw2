import 'dart:convert';

import 'canvas_state.dart';
import 'existing_player.dart';
import 'guess.dart';

class GameState {
  String currentArtist;
  List<Guess> guesses;
  List<ExistingPlayer> players;
  CanvasState canvasState;

  GameState._internal();

  factory GameState.fromJson(String json) {
    var map = JSON.decode(json) as Map;

    var guessesDecoded = [];

    for (var guessJson in map['guesses']) {
      guessesDecoded.add(new Guess.fromJson(guessJson));
    }

    var playersDecoded = [];

    for (var playerJson in map['players']) {
      playersDecoded.add(new ExistingPlayer.fromJson(playerJson));
    }

    var gameState = new GameState._internal()
      ..currentArtist = map['currentArtist']
      ..guesses = guessesDecoded
      ..players = playersDecoded
      ..canvasState = new CanvasState.fromJson(map['canvasState']);

    return gameState;
  }

  String toJson() {
    var guessesEncoded = [];

    for (var guess in guesses) {
      guessesEncoded.add(guess.toJson());
    }

    var playersEncoded = [];

    for (var player in players) {
      playersEncoded.add(player.toJson());
    }

    var json = JSON.encode({
      'currentArtist': currentArtist,
      'guesses': guessesEncoded,
      'players': playersEncoded,
      'canvasState': canvasState.toJson()
    });

    return json;
  }
}
