part of common;

@serializable
class Brush extends JsonObject {
  String color = '#000000';
  int size = 5;

  bool pressed = false;
  bool moved = false;

  Point pos = new Point.zero();
  Point prevPos = new Point.zero();

  Brush();

  factory Brush.fromJson(String json) =>
      JsonObject.serializer.decode(json, Brush);
}
