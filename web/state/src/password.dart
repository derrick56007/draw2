part of state;

class Password {
  static final Element passwordCard = querySelector('#password-card');
  static final InputElement passwordField = querySelector('#enter-lobby-password');

  static StreamSubscription submitButtonSub;
  static StreamSubscription enterToSubmitSub;

  static Future<String> show() {
    final completer = new Completer<String>();

    submitButtonSub = querySelector('#enter-lobby-password-btn').onClick.listen((_) {
      hide();

      completer.complete(getPassword());
    });

    passwordCard.style.display = '';

    passwordField.autofocus = true;

    enterToSubmitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        hide();

        completer.complete(getPassword());
      }
    });

    return completer.future;
  }

  static hide() {
    passwordCard.style.display = 'none';

    submitButtonSub?.cancel();
    enterToSubmitSub?.cancel();
  }

  static String getPassword() => passwordField.value.trim();
}
