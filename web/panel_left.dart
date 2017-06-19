part of play;

class PanelLeft {
  final Element playerListCollection = querySelector('#player-list-collection');

  final ClientWebSocket client;

  PanelLeft(this.client) {
    client
      ..on(Message.newPlayer, (x) => _newPlayer(x, 0))
      ..on(Message.existingPlayer, (x) => _existingPlayer(x))
      ..on(Message.removePlayer, (x) => _removePlayer(x))
      ..on(Message.setQueue, (x) => _setQueue(x))
      ..on(Message.setPlayerOrder, (x) => _setPlayerOrder(x))
      ..on(Message.updatePlayerScore, (x) => _updatePlayerScore(x));
  }

  _newPlayerItem(String name, int score) => new Element.html('''
      <a id="player-$name" class="collection-item player-item">
        <span id="player-$name-queue-number" class="queue-number"></span>
        <span id="player-$name-score" class="player-score">$score</span>
        $name
      </a>''');

  _newPlayer(String name, int score) {
    var playerItem = _newPlayerItem(name, score);

    playerListCollection.children.add(playerItem);
  }

  _existingPlayer(String json) {
    var existingPlayer = new ExistingPlayer.fromJson(json);

    _newPlayer(existingPlayer.username, existingPlayer.score);
  }

  _removePlayer(String name) {
    querySelector('#player-$name')?.remove();
  }

  _setQueue(String json) {
    for (var el in playerListCollection.children) {
      var queueNumber = el.querySelectorAll('.queue-number').first;
      queueNumber.text = '';
    }

    var queue = JSON.decode(json) as List;

    for (var player in queue) {
      var name = player[0];
      querySelector('#player-$name-queue-number')?.text = '${player[1]}';
    }
  }

  _setPlayerOrder(String json) {
    var order = JSON.decode(json) as List;
    for (var name in order.reversed) {
      var el = querySelector('#player-$name');

      if (el == null) continue;

      el.remove();
      playerListCollection.children.insert(0, el);
    }
  }

  _updatePlayerScore(String json) {
    var playerScore = JSON.decode(json) as List;
    var name = playerScore[0];
    var score = playerScore[1];

    querySelector('#player-$name-score')?.text = '$score';
  }
}
