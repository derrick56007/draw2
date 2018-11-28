part of play;

class Stroke {
  static final fillLayerCache = <FillLayer, CanvasElement>{};

  static brushLayer(BrushLayer layer, CanvasRenderingContext2D ctx) {
    var p1 = layer.points.first;

    if (layer.points.length == 1) {
      ctx
        ..beginPath()
        ..arc(p1.x, p1.y, layer.size / 2, 0, 2 * Math.pi)
        ..closePath()
        ..fillStyle = layer.color
        ..fill();
    } else if (layer.points.length > 1) {
      var p2 = layer.points[1];

      ctx
        ..beginPath()
        ..moveTo(p1.x, p1.y);

      for (var i = 1; i < layer.points.length - 1; i++) {
        final midPoint = Point.midPoint(p1, p2);

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
  }

  static fillLayer(FillLayer layer, CanvasRenderingContext2D ctx) {
    if (fillLayerCache.containsKey(layer)) {
      final canvas = fillLayerCache[layer];

      ctx.drawImage(canvas, 0, 0);
    } else {
      final canvas = new CanvasElement(
          width: CanvasHelper.canvasWidth, height: CanvasHelper.canvasHeight);

      final CanvasRenderingContext2D tempCtx =
          canvas.getContext('2d', {'alpha': false});

      final img = ctx.getImageData(
          0, 0, CanvasHelper.canvasWidth, CanvasHelper.canvasHeight);
      final data = img.data;

      final length = data.length;
      final queue = [];
      var i =
          ((layer.x.floor() + layer.y.floor() * CanvasHelper.canvasWidth) * 4)
              .toInt();
      var e = i, w = i, me, mw;
      final w2 = CanvasHelper.canvasWidth * 4;
      final tolerance = 100;

      final targetColor = [data[i], data[i + 1], data[i + 2]];

      final hex = new HexColor(layer.color);

      if (!pixelCompare(i, targetColor, hex, data, length, tolerance)) {
        return false;
      }
      queue.add(i);
      while (queue.isNotEmpty) {
        i = queue.removeLast();
        if (pixelCompareAndSet(i, targetColor, hex, data, length, tolerance)) {
          e = i;
          w = i;
          mw = (i ~/ w2) * w2; //left bound
          me = mw + w2; //right bound
          while (mw < (w -= 4) &&
              pixelCompareAndSet(w, targetColor, hex, data, length,
                  tolerance)); //go left until edge hit
          while (me > (e += 4) &&
              pixelCompareAndSet(e, targetColor, hex, data, length,
                  tolerance)); //go right until edge hit
          for (var j = w; j < e; j += 4) {
            if (j - w2 >= 0 &&
                pixelCompare(j - w2, targetColor, hex, data, length, tolerance))
              queue.add(j - w2); //queue y-1
            if (j + w2 < length &&
                pixelCompare(j + w2, targetColor, hex, data, length, tolerance))
              queue.add(j + w2); //queue y+1
          }
        }
      }
      ctx.putImageData(img, 0, 0);

      // add to cache
      tempCtx.putImageData(img, 0, 0);

      fillLayerCache[layer] = canvas;
    }
  }

  static bool pixelCompare(int i, List<int> targetColor, HexColor fillColor,
      Uint8ClampedList data, int length, int tolerance) {
    if (i < 0 || i >= length) return false; //out of bounds

    if ((targetColor[0] == fillColor.r) &&
        (targetColor[1] == fillColor.g) &&
        (targetColor[2] == fillColor.b)) return false; //target is same as fill

    if ((targetColor[0] == data[i]) &&
        (targetColor[1] == data[i + 1]) &&
        (targetColor[2] == data[i + 2])) return true; //target matches surface

    if ((targetColor[0] - data[i]).abs() <= tolerance &&
        (targetColor[1] - data[i + 1]).abs() <= tolerance &&
        (targetColor[2] - data[i + 2]).abs() <= tolerance)
      return true; //target to surface within tolerance

    return false; //no match
  }

  static bool pixelCompareAndSet(int i, List<int> targetColor,
      HexColor fillColor, Uint8ClampedList data, int length, int tolerance) {
    if (pixelCompare(i, targetColor, fillColor, data, length, tolerance)) {
      // fill the color
      data[i] = fillColor.r;
      data[i + 1] = fillColor.g;
      data[i + 2] = fillColor.b;
      return true;
    }

    return false;
  }
}
