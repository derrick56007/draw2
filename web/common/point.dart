part of common;

@serializable
class Point extends JsonObject {
  int x, y;

  Point();

  Point.zero()
      : x = 0,
        y = 0;

  @override
  String toJson() => JSON.encode([x, y]);

  factory Point.fromJson(String json) {
    var point = JSON.decode(json);

    return new Point()
      ..x = point[0]
      ..y = point[1];
  }
}
