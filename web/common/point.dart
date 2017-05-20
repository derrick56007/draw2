import 'dart:convert';

class Point<T> {
  T x, y;

  Point(this.x, this.y);

  String toJson() => JSON.encode([x, y]);

  factory Point.fromList(List list) => new Point(list[0], list[1]);

  factory Point.fromJson(var json) {
    if (json is List) return new Point.fromList(json);

    return new Point.fromList(JSON.decode(json));
  }

  static Point midPoint(Point p1, Point p2) =>
      new Point(p1.x + (p2.x - p1.x) / 2, p1.y + (p2.y - p1.y) / 2);
}
