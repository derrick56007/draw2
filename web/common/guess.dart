part of common;

@serializable
class Guess extends JsonObject {
  String username;
  String guess;

  Guess();

  factory Guess.fromJson(String json) =>
      JsonObject.serializer.decode(json, Guess);
}
