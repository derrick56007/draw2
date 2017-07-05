part of server;

class ValidateString {
  static final _lobbyNameRegex = new RegExp(DrawRegExp.lobbyName);

  static final _usernameRegex = new RegExp(DrawRegExp.username);

  static bool isValidLobbyName(String lobbyName) {
    final lobbyMatches = _lobbyNameRegex.firstMatch(lobbyName);

    return lobbyMatches != null && lobbyMatches[0] == lobbyName;
  }

  static bool isValidUsername(String username) {
    final usernameMatches = _usernameRegex.firstMatch(username);

    return usernameMatches != null && usernameMatches[0] == username;
  }
}