library server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' hide Point;

import 'package:args/args.dart';
import 'package:http_server/http_server.dart';
import 'package:pedantic/pedantic.dart';

import '../word_base/word_base.dart';

import '../../web/common/brush_layer.dart';
import '../../web/common/canvas_layer.dart';
import '../../web/common/create_lobby_info.dart';
import '../../web/common/draw_point.dart';
import '../../web/common/draw_regex.dart';
import '../../web/common/draw_websocket.dart';
import '../../web/common/existing_player.dart';
import '../../web/common/fill_layer.dart';
import '../../web/common/guess.dart';
import '../../web/common/lobby_info.dart';
import '../../web/common/login_info.dart';
import '../../web/common/message_type.dart';
import '../../web/common/point.dart';

part '../logic/game.dart';

part '../logic/lobby.dart';

part '../logic/word_similarity.dart';

part '../server/login_manager.dart';

part '../server/server_websocket.dart';

part '../server/socket_receiver.dart';

part '../server/validate_string.dart';

void main(List<String> args) async {
  int port;

  if (Platform.environment['PORT'] == null) {
    port = 8080;
  } else {
    port = int.parse(Platform.environment['PORT']);
  }

  WordBase.init();

  createDefaultLobbies();

  final parser = ArgParser();
  parser.addOption('clientFiles', defaultsTo: 'build/');

  final results = parser.parse(args);
  final clientFiles = results['clientFiles'];

  final defaultPage = File('$clientFiles/index.html');

  final staticFiles = VirtualDirectory(clientFiles);
  staticFiles
    ..jailRoot = false
    ..allowDirectoryListing = true
    ..directoryHandler = (dir, request) async {
      final indexUri = Uri.file(dir.path).resolve('index.html');

      var file = File(indexUri.toFilePath());

      if (!(await file.exists())) {
        file = defaultPage;
      }
      staticFiles.serveFile(file, request);
    };

  final server = await HttpServer.bind('0.0.0.0', port);

  print('server started at ${server.address.address}:${server.port}');

  unawaited(server.forEach((HttpRequest request) async {
    request.response.headers.set('cache-control', 'no-cache');

    final path = request.uri.path.trim();

    final pathHasValidLobbyName =
        ValidateString.isValidLobbyName(path.substring(1));

    // handle websocket connection
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = ServerWebSocket.upgradeRequest(request);

      SocketReceiver.handle(socket);
    } else {
      // handle path with lobby name
      if (pathHasValidLobbyName) {
        staticFiles.serveFile(defaultPage, request);
      } else {
        await staticFiles.serveRequest(request);
      }
    }
  }));
}

void createDefaultLobbies() {
  LoginManager.shared
    ..addLobby(Lobby('lobby0', isDefaultLobby: true))
    ..addLobby(Lobby('lobby1', isDefaultLobby: true))
    ..addLobby(Lobby('lobby2', isDefaultLobby: true))
    ..addLobby(Lobby('lobby3', isDefaultLobby: true));
}
