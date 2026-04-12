import 'package:shared_preferences/shared_preferences.dart';

const String _serverUrlKey = 'manyoyo_server_url';

class ServerConfig {
  Future<String> loadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_serverUrlKey) ?? '').trim();
  }

  Future<void> saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_serverUrlKey);
    } else {
      await prefs.setString(_serverUrlKey, trimmed);
    }
  }
}
