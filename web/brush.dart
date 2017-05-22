import 'common/point.dart';

class Brush {
  static const defaultColor = '#000000';
  static const defaultSize = 5;

  bool pressed = false;
  bool moved = false;
  final Point pos = new Point(0, 0);

  Brush();
}
