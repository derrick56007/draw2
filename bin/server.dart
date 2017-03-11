library server;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:args/args.dart';
import 'package:http_server/http_server.dart';

import 'server_websocket.dart';

import '../web/common/create_lobby_info.dart';
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

main(List<String> args) async {
  int port;

  if (Platform.environment['PORT'] == null) {
    port = 8080;
  } else {
    port = int.parse(Platform.environment['PORT']);
  }

  var parser = new ArgParser();
  parser.addOption('clientFiles', defaultsTo: 'web');

  var results = parser.parse(args);
  var clientFiles = results['clientFiles'];

  var staticFiles = new VirtualDirectory(clientFiles);
  staticFiles
    ..allowDirectoryListing = true
    ..directoryHandler = (dir, request) {
      var indexUri = new Uri.file(dir.path).resolve('index.html');

      staticFiles.serveFile(new File(indexUri.toFilePath()), request);
    };

  var regex = new RegExp(r"/^[a-zA-Z0-9_-]{4,16}$/");

  var server = await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port);

  print('server started at ${server.address.address}:${server.port}');

  await for (HttpRequest request in server) {
    request.response.headers.set('cache-control', 'no-cache');

    if (WebSocketTransformer.isUpgradeRequest(request)) {
      var path = request.uri.path;
      var lobbyName = regex.firstMatch(path.substring(1, path.length));

      if (lobbyName != null) {
        // lobby
      }

      var socket = new ServerWebSocket.ugradeRequest(request);
      handleSocket(socket);

      continue;
    }

    staticFiles.serveRequest(request);
  }
}

handleSocket(ServerWebSocket socket, {String urlLobbyName}) async {
  await socket.start();

  socket
    ..on(Message.login, (String username) {
      /////////// check if username exists ///////////
      if (gPlayers.containsValue(username)) {
        socket.send(Message.toast, 'Username taken');
        return null;
      }
      ////////////////////////////////////////////////

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
    ..on(Message.changeColor, (String json) {
      var lobby = gPlayerLobby[socket];
      lobby?.sendToAll(Message.changeColor, json, except: socket);
    })
    ..on(Message.changeSize, (String json) {
      var lobby = gPlayerLobby[socket];
      lobby?.sendToAll(Message.changeSize, json, except: socket);
    });

  await socket.done;

  // remove logged in player
  if (!gPlayers.containsKey(socket)) return;
  var username = gPlayers.remove(socket);
  print('$username logged out');

  // remove from lobby
  if (!gPlayerLobby.containsKey(socket)) return;
  var lobby = gPlayerLobby.remove(socket);
  lobby.removePlayer(socket);

  // close lobby if empty
  if (lobby.players.isNotEmpty) return;
  print('closed lobby ${lobby.name}');
  gLobbies.remove(lobby.name);

  // tell all players
  for (var sk in gPlayers.keys) {
    sk.send(Message.lobbyClosed, lobby.name);
  }
}
