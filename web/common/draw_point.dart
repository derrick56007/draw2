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
      list = jsonDecode(json) as List;
    }

    return DrawPoint(
        list[colorIndex], list[sizeIndex],  Point.fromJson(list[posIndex]));
  }

  static const colorIndex = 0;
  static const sizeIndex = 1;
  static const posIndex = 2;

  String toJson() => jsonEncode([color, size, pos]);
}
