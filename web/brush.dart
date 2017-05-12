import 'common/point.dart';

class Brush {
  String color = '#000000';
  int size = 5;
  bool pressed = false;
  bool moved = false;
  Point pos = new Point(0, 0);

  Brush();
}
