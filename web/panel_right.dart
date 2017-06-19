part of play;

class PanelRight {
  static const maxChatLength = 20;

  final Element chatList = querySelector('#chat-list');

  final ClientWebSocket client;

  PanelRight(this.client) {
    client
      ..on(Message.guess, (x) => _guess(x));
  }

  _addToChat(String username, String text) {
    var el = new Element.html('''
      <a class="collection-item chat-item">
        <div class="chat-username">$username</div>
        <div class="chat-text">$text</div>
      </a>''');

    chatList
      ..children.add(el)
      ..scrollTop = chatList.scrollHeight;

    if (chatList.children.length < maxChatLength) return;

    chatList.children.removeAt(0);
  }

  _guess(String json) {
    var guess = new Guess.fromJson(json);

    _addToChat(guess.username, guess.guess);
  }
}