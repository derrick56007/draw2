part of play;

class PanelRight {
  static const maxChatLength = 20;

  final Element chatList = querySelector('#chat-list');

  final ClientWebSocket client;

  PanelRight(this.client) {
    client.on(MessageType.guess, _guess);
  }

  Element _newChatItem(String username, String text) => Element.html('''
      <a class="collection-item chat-item">
        <div class="chat-username">$username</div>
        <div class="chat-text">$text</div>
      </a>''');

  void _addToChat(Element chatItem) {
    chatList
      ..children.add(chatItem)
      ..scrollTop = chatList.scrollHeight;

    if (chatList.children.length < maxChatLength) return;

    chatList.children.removeAt(0);
  }

  void _guess(String json) {
    final guess = Guess.fromJson(json);

    final chatItem = _newChatItem(guess.username, guess.guess);
    _addToChat(chatItem);
  }

  void clearGuesses() => chatList.children.clear();
}
