library play;

import 'common/existing_player.dart';
import 'common/guess.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html' hide Point;
import 'dart:math' hide Point;

import 'common/draw_point.dart';
import 'common/fill_layer.dart';
import 'common/message.dart';
import 'common/point.dart';
import 'common/tool_type.dart';
import 'common/brush_layer.dart';
import 'common/canvas_layer.dart';

import 'card.dart';
import 'client_websocket.dart';
import 'dart:typed_data';
import 'main.dart';

part 'draw/brush.dart';
part 'draw/canvas_helper.dart';
part 'draw/hex_color.dart';

part 'panel_left.dart';
part 'panel_right.dart';

class Play extends Card {
  static const brushInterval = const Duration(milliseconds: 25);
  static const defaultToolType = ToolType.BRUSH;

  final Element playCard = querySelector('#play-card');

  final Element canvasLeftLabel = querySelector('#canvas-left-label');
  final Element canvasMiddleLabel = querySelector('#canvas-middle-label');
  final Element canvasRightLabel = querySelector('#canvas-right-label');

  final Element artistOptions = querySelector('#artist-options');
  final Element drawNextBtn = querySelector('#draw-next-btn');
  final Element undoBtn = querySelector('#undo-btn');
  final Element clearBtn = querySelector('#clear-btn');
  final Element brushBtn = querySelector('#brush-btn');
  final Element fillBtn = querySelector('#fill-btn');

  static final CanvasElement canvas = querySelector('#canvas');

  final InputElement chatInput = querySelector('#chat-input');

  final List<StreamSubscription<MouseEvent>> drawSubs = [];
  final List<StreamSubscription> playSubs = [];

  final ClientWebSocket client;

  final CanvasHelper cvs;

  Timer timer;

  ToolType toolType = defaultToolType;

  Play(this.client) : cvs = new CanvasHelper(client) {
    client
      ..on(Message.setAsArtist, (_) => _setAsArtist())
      ..on(Message.setArtist, (_) => _setArtist())
      ..on(Message.win, (_) => _win())
      ..on(Message.lose, (_) => _lose())
      ..on(Message.setCanvasLeftLabel, (x) => _setCanvasLeftLabel(x))
      ..on(Message.setCanvasMiddleLabel, (x) => _setCanvasMiddleLabel(x))
      ..on(Message.setCanvasRightLabel, (x) => _setCanvasRightLabel(x))
      ..on(Message.clearCanvasLabels, (_) => _clearCanvasLabels())
      ..on(Message.enableDrawNext, (x) => _enableDrawNext());
  }

  show() {
    hideAllCards();
    playCard.style.display = '';

    playSubs
      ..add(document.onKeyPress.listen((KeyboardEvent e) {
        if (e.keyCode != KeyCode.ENTER) return;

        final guess = chatInput.value.trim();

        if (guess.isNotEmpty) {
          client.send(Message.guess, guess);
        }

        chatInput.value = '';
      }))
      ..add(drawNextBtn.onClick.listen((_) {
        if (drawNextBtn.classes.contains('disabled')) return;

        drawNextBtn.classes.add('disabled');

        client.send(Message.drawNext);
      }));
  }

  hide() {
    playCard.style.display = 'none';

    _clearPlaySubs();
    _clearDrawSubs();
  }

  _clearPlaySubs() {
    for (var sub in playSubs) {
      sub?.cancel();
    }
    playSubs.clear();
  }

  _clearDrawSubs() {
    for (var sub in drawSubs) {
      sub?.cancel();
    }
    drawSubs.clear();
  }

  _drawStart(Brush brush, Point pos) {
    final color = querySelector('#color').text;

    if (toolType == ToolType.BRUSH) {
      brush
        ..pos.x = pos.x
        ..pos.y = pos.y
        ..pressed = true;

      final drawPoint = new DrawPoint(color, Brush.defaultSize, brush.pos);

      cvs.drawPoint(drawPoint);
      client.send(Message.drawPoint, drawPoint.toJson());

      timer?.cancel();
      timer = new Timer.periodic(brushInterval, (_) {
        if (brush.moved) {
          cvs.drawLine(brush.pos);
          client.send(Message.drawLine, brush.pos.toJson());

          brush.moved = false;
        }
      });

      undoBtn.classes.remove('disabled');
      clearBtn.classes.remove('disabled');
    } else if (toolType == ToolType.FILL) {
      final fillLayer = new FillLayer(pos.x, pos.y, color);

      cvs.addFillLayer(fillLayer);
      client.send(Message.fill, fillLayer.toJson());
    }
  }

