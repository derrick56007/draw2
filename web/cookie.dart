import 'dart:convert';
import 'dart:html';

class Cookie {
  static reset() {
    document.cookie = '{}';
  }

  static set(String key, dynamic val) {
    if (document.cookie.isEmpty) reset();

    Map map = JSON.decode(document.cookie) as Map;
    map[key] = val;
    document.cookie = JSON.encode(map);
  }

  static get(String key, {dynamic ifNull}) {
    if (document.cookie.isEmpty) reset();

    Map map = JSON.decode(document.cookie) as Map;
    return map[key] == null ? ifNull : map[key];
  }
}
