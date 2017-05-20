import 'dart:convert';
import 'point.dart';

class Layer {
  final List<Point> points;
  final String brushColor;
  final int brushSize;

  const Layer(this.points, this.brushColor, this.brushSize);

  factory Layer.fromJson(var json) {
    var map;

    if (json is Map) {
      map = json;
    } else {
      map = JSON.decode(json) as Map;
    }

    return new Layer(map['points'], map['brushColor'], map['brushSize']);
  }

  String toJson() => JSON.encode(
      {'points': points, 'brushColor': brushColor, 'brushSize': brushSize});
}
