import 'dart:convert';

import 'point.dart';

class DrawPoint {
  final String color;
  final int size;
  final Point pos;

  const DrawPoint(this.color, this.size, this.pos);

  factory DrawPoint.fromJson(var json) {
    var list;

    if (json is List) {
      list = json;
    } else {
      list = JSON.decode(json) as List;
    }

    return new DrawPoint(
        list[colorIndex], list[sizeIndex], new Point.fromJson(list[posIndex]));
  }

  static const colorIndex = 0;
  static const sizeIndex = 1;
  static const posIndex = 2;

  String toJson() => JSON.encode([color, size, pos]);
}
