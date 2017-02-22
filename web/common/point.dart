import 'dart:convert';

class Point {
  int x, y;

  Point();

  Point.zero()
      : x = 0,
        y = 0;

  String toJson() => JSON.encode([x, y]);

  factory Point.fromList(List list) => new Point()
    ..x = list[0]
    ..y = list[1];

  factory Point.fromJson(String json) => new Point.fromList(JSON.decode(json));
}
