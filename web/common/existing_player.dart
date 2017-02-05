part of common;

@serializable
class ExistingPlayer extends JsonObject {
  String username;
  int score;

  ExistingPlayer();

  factory ExistingPlayer.fromJson(String json) =>
      JsonObject.serializer.decode(json, ExistingPlayer);
}
