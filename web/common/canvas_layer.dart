import 'tool_type.dart';

abstract class CanvasLayer {
  final ToolType layerType;

  CanvasLayer(this.layerType);

  static const layerTypeIndex = 0;
}
