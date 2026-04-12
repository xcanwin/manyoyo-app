import 'package:flutter_test/flutter_test.dart';
import 'package:manyoyo_app/core/server_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads empty url when no value saved', () async {
    final config = ServerConfig();
    final url = await config.loadUrl();
    expect(url, isEmpty);
  });

  test('saves and reloads url', () async {
    final config = ServerConfig();
    await config.saveUrl('http://127.0.0.1:3000');
    final url = await config.loadUrl();
    expect(url, equals('http://127.0.0.1:3000'));
  });

  test('clears url when saving empty string', () async {
    SharedPreferences.setMockInitialValues({
      'manyoyo_server_url': 'http://192.168.1.1:3000',
    });
    final config = ServerConfig();
    await config.saveUrl('');
    final url = await config.loadUrl();
    expect(url, isEmpty);
  });

  test('trims whitespace from saved url', () async {
    final config = ServerConfig();
    await config.saveUrl('  http://127.0.0.1:3000  ');
    final url = await config.loadUrl();
    expect(url, equals('http://127.0.0.1:3000'));
  });
}
