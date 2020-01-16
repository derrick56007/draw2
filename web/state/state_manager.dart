part of state;

class StateManager {
  static final shared =  StateManager._internal();

  final _states = <String, State>{};

  StateManager._internal() {
    window.onPopState.listen((PopStateEvent e) {
      final stateName = e.state.toString();

      _showState(stateName);
    });
  }

  Iterable<String> get keys => _states.keys;

  void addAll(Map<String, State> states) => _states.addAll(states);

  void pushState(String stateName, [String path]) {
    if (!_states.containsKey(stateName)) {
      print('No such state!');
      return;
    }

    if (path == null) {
      window.history.pushState(stateName, null, stateName);
    } else {
      window.history.pushState(stateName, null, path);
    }

    _showState(stateName);
  }

  void _showState(String stateName) {
    if (!_states.containsKey(stateName)) {
      print('No such state!');
      return;
    }

    _states.forEach((name, state) {
      if (stateName != name) {
        state.hide();
      }
    });

    _states[stateName].show();
  }
}
