library server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' hide Point;

import 'package:args/args.dart';
import 'package:http_server/http_server.dart';

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
import '../../web/common/message.dart';
import '../../web/common/point.dart';

part '../logic/game.dart';
part '../logic/lobby.dart';
part '../logic/word_similarity.dart';
part '../server/server_websocket.dart';
part '../server/socket_receiver.dart';

var gLobbies = <String, Lobby>{};
var gPlayers = <ServerWebSocket, String>{};
var gPlayerLobby = <ServerWebSocket, Lobby>{};

var defaultLobbies = <Lobby>[];

var lobbyNameRegex = new RegExp(DrawRegExp.lobbyName);

main(List<String> args) async {
  int port;

  if (Platform.environment['PORT'] == null) {
    port = 8080;
  } else {
    port = int.parse(Platform.environment['PORT']);
  }

  WordBase.init();
  initDefaultLobbies();

  parser.addOption('clientFiles', defaultsTo: 'build/web/');
  final parser = new ArgParser();

  final results = parser.parse(args);
  final clientFiles = results['clientFiles'];

  final defaultPage = new File('$clientFiles/index.html');

  final staticFiles = new VirtualDirectory(clientFiles);
  staticFiles
    ..jailRoot = false
    ..allowDirectoryListing = true
    ..directoryHandler = (dir, request) async {
      final indexUri = new Uri.file(dir.path).resolve('index.html');

      var file = new File(indexUri.toFilePath());

      if (!(await file.exists())) {
        file = defaultPage;
      }
      staticFiles.serveFile(file, request);
    };

  final server = await HttpServer.bind('0.0.0.0', port);

  print('server started at ${server.address.address}:${server.port}');

  await for (HttpRequest request in server) {
    request.response.headers.set('cache-control', 'no-cache');

    final path = request.uri.path.trim();

    final hasLobby = isValidLobbyName(path.substring(1));

    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = new ServerWebSocket.ugradeRequest(request);

      new SocketReceiver.handle(socket);

      continue;
    }

    if (hasLobby) {
      staticFiles.serveFile(defaultPage, request);
    } else {
      staticFiles.serveRequest(request);
    }
  }
}

bool isValidLobbyName(String lobbyName) {
  final lobbyMatches = lobbyNameRegex.firstMatch(lobbyName);

  return lobbyMatches != null && lobbyMatches[0] == lobbyName;
}

initDefaultLobbies() {
  final createLobbyInfo1 = const CreateLobbyInfo('lobby1', '', true, 15);
  final createLobbyInfo2 = const CreateLobbyInfo('lobby2', '', true, 15);
  final createLobbyInfo3 = const CreateLobbyInfo('lobby3', '', true, 15);

  gLobbies[createLobbyInfo1.name] = new Lobby(createLobbyInfo1);
  gLobbies[createLobbyInfo2.name] = new Lobby(createLobbyInfo2);
  gLobbies[createLobbyInfo3.name] = new Lobby(createLobbyInfo3);

  defaultLobbies.addAll(gLobbies.values);
}
