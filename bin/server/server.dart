library server;

import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';
import 'package:http_server/http_server.dart';

import '../word_base/word_base.dart';

import '../../web/common/canvas_layer.dart';
import '../../web/common/create_lobby_info.dart';
import '../../web/common/draw_point.dart';
import '../../web/common/draw_regex.dart';
import '../../web/common/draw_websocket.dart';
import '../../web/common/existing_player.dart';
import '../../web/common/guess.dart';
import '../../web/common/lobby_info.dart';
import '../../web/common/login_info.dart';
import '../../web/common/message.dart';
import '../../web/common/point.dart';

part '../logic/game.dart';
part '../logic/lobby.dart';
part '../server/server_websocket.dart';
part '../server/socket_receiver.dart';

var gLobbies = <String, Lobby>{};
var gPlayers = <ServerWebSocket, String>{};
var gPlayerLobby = <ServerWebSocket, Lobby>{};

var lobbyNameRegex = new RegExp(DrawRegExp.lobbyName);

main(List<String> args) async {
  int port;

  if (Platform.environment['PORT'] == null) {
    port = 8080;
  } else {
    port = int.parse(Platform.environment['PORT']);
  }

  WordBase.init();

  var parser = new ArgParser();
  parser.addOption('clientFiles', defaultsTo: 'build/web/');

  var results = parser.parse(args);
  var clientFiles = results['clientFiles'];

  var defaultPage = new File('$clientFiles/index.html');

  var staticFiles = new VirtualDirectory(clientFiles);
  staticFiles
    ..jailRoot = false
    ..allowDirectoryListing = true
    ..directoryHandler = (dir, request) async {
      var indexUri = new Uri.file(dir.path).resolve('index.html');

      var file = new File(indexUri.toFilePath());

      if (!(await file.exists())) {
        file = defaultPage;
      }
      staticFiles.serveFile(file, request);
    };

  var server = await HttpServer.bind('0.0.0.0', port);

  print('server started at ${server.address.address}:${server.port}');

  await for (HttpRequest request in server) {
    request.response.headers.set('cache-control', 'no-cache');

    var path = request.uri.path.trim();

    var hasLobby = isValidLobbyName(path.substring(1));

    if (WebSocketTransformer.isUpgradeRequest(request)) {
      var socket = new ServerWebSocket.ugradeRequest(request);

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
  var lobbyMatches = lobbyNameRegex.firstMatch(lobbyName);

  return lobbyMatches != null && lobbyMatches[0] == lobbyName;
}