  _drawMove(Brush brush, Point pos) {
    if (brush.pressed) {
      brush
        ..pos.x = pos.x
        ..pos.y = pos.y
        ..moved = true;
    }
  }

  _drawEnd(Brush brush) {
    if (toolType == ToolType.BRUSH) {
      brush
        ..pressed = false
        ..moved = false;

      timer?.cancel();
    }
  }

  _canvasOnMouseDown(Brush brush) => canvas.onMouseDown.listen((MouseEvent e) {
        final mousePos = _getMousePos(e);

        _drawStart(brush, mousePos);
      });

  _documentOnMouseMove(Brush brush) =>
      document.onMouseMove.listen((MouseEvent e) {
        final mousePos = _getMousePos(e);

        _drawMove(brush, mousePos);
      });

  _documentOnMouseUp(Brush brush) => document.onMouseUp.listen((_) {
        _drawEnd(brush);
      });

  Point _getMousePos(MouseEvent e) {
    final rect = canvas.getBoundingClientRect();

    final x = e.page.x - (rect.left + window.pageXOffset);
    final y = e.page.y - (rect.top + window.pageYOffset);

    return new Point(x, y);
  }

  _canvasOnTouchStart(Brush brush) =>
      canvas.onTouchStart.listen((TouchEvent e) {
        if (e.target == canvas) {
          e.preventDefault();
        }

        final touchPos = _getTouchPos(e);

        _drawStart(brush, touchPos);
      });

  _documentOnTouchMove(Brush brush) =>
      document.onTouchMove.listen((TouchEvent e) {
        if (e.target == canvas) {
          e.preventDefault();
        }

        final touchPos = _getTouchPos(e);

        _drawMove(brush, touchPos);
      });

  _documentOnTouchEnd(Brush brush) =>
      document.onTouchEnd.listen((TouchEvent e) {
        if (e.target == canvas) {
          e.preventDefault();
        }

        _drawEnd(brush);
      });

  Point _getTouchPos(TouchEvent e) {
    final rect = canvas.getBoundingClientRect();

    final x = e.touches.first.page.x - (rect.left + window.pageXOffset);
    final y = e.touches.first.page.y - (rect.top + window.pageYOffset);

    return new Point(x, y);
  }

  _undoBtnOnClick() => undoBtn.onClick.listen((_) {
        if (undoBtn.classes.contains('disabled')) return;

        client.send(Message.undoLast);
        cvs.undoLast();
      });

  _clearBtnOnClick() => clearBtn.onClick.listen((_) {
        client.send(Message.clearDrawing);
        cvs.clearDrawing();
      });

  _brushBtnOnClick() => brushBtn.onClick.listen((_) {
        if (brushBtn.classes.contains('disabled')) return;

        toolType = ToolType.BRUSH;

        brushBtn.classes.add('disabled');
        fillBtn.classes.remove('disabled');
      });

  _fillBtnOnClick() => fillBtn.onClick.listen((_) {
        if (fillBtn.classes.contains('disabled')) return;

        toolType = ToolType.FILL;

        fillBtn.classes.add('disabled');
        brushBtn.classes.remove('disabled');
      });

  _setAsArtist() {
    querySelector('#color').text = Brush.defaultColor;
    // TODO set default size

    artistOptions.classes
      ..remove('scale-out')
      ..add('scale-in');

    cvs.clearDrawing();

    final brush = new Brush();

    drawSubs.addAll([
      // desktop
      _canvasOnMouseDown(brush),
      _documentOnMouseMove(brush),
      _documentOnMouseUp(brush),

      // mobile
      _canvasOnTouchStart(brush),
      _documentOnTouchMove(brush),
      _documentOnTouchEnd(brush),

      // buttons
      _undoBtnOnClick(),
      _clearBtnOnClick(),
      _brushBtnOnClick(),
      _fillBtnOnClick()
    ]);
  }

  _setArtist() {
    artistOptions.classes
      ..remove('scale-in')
      ..add('scale-out');

    cvs.clearDrawing();
    _clearDrawSubs();

    timer?.cancel();

    clearBtn.classes.add('disabled');
    undoBtn.classes.add('disabled');
  }

  _win() {}

  _lose() {}

  _setCanvasLeftLabel(String json) {
    canvasLeftLabel.text = json;
  }

  _setCanvasMiddleLabel(String json) {
    canvasMiddleLabel.text = json;
  }

  _setCanvasRightLabel(String json) {
    canvasRightLabel.text = json;
  }

  _clearCanvasLabels() {
    canvasLeftLabel.text = '';
    canvasMiddleLabel.text = '';
    canvasRightLabel.text = '';
  }

  _enableDrawNext() {
    drawNextBtn.classes.remove('disabled');
  }
}
