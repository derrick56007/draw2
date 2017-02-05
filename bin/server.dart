library server;

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'dart:math';
import 'package:args/args.dart';
import 'package:force/force_serverside.dart';

import '../web/common/common.dart';

part 'data.dart';
part 'game.dart';
part 'lobby.dart';

main(List<String> args) async {
  int port;

  if (Platform.environment['PORT'] == null) {
    port = 8080;
  } else {
    port = int.parse(Platform.environment['PORT']);
  }

  var parser = new ArgParser();
  parser.addOption('clientFiles', defaultsTo: '../web/');

  var results = parser.parse(args);
  var clientFiles = results['clientFiles'];

  var server = new ForceServer(
      host: '0.0.0.0',
      port: port,
      clientFiles: clientFiles,
      startPage: 'index.html');

  await server.start();

  print('Started server');

  var lobbies = <String, Lobby>{};
  var players = <String>[];

  Lobby lobbyFromProfile(Map profile) {
    var name = profile['name'];
    if (name == null) return null;

    var lobbyName = profile['lobby'];
    if (lobbyName == null) return null;

    return lobbies[lobbyName];
  }

  server
    ..onProfileChanged.listen((ForceProfileEvent e) {
      ////////// on disconnected ///////////////
      if (e.type == ForceProfileType.Removed) {
        var lobby = lobbyFromProfile(e.profileInfo);
        if (lobby == null) return;

        var name = e.profileInfo['name'];
        lobby.removePlayer(name);
        players.remove(name);

        if (lobby.game.players.isEmpty) {
          lobbies.remove(lobby.name);

          server.broadcast(Message.lobbyClosed, lobby.name);

          print('Closed lobby ${lobby.name}');
        }
      }
      //////////////////////////////////////////
    })
    ..on(Message.login, (mp, sender) {
      var username = mp.json;

      /////////// check if username exists ///////////
      if (players.contains(username)) {
        sender.reply(Message.toast, 'Username taken');
        return;
      }
      ////////////////////////////////////////////////

      players.add(username);
      sender.reply(Message.loginSuccesful, username);

      print('$username logged in');
    })
    ..on(Message.requestLobbyList, (_, sender) {
      // TODO cache this data

      for (Lobby lobby in lobbies.values) {
        sender.reply(Message.lobbyOpened, lobby.getInfo().toJson());
      }
    })
    ..on(Message.createLobby, (mp, sender) {
      var createLobbyInfo = new CreateLobbyInfo.fromJson(mp.json);

      ////////// check if lobby exists /////////////
      if (lobbies.containsKey(createLobbyInfo.name)) {
        sender.reply(Message.toast, 'Lobby already exists');
        return;
      }
      //////////////////////////////////////////////

      var lobby = new Lobby(server, createLobbyInfo);
      lobbies[createLobbyInfo.name] = lobby;

      sender.reply(Message.createLobbySuccessful, createLobbyInfo.name);

      server.broadcast(Message.lobbyOpened, lobby.getInfo().toJson());
    })
    ..on(Message.enterLobby, (mp, sender) {
      var loginInfo = new LoginInfo.fromJson(mp.json);

      ////////// check if lobby exists ////////////////
      if (!lobbies.containsKey(loginInfo.lobbyName)) {
        sender.reply(Message.toast, 'Lobby doesn\'t exist');
        sender.reply(Message.enterLobbyFailure, '');
        return;
      }
      ////////////////////////////////////////////////

      /////////////// check password /////////////////
      var lobby = lobbies[loginInfo.lobbyName];

      if (lobby.hasPassword && lobby.password != loginInfo.password) {
        sender.reply(Message.toast, 'Password is incorrect');
        sender.reply(Message.enterLobbyFailure, '');
        return;
      }
      ////////////////////////////////////////////////

      // add player
      lobby.addPlayer(loginInfo.username);
      players.add(loginInfo.username);

      sender.reply(Message.enterLobbySuccessful, lobby.name);
    })
    ..on(Message.guess, (mp, _) {
      var lobby = lobbyFromProfile(mp.profile);
      if (lobby == null) return;

      var guess = new Guess()
        ..username = mp.profile['name']
        ..guess = mp.json;

      lobby.onGuess(guess);
    })
    ..on(Message.drawPoint, (mp, _) {
      var lobby = lobbyFromProfile(mp.profile);
      lobby?.sendToAll(Message.drawPoint, mp.json, except: mp.profile['name']);
    })
    ..on(Message.drawLine, (mp, _) {
      var lobby = lobbyFromProfile(mp.profile);
      lobby?.sendToAll(Message.drawLine, mp.json, except: mp.profile['name']);
    })
    ..on(Message.changeColor, (mp, _) {
      var lobby = lobbyFromProfile(mp.profile);
      lobby?.sendToAll(Message.changeColor, mp.json,
          except: mp.profile['name']);
    })
    ..on(Message.changeSize, (mp, _) {
      var lobby = lobbyFromProfile(mp.profile);
      lobby?.sendToAll(Message.changeSize, mp.json, except: mp.profile['name']);
    });
}
