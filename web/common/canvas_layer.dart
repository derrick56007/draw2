import 'tool_type.dart';

abstract class CanvasLayer {
  final ToolType toolType;

  CanvasLayer(this.toolType);

  static const toolTypeIndex = 0;
}
