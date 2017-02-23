library server;

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


var lobbies = <String, Lobby>{};
var players = <ServerWebSocket, String>{};
var playerLobby = <ServerWebSocket, Lobby>{};

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

  var server = await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port);

  await for (HttpRequest request in server) {
    var uri = request.uri.path;

    if (uri == '/ws') {
      var socket = new ServerWebSocket.ugradeRequest(request);
      await socket.start();

      // TODO
      handleSocket(socket, false);

      continue;
    } else if (uri.length > 1 &&
        !uri.contains(' ') &&
        !uri.contains('/', 1) &&
        !uri.contains('.') &&
        !uri.contains('\\')) {
      // lobby
    }

    staticFiles.serveRequest(request);
  }
}

handleSocket(ServerWebSocket socket, bool onPlayPage) async {
  socket
    ..on(Message.login, (String username) {
      /////////// check if username exists ///////////
      if (players.containsValue(username)) {
        socket.send(Message.toast, 'Username taken');
        return null;
      }
      ////////////////////////////////////////////////

      players[socket] = username;

      socket.send(Message.loginSuccesful, username);

      print('$username logged in');
    })
    ..on(Message.requestLobbyList, (_) {
      // TODO cache data
      for (Lobby lobby in lobbies.values) {
        socket.send(Message.lobbyOpened, lobby.getInfo().toJson());
      }
    })
    ..on(Message.createLobby, (String json) {
      var createLobbyInfo = new CreateLobbyInfo.fromJson(json);

      ////////// check if lobby exists /////////////
      if (lobbies.containsKey(createLobbyInfo.name)) {
        socket.send(Message.toast, 'Lobby already exists');
        return null;
      }
      //////////////////////////////////////////////

      print('Created lobby ${createLobbyInfo.toJson()}');

      var lobby = new Lobby(createLobbyInfo);
      lobbies[createLobbyInfo.name] = lobby;

      lobby.sendToAll(Message.lobbyOpened, lobby.getInfo().toJson());

      playerLobby[socket] = lobby;
      lobby.addPlayer(socket, players[socket]);
      socket.send(Message.enterLobbySuccessful, lobby.name);
    })
    ..on(Message.enterLobby, (String lobbyName) {
      ////////// check if lobby exists ////////////////
      if (!lobbies.containsKey(lobbyName)) {
        socket.send(Message.toast, 'Lobby doesn\'t exist');
        socket.send(Message.enterLobbyFailure, '');
        return null;
      }

      var lobby = lobbies[lobbyName];

      playerLobby[socket] = lobby;
      lobby.addPlayer(socket, players[socket]);
      socket.send(Message.enterLobbySuccessful, lobbyName);
    })
    ..on(Message.enterLobbyWithPassword, (String json) {
      var loginInfo = new LoginInfo.fromJson(json);

      if (!lobbies.containsKey(loginInfo.lobbyName)) {
        socket.send(Message.toast, 'Lobby doesn\'t exist');
        socket.send(Message.enterLobbyFailure, '');
        return null;
      }

      var lobby = lobbies[loginInfo.lobbyName];

      if (lobby.hasPassword && lobby.password != loginInfo.password) {
        socket.send(Message.toast, 'Password is incorrect');
        socket.send(Message.enterLobbyFailure, '');
        return null;
      }

      playerLobby[socket] = lobby;
      lobby.addPlayer(socket, players[socket]);
      socket.send(Message.enterLobbySuccessful, loginInfo.lobbyName);
    })
    ..on(Message.guess, (String json) {
      var lobby = playerLobby[socket];
      if (lobby == null) return null;

      var guess = new Guess()
        ..username = players[socket]
        ..guess = json;

      lobby.onGuess(socket, guess);
    })
    ..on(Message.drawPoint, (String json) {
      var lobby = playerLobby[socket];
      lobby?.sendToAll(Message.drawPoint, json, except: socket);
    })
    ..on(Message.drawLine, (String json) {
      var lobby = playerLobby[socket];
      lobby?.sendToAll(Message.drawLine, json, except: socket);
    })
    ..on(Message.changeColor, (String json) {
      var lobby = playerLobby[socket];
      lobby?.sendToAll(Message.changeColor, json, except: socket);
    })
    ..on(Message.changeSize, (String json) {
      var lobby = playerLobby[socket];
      lobby?.sendToAll(Message.changeSize, json, except: socket);
    });

  if (onPlayPage) {
    await socket.done;

    playerLobby.remove(socket);
    print('${players.remove(socket)} logged out');

    var lobby = playerLobby[socket];
    if (lobby == null) return;
    lobby.removePlayer(socket);
  }
}

broadcast(String request, dynamic val) {
  for (ServerWebSocket socket in players.keys) {
    socket.send(request, val);
  }
}
