part of play;

class CanvasHelper {
  static const canvasWidth = 640;
  static const canvasHeight = 480;

  final Element undoBtn = querySelector('#undo-btn');
  final Element clearBtn = querySelector('#clear-btn');

  static final CanvasElement canvas = querySelector('#canvas');
  final CanvasRenderingContext2D ctx =
      canvas.getContext('2d', {'alpha': false});

  final List<CanvasLayer> canvasLayers = [];

  final ClientWebSocket client;

  CanvasHelper(this.client) {
    client
      ..on(MessageType.drawPoint, (x) => drawPoint( DrawPoint.fromJson(x)))
      ..on(MessageType.drawLine, (x) => drawLine( Point.fromJson(x)))
      ..on(MessageType.clearDrawing, clearDrawing)
      ..on(MessageType.undoLast, undoLast)
      ..on(MessageType.fill, (x) => addFillLayer( FillLayer.fromJson(x)))
      ..on(MessageType.existingCanvasLayers, existingCanvasLayers);

    clearDrawing();
  }

  void drawPoint(DrawPoint drawPoint) {
    final layer =  BrushLayer(
        [drawPoint.pos.clone()], drawPoint.color, drawPoint.size);
    canvasLayers.add(layer);

    strokeLayer(layer);
  }

  void drawLine(Point pos) {
    if (canvasLayers.isNotEmpty && canvasLayers.last is BrushLayer) {
      (canvasLayers.last as BrushLayer).points.add(pos.clone());

      strokeAllLayers();
    }
  }

  void strokeLayer(CanvasLayer layer) {
    if (layer is BrushLayer) {
      Stroke.brushLayer(layer, ctx);
    } else if (layer is FillLayer) {
      Stroke.fillLayer(layer, ctx);
    }
  }

  // smooth draw path
  void strokeAllLayers() {
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);

    for (var layer in canvasLayers) {
      strokeLayer(layer);
    }
  }

  void undoLast() {
    if (canvasLayers.isNotEmpty) {
      canvasLayers.removeLast();

      strokeAllLayers();

      if (canvasLayers.isEmpty) {
        undoBtn.classes.add('disabled');
        clearBtn.classes.add('disabled');
      }
    }
  }

  void clearDrawing() {
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);

    canvasLayers.clear();

    undoBtn.classes.add('disabled');
    clearBtn.classes.add('disabled');
  }


  void addFillLayer(FillLayer fillLayer) {
    canvasLayers.add(fillLayer);

    strokeLayer(fillLayer);
  }

  void existingCanvasLayers(String json) {

    canvasLayers.clear();

    final layers = jsonDecode(json) as List;

    for (var layer in layers) {
      layer = jsonDecode(layer) as List;

      final toolType = layer[CanvasLayer.toolTypeIndex];

      var canvasLayer;

      // instantiate layer
      if (toolType == ToolType.BRUSH.index) {
        canvasLayer =  BrushLayer.fromJson(layer);
      } else if (toolType == ToolType.FILL.index) {
        canvasLayer =  FillLayer.fromJson(layer);
      }

      // stroke if successfully created
      if (canvasLayer != null) {
        strokeLayer(canvasLayer);
      }
    }
  }
}
