import 'dart:convert';

import 'canvas_layer.dart';
import 'existing_player.dart';
import 'guess.dart';

class GameState {
  final String currentArtist;
  final List<Guess> guesses;
  final List<ExistingPlayer> players;
  final List<CanvasLayer> canvasLayers;

  const GameState(
      this.currentArtist, this.guesses, this.players, this.canvasLayers);

  factory GameState.fromJson(var json) {
    var list;

    if (json is List) {
      list = json;
    } else {
      list = JSON.decode(json) as List;
    }

    var guessesDecoded = <Guess>[];

    for (var guessJson in list[guessesIndex]) {
      guessesDecoded.add(new Guess.fromJson(guessJson));
    }

    var playersDecoded = <ExistingPlayer>[];

    for (var playerJson in list[playersIndex]) {
      playersDecoded.add(new ExistingPlayer.fromJson(playerJson));
    }

    var layersDecoded = <CanvasLayer>[];

    for (var layer in list[canvasLayersIndex]) {
      layersDecoded.add(new CanvasLayer.fromJson(layer));
    }

    var gameState = new GameState(list[currentArtistIndex], guessesDecoded,
        playersDecoded, layersDecoded);

    return gameState;
  }

  static const currentArtistIndex = 0;
  static const guessesIndex = 1;
  static const playersIndex = 2;
  static const canvasLayersIndex = 3;

  String toJson() =>
      JSON.encode([currentArtist, guesses, players, canvasLayers]);
}
