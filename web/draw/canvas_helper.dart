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
      ..on(Message.fill, (x) => fill(new FillLayer.fromJson(x)))
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

  colorPixel(int x, int y, Uint32List data, HexColor color) {
    data[y * canvasWidth + x] = (255 << 24) | // alpha
        (color.b << 16) | // blue
        (color.g << 8) | // green
        color.r; // red
  }

  bool pixelCompare(int i, List<int> targetColor, HexColor fillColor,
      Uint8ClampedList data, int length, int tolerance) {
    if (i < 0 || i >= length) return false;

    if ((targetColor[0] == fillColor.r) &&
        (targetColor[1] == fillColor.g) &&
        (targetColor[2] == fillColor.b)) return false;

    if ((targetColor[0] == data[i]) &&
        (targetColor[1] == data[i + 1]) &&
        (targetColor[2] == data[i + 2])) return true;

    if ((targetColor[0] - data[i]).abs() <= tolerance &&
        (targetColor[1] - data[i + 1]).abs() <= tolerance &&
        (targetColor[2] - data[i + 2]).abs() <= tolerance) return true;

    return false; // no match
  }

  bool pixelCompareAndSet(int i, List<int> targetColor, HexColor fillColor,
      Uint8ClampedList data, int length, int tolerance) {
    if (pixelCompare(i, targetColor, fillColor, data, length, tolerance)) {
      // fill the color
      data[i] = fillColor.r;
      data[i + 1] = fillColor.g;
      data[i + 2] = fillColor.b;
      return true;
    }

    return false;
  }

  fill(FillLayer fillLayer) {
    canvasLayers.add(fillLayer);

    var img = ctx.getImageData(0, 0, canvasWidth, canvasHeight);
    var data = img.data;

    var length = data.length;
    var queue = [];
    var i = (fillLayer.x + fillLayer.y * canvasWidth) * 4;
    var e = i, w = i, me, mw, w2 = canvasWidth * 4;
    var tolerance = 1;

    var targetColor = [data[i], data[i + 1], data[i + 2]];

    var hex = new HexColor(fillLayer.color);

    if (!pixelCompare(i, targetColor, hex, data, length, tolerance)) {
      queue.add(i);

      while (queue.isNotEmpty) {
        i = queue.removeLast();

        if (pixelCompare(i, targetColor, hex, data, length, tolerance)) {
          e = i;
          w = i;
          mw = i ~/ w2 * w2; // left bound
          me = mw + w2; // right bound

          while (mw < w &&
              mw < (w -= 4) &&
              pixelCompareAndSet(i, targetColor, hex, data, length, tolerance));
          while (me < e &&
              me < (e += 4) &&
              pixelCompareAndSet(i, targetColor, hex, data, length, tolerance));
          for (int j = w; j < e; j += 4) {
            if (j - w2 >= 0 &&
                pixelCompare(
                    j - w2, targetColor, hex, data, length, tolerance)) {
              queue.add(j - w2);
            }
            if (j + w2 < length &&
                pixelCompare(
                    j + w2, targetColor, hex, data, length, tolerance)) {
              queue.add(j + w2);
            }
          }
        }
      }
    }

    ctx.putImageData(img, 0, 0);
  }

  existingCanvasLayers(String json) {
    canvasLayers.clear();

    var layers = JSON.decode(json) as List;

    for (var layer in layers) {
      switch (layer[CanvasLayer.layerTypeIndex]) {
        case ToolType.BRUSH:
          canvasLayers.add(new BrushLayer.fromJson(layer));
          break;
        case ToolType.FILL:
          canvasLayers.add(new FillLayer.fromJson(layer));
          break;
        default:
      }
    }

    strokeCanvasLayers();
  }
}
