import 'dart:convert';
import 'point.dart';

class CanvasLayer {
  final List<Point> points;
  final String brushColor;
  final int brushSize;

  const CanvasLayer(this.points, this.brushColor, this.brushSize);

  factory CanvasLayer.fromJson(var json) {
    var list;

    if (json is List) {
      list = json;
    } else {
      list = JSON.decode(json) as List;
    }

    var decodedPoints = <Point>[];

    for (var point in list[pointsIndex]) {
      decodedPoints.add(new Point.fromJson(point));
    }

    return new CanvasLayer(
        decodedPoints, list[brushColorIndex], list[brushSizeIndex]);
  }

  static const pointsIndex = 0;
  static const brushColorIndex = 1;
  static const brushSizeIndex = 2;

  String toJson() => JSON.encode([points, brushColor, brushSize]);
}
