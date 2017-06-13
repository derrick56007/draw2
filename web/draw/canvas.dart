part of client;

class CanvasHelper {
  static const canvasWidth = 640;
  static const canvasHeight = 480;

  final Element undoBtn = querySelector('#undo-btn');
  final Element clearBtn = querySelector('#clear-btn');

  static final CanvasElement canvas = querySelector('#canvas');
  final CanvasRenderingContext2D ctx = canvas.context2D;

  final List<CanvasLayer> canvasLayers = [];

  final ClientWebSocket client;

  CanvasHelper(this.client) {
    client
      ..on(Message.drawPoint, (x) => drawPoint(new DrawPoint.fromJson(x)))
      ..on(Message.drawLine, (x) => drawLine(new Point.fromJson(x)))
      ..on(Message.clearDrawing, (_) => clearDrawing())
      ..on(Message.undoLast, (_) => undoLast())
      ..on(Message.existingCanvasLayers, (x) => existingCanvasLayers(x));
  }

  drawPoint(DrawPoint drawPoint) {
    var layer = new BrushLayer(
        [drawPoint.pos.clone()], drawPoint.color, drawPoint.size);
    canvasLayers.add(layer);

    strokeCanvasLayers();
  }

  drawLine(Point pos) {
    if (canvasLayers.length > 0) {
      (canvasLayers.last as BrushLayer).points.add(pos.clone());
    }
    strokeCanvasLayers();
  }

  // smooth draw path
  strokeCanvasLayers() {
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    for (var layer in canvasLayers) {
      if (layer is BrushLayer) {
        var p1 = layer.points.first;

        if (layer.points.length == 1) {
          ctx
            ..beginPath()
            ..arc(p1.x, p1.y, layer.size / 2, 0, 2 * PI)
            ..closePath()
            ..fillStyle = layer.color
            ..fill();
        } else if (layer.points.length > 1) {
          var p2 = layer.points[1];

          ctx
            ..beginPath()
            ..moveTo(p1.x, p1.y);

          for (int i = 1; i < layer.points.length - 1; i++) {
            var midPoint = Point.midPoint(p1, p2);

            ctx.quadraticCurveTo(p1.x, p1.y, midPoint.x, midPoint.y);

            p1 = layer.points[i];
            p2 = layer.points[i + 1];
          }

          ctx
            ..lineTo(p1.x, p1.y)
            ..lineWidth = layer.size
            ..strokeStyle = layer.color
            ..lineCap = 'round'
            ..lineJoin = 'round'
            ..stroke();
        }
      } else if (layer is FillLayer) {}
    }
  }

  undoLast() {
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    if (canvasLayers.length > 0) {
      canvasLayers.removeLast();

      strokeCanvasLayers();

      if (canvasLayers.length == 0) {
        undoBtn.classes.add('disabled');
        clearBtn.classes.add('disabled');
      }
    }
  }

  clearDrawing() {
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    canvasLayers.clear();

    undoBtn.classes.add('disabled');
    clearBtn.classes.add('disabled');
  }

  matchStartColor(int pixelPos, ImageData imgData, HexColor color) {
    var r = imgData.data[pixelPos];
    var g = imgData.data[pixelPos + 1];
    var b = imgData.data[pixelPos + 2];

    return (r == color.r && g == color.g && b == color.b);
  }

  colorPixel(int pixelPos, ImageData imgData, HexColor color) {
    imgData.data[pixelPos] = color.r;
    imgData.data[pixelPos + 1] = color.g;
    imgData.data[pixelPos + 2] = color.b;
    imgData.data[pixelPos + 3] = 255;
  }

  fill(num x, num y, String color) {
    var imgData = ctx.getImageData(0, 0, canvasWidth, canvasHeight);

    var hex = new HexColor(color);

    var drawingBoundTop = 0;

    var pixelStack = [
      [x, y]
    ];

    while (pixelStack.isNotEmpty) {
      var newPos, x, y, pixelPos, reachLeft, reachRight;
      newPos = pixelStack.removeLast();
      x = newPos[0];
      y = newPos[1];

      pixelPos = (y * canvasWidth + x) * 4;
      while (
          y-- >= drawingBoundTop && matchStartColor(pixelPos, imgData, hex)) {
        pixelPos -= canvasWidth * 4;
      }
      pixelPos += canvasWidth * 4;
      ++y;
      reachLeft = false;
      reachRight = false;
      while (
          y++ < canvasHeight - 1 && matchStartColor(pixelPos, imgData, hex)) {
        colorPixel(pixelPos, imgData, hex);

        if (x > 0) {
          if (matchStartColor(pixelPos - 4, imgData, hex)) {
            if (!reachLeft) {
              pixelStack.add([x - 1, y]);
              reachLeft = true;
            }
          } else if (reachLeft) {
            reachLeft = false;
          }
        }

        if (x < canvasWidth - 1) {
          if (matchStartColor(pixelPos + 4, imgData, hex)) {
            if (!reachRight) {
              pixelStack.add([x + 1, y]);
              reachRight = true;
            }
          } else if (reachRight) {
            reachRight = false;
          }
        }

        pixelPos += canvasWidth * 4;
      }
    }
    ctx.putImageData(imgData, 0, 0);
  }

  existingCanvasLayers(String json) {
    canvasLayers.clear();

    var layers = JSON.decode(json) as List;

    for (var layer in layers) {
      switch (layer[CanvasLayer.layerTypeIndex]) {
        case ToolType.BRUSH:
          canvasLayers.add(new BrushLayer.fromList(layer));
          break;
        case ToolType.FILL:
          canvasLayers.add(new FillLayer.fromList(layer));
          break;
        default:
      }
    }

    strokeCanvasLayers();
  }
}
