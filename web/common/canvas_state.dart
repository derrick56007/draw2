import 'dart:convert';

class CanvasState {

  CanvasState._internal();

  factory CanvasState.fromJson(String json) {
    var map = JSON.decode(json) as Map;

    return new CanvasState._internal();
  }

  String toJson() {
    var json = JSON.encode({});

    return json;
  }
}