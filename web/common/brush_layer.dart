import 'canvas_layer.dart';
import 'dart:convert';
import 'point.dart';
import 'tool_type.dart';

class BrushLayer extends CanvasLayer {
  final List<Point> points;
  final String color;
  final int size;

  BrushLayer(this.points, this.color, this.size) : super(ToolType.BRUSH);

  factory BrushLayer.fromJson(var json) {
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

    return new BrushLayer(decodedPoints, list[colorIndex], list[sizeIndex]);
  }

  static const layerTypeIndex = 0;
  static const pointsIndex = 1;
  static const colorIndex = 2;
  static const sizeIndex = 3;

  String toJson() => JSON.encode([layerType, points, color, size]);
}
