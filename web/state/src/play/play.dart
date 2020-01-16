library play;

import '../../../common/brush_layer.dart';
import '../../../common/canvas_layer.dart';
import '../../../common/draw_point.dart';
import '../../../common/existing_player.dart';
import '../../../common/fill_layer.dart';
import '../../../common/guess.dart';
import '../../../common/message_type.dart';
import '../../../common/point.dart';
import '../../../common/tool_type.dart';

import '../../../toast.dart';
import '../../state.dart';
import '../../../client_websocket.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:html' hide Point;
import 'dart:math' as math hide Point;
import 'dart:typed_data';

part 'draw/brush.dart';
part 'draw/canvas_helper.dart';
part 'draw/drop_text.dart';
part 'draw/hex_color.dart';
part 'draw/stroke.dart';

part 'panel_left.dart';
part 'panel_right.dart';

class Play extends State {
  static const brushInterval = Duration(milliseconds: 25);
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

  final Element invitePlayersText = querySelector('#invite-players-text');
  final Element invitePlayersBtn = querySelector('#invite-players-btn');

  static final CanvasElement canvas = querySelector('#canvas');

  final InputElement chatInput = querySelector('#chat-input');

  final List<StreamSubscription<MouseEvent>> drawSubs = [];
  final List<StreamSubscription> playSubs = [];

  final CanvasHelper cvs;

  Timer timer;

  ToolType toolType = defaultToolType;

  final PanelLeft panelLeft;
  final PanelRight panelRight;

  Play(ClientWebSocket client)
      : cvs = CanvasHelper(client),
        panelLeft = PanelLeft(client),
        panelRight = PanelRight(client),
        super(client) {
    client
      ..on(MessageType.setAsArtist, _setAsArtist)
      ..on(MessageType.setArtist, _setArtist)
      ..on(MessageType.win, _win)
      ..on(MessageType.lose, _lose)
      ..on(MessageType.setCanvasLeftLabel, _setCanvasLeftLabel)
      ..on(MessageType.setCanvasMiddleLabel, _setCanvasMiddleLabel)
      ..on(MessageType.setCanvasRightLabel, _setCanvasRightLabel)
      ..on(MessageType.clearCanvasLabels, _clearCanvasLabels)
      ..on(MessageType.enableDrawNext, _enableDrawNext);
  }

  @override
  void show() {
    playCard.style.display = '';

    playSubs
      ..add(document.onKeyPress.listen((KeyboardEvent e) {
        if (e.keyCode != KeyCode.ENTER) return;

        final guess = chatInput.value.trim();

        if (guess.isNotEmpty) {
          client.send(MessageType.guess, guess);
        }

        chatInput.value = '';
      }))
      ..add(drawNextBtn.onClick.listen((_) {
        if (drawNextBtn.classes.contains('disabled')) return;

        drawNextBtn.classes.add('disabled');

        client.send(MessageType.drawNext);
      }))
      ..add(_invitePlayers());
  }

  @override
  void hide() {
    playCard.style.display = 'none';

    _clearPlaySubs();
    _clearDrawSubs();

    panelLeft.clearPlayers();
    panelRight.clearGuesses();

    client.send(MessageType.exitLobby);
  }

  void _clearPlaySubs() {
    for (var sub in playSubs) {
      sub?.cancel();
    }
    playSubs.clear();
  }

  void _clearDrawSubs() {
    for (var sub in drawSubs) {
      sub?.cancel();
    }
    drawSubs.clear();
  }

  void _drawStart(Brush brush, Point pos) {
    final color = querySelector('#color').text;

    if (toolType == ToolType.BRUSH) {
      brush
        ..pos.x = pos.x
        ..pos.y = pos.y
        ..pressed = true;

      final drawPoint = DrawPoint(color, Brush.defaultSize, brush.pos);

      cvs.drawPoint(drawPoint);
      client.send(MessageType.drawPoint, drawPoint.toJson());

      timer?.cancel();
      timer = Timer.periodic(brushInterval, (_) {
        if (brush.moved) {
          cvs.drawLine(brush.pos);
          client.send(MessageType.drawLine, brush.pos.toJson());

          brush.moved = false;
        }
      });

      undoBtn.classes.remove('disabled');
      clearBtn.classes.remove('disabled');
    } else if (toolType == ToolType.FILL) {
      final fillLayer = FillLayer(pos.x, pos.y, color);

      cvs.addFillLayer(fillLayer);
      client.send(MessageType.fill, fillLayer.toJson());
    }
  }

  void _drawMove(Brush brush, Point pos) {
    if (brush.pressed) {
      brush
        ..pos.x = pos.x
        ..pos.y = pos.y
        ..moved = true;
    }
  }

  void _drawEnd(Brush brush) {
    if (toolType == ToolType.BRUSH) {
      brush
        ..pressed = false
        ..moved = false;

      timer?.cancel();
    }
  }

  StreamSubscription _canvasOnMouseDown(Brush brush) => canvas.onMouseDown.listen((MouseEvent e) {
        final mousePos = _getMousePos(e);

        _drawStart(brush, mousePos);
      });

