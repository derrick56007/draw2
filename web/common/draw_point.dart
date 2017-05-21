import 'dart:convert';

import 'point.dart';

class DrawPoint {
  final String color;
  final int size;
  final Point pos;

  const DrawPoint(this.color, this.size, this.pos);

  factory DrawPoint.fromJson(var json) {
    var map;

    if (json is Map) {
      map = json;
    } else {
      map = JSON.decode(json) as Map;
    }

    return new DrawPoint(
        map['color'], map['size'], new Point.fromJson(map['pos']));
  }

  String toJson() => JSON.encode({'color': color, 'size': size, 'pos': pos});
}
