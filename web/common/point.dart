import 'dart:convert';

class Point<T> {
  T x, y;

  Point(this.x, this.y);

  Point clone() =>  Point(x, y);

  String toJson() => jsonEncode([x, y]);

  static const xIndex = 0;
  static const yIndex = 1;

  factory Point.fromList(List list) =>  Point(list[xIndex], list[yIndex]);

  factory Point.fromJson(var json) {
    if (json is List) return  Point.fromList(json);

    return  Point.fromList(jsonDecode(json));
  }

  static Point midPoint(Point p1, Point p2) =>
       Point(p1.x + (p2.x - p1.x) / 2, p1.y + (p2.y - p1.y) / 2);
}
