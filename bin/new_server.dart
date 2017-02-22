library server;

import '../web/common/create_lobby_info.dart';
import '../web/common/guess.dart';
import '../web/common/login_info.dart';
import 'dart:io';

import '../web/common/message.dart';
import 'dart:async';
import 'dart:math';

import '../web/common/existing_player.dart';
import '../web/common/lobby_info.dart';
import 'server_websocket.dart';

import 'package:http_server/http_server.dart';

part 'data.dart';
part 'game.dart';
part 'lobby.dart';

var lobbies = <String, Lobby>{};
Map<ServerWebSocket, String> players = {};
Map<ServerWebSocket, Lobby> playerLobby = {};

main() async {
  var staticFiles = new VirtualDirectory('web');
  staticFiles
    ..allowDirectoryListing = true
    ..directoryHandler = (dir, request) {
      var indexUri = new Uri.file(dir.path).resolve('views/login.html');

      staticFiles.serveFile(new File(indexUri.toFilePath()), request);
    };

  var server = await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8080);

  await for (HttpRequest request in server) {
    var uri = request.uri.path;

    if (uri == '/ws') {
      var socket = new ServerWebSocket.ugradeRequest(request);
      await socket.start();

      // TODO
      handleSocket(socket, false);
    } else if (uri == '/create' || uri == '/lobbies') {
      staticFiles.serveFile(new File('web/views${uri}.html'), request);
    } else if (uri.length > 1 &&
        !uri.contains(' ') &&
        !uri.contains('/', 1) &&
        !uri.contains('.') &&
        !uri.contains('\\')) {
      // lobby
      staticFiles.serveFile(new File('web/views/play.html'), request);
    } else {
      staticFiles.serveRequest(request);
    }
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

      socket.send(Message.loginSuccesful, '');

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

      socket.send(Message.createLobbySuccessful, createLobbyInfo.name);

      lobby.sendToAll(Message.lobbyOpened, lobby.getInfo().toJson());
    })
    ..on(Message.enterLobby, (String json) {
      var loginInfo = new LoginInfo.fromJson(json);

      ////////// check if lobby exists ////////////////
      if (!lobbies.containsKey(loginInfo.lobbyName)) {
        socket.send(Message.toast, 'Lobby doesn\'t exist');
        socket.send(Message.enterLobbyFailure, '');
        return null;
      }
      ////////////////////////////////////////////////

      /////////////// check password /////////////////
      var lobby = lobbies[loginInfo.lobbyName];

      if (lobby.hasPassword && lobby.password != loginInfo.password) {
        socket.send(Message.toast, 'Password is incorrect');
        socket.send(Message.enterLobbyFailure, '');
        return null;
      }
      ////////////////////////////////////////////////

      socket.send(Message.enterLobbySuccessful, lobby.name);
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
    })
    ..on(Message.handshake, (String json) {
      var loginInfo = new LoginInfo.fromJson(json);

      var lobby = lobbies[loginInfo.lobbyName];

      // add player
      lobby.addPlayer(socket, loginInfo.username);
      players[socket] = loginInfo.username;
      playerLobby[socket] = lobby;

      socket.send(Message.handshakeSuccessful, '');
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
