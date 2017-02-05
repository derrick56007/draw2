part of common;

@serializable
class LobbyInfo extends JsonObject {
  String name;
  bool hasPassword;
  bool hasTimer;
  int numberOfPlayers;
  int maxPlayers;

  LobbyInfo();

  factory LobbyInfo.fromJson(String json) =>
      JsonObject.serializer.decode(json, LobbyInfo);
}