  StreamSubscription _documentOnMouseMove(Brush brush) =>
      document.onMouseMove.listen((MouseEvent e) {
        final mousePos = _getMousePos(e);

        _drawMove(brush, mousePos);
      });

  StreamSubscription _documentOnMouseUp(Brush brush) => document.onMouseUp.listen((_) {
        _drawEnd(brush);
      });

  Point _getMousePos(MouseEvent e) {
    final rect = canvas.getBoundingClientRect();

    final x = e.page.x - (rect.left + window.pageXOffset);
    final y = e.page.y - (rect.top + window.pageYOffset);

    return Point(x, y);
  }

  StreamSubscription _invitePlayers() => invitePlayersBtn.onClick.listen((_) {
    final text = invitePlayersText.text.trim();

    if (_copyToClipboard(text)) {
      toast('Copied link to clipboard!');
    } else {
      toast('error');
    }
  });

  // made by bergwerf
  // https://gist.github.com/bergwerf/1b427ad2b1f9770b260dd4dac295b6f0
  bool _copyToClipboard(String text) {
    final textArea = TextAreaElement();
    document.body.append(textArea);
    textArea.style.border = '0';
    textArea.style.margin = '0';
    textArea.style.padding = '0';
    textArea.style.opacity = '0';
    textArea.style.position = 'absolute';
    textArea.readOnly = true;
    textArea.value = text;
    textArea.select();
    final result = document.execCommand('copy');
    textArea.remove();
    return result;
  }

//  _canvasOnTouchStart(Brush brush) =>
//      canvas.onTouchStart.listen((TouchEvent e) {
//        e.preventDefault();
//
//        final touchPos = _getTouchPos(e);
//
//        _drawStart(brush, touchPos);
//      });
//
//  _documentOnTouchMove(Brush brush) =>
//      document.onTouchMove.listen((TouchEvent e) {
//        e.preventDefault();
//
//        final touchPos = _getTouchPos(e);
//
//        _drawMove(brush, touchPos);
//      });
//
//  _documentOnTouchEnd(Brush brush) =>
//      document.onTouchEnd.listen((TouchEvent e) {
//        e.preventDefault();
//
//        _drawEnd(brush);
//      });

//  Point _getTouchPos(TouchEvent e) {
//    final rect = canvas.getBoundingClientRect();
//
//    final x = e.touches.first.page.x - (rect.left + window.pageXOffset);
//    final y = e.touches.first.page.y - (rect.top + window.pageYOffset);
//
//    return new Point(x, y);
//  }

  StreamSubscription _undoBtnOnClick() => undoBtn.onClick.listen((_) {
        if (undoBtn.classes.contains('disabled')) return;

        client.send(MessageType.undoLast);
        cvs.undoLast();
      });

  StreamSubscription _clearBtnOnClick() => clearBtn.onClick.listen((_) {
        client.send(MessageType.clearDrawing);
        cvs.clearDrawing();
      });

  StreamSubscription _brushBtnOnClick() => brushBtn.onClick.listen((_) {
        if (brushBtn.classes.contains('disabled')) return;

        toolType = ToolType.BRUSH;

        brushBtn.classes.add('disabled');
        fillBtn.classes.remove('disabled');
      });

//  _fillBtnOnClick() => fillBtn.onClick.listen((_) {
//        if (fillBtn.classes.contains('disabled')) return;
//
//        toolType = ToolType.FILL;
//
//        fillBtn.classes.add('disabled');
//        brushBtn.classes.remove('disabled');
//      });

  void _setAsArtist() {
    querySelector('#color').text = Brush.defaultColor;
    // TODO set default size

    artistOptions.classes
      ..remove('scale-out')
      ..add('scale-in');

    cvs.clearDrawing();

    final brush = Brush();

    drawSubs.addAll([
      // desktop
      _canvasOnMouseDown(brush),
      _documentOnMouseMove(brush),
      _documentOnMouseUp(brush),

      // mobile
//      _canvasOnTouchStart(brush),
//      _documentOnTouchMove(brush),
//      _documentOnTouchEnd(brush),

      // buttons
      _undoBtnOnClick(),
      _clearBtnOnClick(),
      _brushBtnOnClick(),
//      _fillBtnOnClick(),
    ]);
  }

  void _setArtist() {
    artistOptions.classes
      ..remove('scale-in')
      ..add('scale-out');

    cvs.clearDrawing();
    _clearDrawSubs();

    timer?.cancel();

    clearBtn.classes.add('disabled');
    undoBtn.classes.add('disabled');
  }

  void _win() {}

  void _lose() {}

  void _setCanvasLeftLabel(String json) {
    canvasLeftLabel.text = json;
  }

  void _setCanvasMiddleLabel(String json) {
    canvasMiddleLabel.text = json;
  }

  void _setCanvasRightLabel(String json) {
    canvasRightLabel.text = json;
  }

  void _clearCanvasLabels() {
    canvasLeftLabel.text = '';
    canvasMiddleLabel.text = '';
    canvasRightLabel.text = '';
  }

  void _enableDrawNext() {
    drawNextBtn.classes.remove('disabled');
  }
}
