library server;

import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';
import 'package:http_server/http_server.dart';

import 'server_websocket.dart';

import '../web/common/create_lobby_info.dart';
import '../web/common/draw_regex.dart';
import '../web/common/existing_player.dart';
import '../web/common/guess.dart';
import '../web/common/lobby_info.dart';
import '../web/common/login_info.dart';
import '../web/common/message.dart';

part 'data.dart';
part 'game.dart';
part 'lobby.dart';

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

  var parser = new ArgParser();
  parser.addOption('clientFiles', defaultsTo: 'build/web/');

  var results = parser.parse(args);
  var clientFiles = results['clientFiles'];

  var staticFiles = new VirtualDirectory(clientFiles);
  staticFiles
    ..jailRoot = false
    ..allowDirectoryListing = true
    ..directoryHandler = (dir, request) async {
      var indexUri = new Uri.file(dir.path).resolve('index.html');

      var file = new File(indexUri.toFilePath());

      if (await file.exists()) {} else {
        file = new File('index.html');
      }
      staticFiles.serveFile(file, request);
    };

  var server = await HttpServer.bind('0.0.0.0', port);

  print('server started at ${server.address.address}:${server.port}');

  await for (HttpRequest request in server) {
    request.response.headers.set('cache-control', 'no-cache');

    var path = request.uri.path;
    var hasLobby = isValidLobbyName(path.substring(1));

    if (WebSocketTransformer.isUpgradeRequest(request)) {
      var socket = new ServerWebSocket.ugradeRequest(request);

      handleSocket(socket);

      continue;
    }

    if (hasLobby) {
      staticFiles.serveFile(new File('web/index.html'), request);
    } else {
      staticFiles.serveRequest(request);
    }
  }
}

handleSocket(ServerWebSocket socket) async {
  await socket.start();

  socket
    ..on(Message.login, (String username) {
      /////////// check if username exists ///////////
      if (gPlayers.containsValue(username)) {
        socket.send(Message.toast, 'Username taken');
        return null;
      }
      ////////////////////////////////////////////////

      ///////// check if valid name ////////////////
      if (!isValidLobbyName(username)) {
        socket.send(Message.toast, 'Invalid username');
        return null;
      }
      //////////////////////////////////////////////

      gPlayers[socket] = username;

      socket.send(Message.loginSuccesful, '');

      print('$username logged in');

      // send lobby info
      for (var lobby in gLobbies.values) {
        socket.send(Message.lobbyInfo, lobby.getInfo().toJson());
      }
    })
    ..on(Message.createLobby, (String json) {
      var createLobbyInfo = new CreateLobbyInfo.fromJson(json);

      ////////// check if lobby exists /////////////
      if (gLobbies.containsKey(createLobbyInfo.name)) {
        socket.send(Message.toast, 'Lobby already exists');
        return null;
      }
      //////////////////////////////////////////////

      ///////// check if valid name ////////////////
      if (!isValidLobbyName(createLobbyInfo.name)) {
        socket.send(Message.toast, 'Invalid lobby name');
        return null;
      }
      //////////////////////////////////////////////

      print('new lobby ${createLobbyInfo.toJson()}');

      var lobby = new Lobby(createLobbyInfo);
      gLobbies[createLobbyInfo.name] = lobby;

      for (var otherSocket in gPlayers.keys) {
        otherSocket.send(Message.lobbyInfo, lobby.getInfo().toJson());
      }

      gPlayerLobby[socket] = lobby;
      lobby.addPlayer(socket, gPlayers[socket]);
      socket.send(Message.enterLobbySuccessful, lobby.name);
    })
    ..on(Message.enterLobby, (String lobbyName) {
      ////////// check if lobby exists ////////////////
      if (!gLobbies.containsKey(lobbyName)) {
        socket.send(Message.toast, 'Lobby doesn\'t exist');
        socket.send(Message.enterLobbyFailure, '');
        return null;
      }

      var lobby = gLobbies[lobbyName];

      if (lobby.hasPassword) {
        socket.send(Message.requestPassword, lobbyName);
        return null;
      }

      gPlayerLobby[socket] = lobby;
      lobby.addPlayer(socket, gPlayers[socket]);
      socket.send(Message.enterLobbySuccessful, lobbyName);
    })
    ..on(Message.enterLobbyWithPassword, (String json) {
      var loginInfo = new LoginInfo.fromJson(json);

      if (!gLobbies.containsKey(loginInfo.lobbyName)) {
        socket.send(Message.toast, 'Lobby doesn\'t exist');
        socket.send(Message.enterLobbyFailure, '');
        return null;
      }

      var lobby = gLobbies[loginInfo.lobbyName];

      if (lobby.hasPassword && lobby.password != loginInfo.password) {
        socket.send(Message.toast, 'Password is incorrect');
        socket.send(Message.enterLobbyFailure, '');
        return null;
      }

      gPlayerLobby[socket] = lobby;
      lobby.addPlayer(socket, gPlayers[socket]);
      socket.send(Message.enterLobbySuccessful, loginInfo.lobbyName);
    })
    ..on(Message.drawNext, (_) {
      if (!gPlayerLobby.containsKey(socket)) return null;

      var lobby = gPlayerLobby[socket];
      lobby.game.addToQueue(socket);
    })
    ..on(Message.guess, (String json) {
      if (!gPlayerLobby.containsKey(socket)) return null;

      var lobby = gPlayerLobby[socket];

      var guess = new Guess()
        ..username = gPlayers[socket]
        ..guess = json;

      lobby.game.onGuess(socket, guess);
    })
    ..on(Message.drawPoint, (String json) {
      var lobby = gPlayerLobby[socket];
      lobby?.sendToAll(Message.drawPoint, json, except: socket);
    })
    ..on(Message.drawLine, (String json) {
      var lobby = gPlayerLobby[socket];
      lobby?.sendToAll(Message.drawLine, json, except: socket);
    })
    ..on(Message.clearDrawing, (String json) {
      var lobby = gPlayerLobby[socket];
      lobby?.sendToAll(Message.clearDrawing, json, except: socket);
    })
    ..on(Message.undoLast, (String json) {
      var lobby = gPlayerLobby[socket];
      lobby?.sendToAll(Message.undoLast, json, except: socket);
    })
    ..on(Message.changeColor, (String json) {
      var lobby = gPlayerLobby[socket];
      lobby?.sendToAll(Message.changeColor, json, except: socket);
    })
    ..on(Message.changeSize, (String json) {
      var lobby = gPlayerLobby[socket];
      lobby?.sendToAll(Message.changeSize, json, except: socket);
    });

  // on socket disconnect
  await socket.done;

  // check if player was logged in
  if (!gPlayers.containsKey(socket)) return;

  // check if player was in a lobby
  if (gPlayerLobby.containsKey(socket)) {
    var lobby = gPlayerLobby.remove(socket);
    lobby.removePlayer(socket);

    // close lobby if empty
    if (lobby.players.isEmpty) {
      print('closed lobby ${lobby.name}');
      gLobbies.remove(lobby.name);

      // tell all players
      for (var sk in gPlayers.keys) {
        sk.send(Message.lobbyClosed, lobby.name);
      }
    }
  }

  var username = gPlayers.remove(socket);
  print('$username logged out');
}

bool isValidLobbyName(String lobbyName) {
  var lobbyMatches = lobbyNameRegex.firstMatch(lobbyName);

  return lobbyMatches != null && lobbyMatches[0] == lobbyName;
}
