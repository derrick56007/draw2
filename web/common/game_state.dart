import 'dart:convert';

import 'canvas_layer.dart';
import 'existing_player.dart';
import 'guess.dart';

class GameState {
  final String currentArtist;
  final List<Guess> guesses;
  final List<ExistingPlayer> players;
  final List<Layer> canvasLayers;

  const GameState(
      this.currentArtist, this.guesses, this.players, this.canvasLayers);

  factory GameState.fromJson(var json) {
    var map;

    if (json is Map) {
      map = json;
    } else {
      map = JSON.decode(json) as Map;
    }

    var guessesDecoded = <Guess>[];

    for (var guessJson in map['guesses']) {
      guessesDecoded.add(new Guess.fromJson(guessJson));
    }

    var playersDecoded = <ExistingPlayer>[];

    for (var playerJson in map['players']) {
      playersDecoded.add(new ExistingPlayer.fromJson(playerJson));
    }

    var layersDecoded = <Layer>[];

    for (var layer in map['canvasLayers']) {
      layersDecoded.add(new Layer.fromJson(layer));
    }

    var gameState = new GameState(
        map['currentArtist'], guessesDecoded, playersDecoded, layersDecoded);

    return gameState;
  }

  String toJson() => JSON.encode({
        'currentArtist': currentArtist,
        'guesses': guesses,
        'players': players,
        'canvasLayers': canvasLayers
      });
}
