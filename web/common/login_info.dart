part of common;

@serializable
class LoginInfo extends JsonObject {
  String username;
  String lobbyName;
  String password;

  LoginInfo();

  factory LoginInfo.fromJson(String json) =>
      JsonObject.serializer.decode(json, LoginInfo);
}
