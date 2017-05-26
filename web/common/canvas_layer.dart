import 'dart:convert';
import 'point.dart';

class CanvasLayer {
  final List<Point> points;
  final String brushColor;
  final int brushSize;

  const CanvasLayer(this.points, this.brushColor, this.brushSize);

  factory CanvasLayer.fromJson(var json) {
    var map;

    if (json is Map) {
      map = json;
    } else {
      map = JSON.decode(json) as Map;
    }

    var decodedPoints = <Point>[];

    for (var point in map['points']) {
      decodedPoints.add(new Point.fromJson(point));
    }

    return new CanvasLayer(decodedPoints, map['brushColor'], map['brushSize']);
  }

  String toJson() => JSON.encode(
      {'points': points, 'brushColor': brushColor, 'brushSize': brushSize});
}
