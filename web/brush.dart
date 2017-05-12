import 'point.dart';

class Brush {
  String color = '#000000';
  int size = 5;

  bool pressed = false;
  bool moved = false;
//
  Point pos = new Point(0, 0);
//  Point prevPos = new Point.zero();

  Brush();
//
//  factory Brush.fromJson(String json) {
//    Map map = JSON.decode(json) as Map;
//
//    return new Brush()
//      ..color = map['color']
//      ..size = map['size']
//      ..pressed = map['pressed']
//      ..moved = map['moved']
//      ..pos = new Point.fromList(map['pos'])
//      ..prevPos = new Point.fromList(map['prevPos']);
//  }
//  String toJson() => JSON.encode({
//        'color': color,
//        'size': size,
//        'pressed': pressed,
//        'moved': moved,
//        'pos': pos.toJson(),
//        'prevPos': prevPos.toJson()
//      });
}
