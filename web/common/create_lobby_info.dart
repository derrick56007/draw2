part of common;

@serializable
class CreateLobbyInfo extends JsonObject {
  String name;
  String password;
  bool hasTimer;
  int maxPlayers;

  CreateLobbyInfo();

  factory CreateLobbyInfo.fromJson(String json) =>
      JsonObject.serializer.decode(json, CreateLobbyInfo);
}
