import 'dart:convert';
import 'point.dart';

class Layer {
  List<Point> points;
  String brushColor;
  int brushSize;

  Layer();

  factory Layer.fromJson(var json) {
    var map;

    if (json is Map) {
      map = json;
    } else {
      map = JSON.decode(json) as Map;
    }

    var pointsDecoded = <Point>[];

    for (var point in map['points']) {
      pointsDecoded.add(new Point.fromList(point));
    }

    return new Layer()
      ..points = pointsDecoded
      ..brushColor = map['brushColor']
      ..brushSize = map['brushSize'];
  }

  String toJson() => JSON.encode({'points': points, 'brushColor': brushColor, 'brushSize': brushSize});
}
