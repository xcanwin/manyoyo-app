import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/core/auth_notifier.dart';

@GenerateMocks([CookieJar])
import 'api_client_test.mocks.dart';

// Mock HTTP adapter that returns a fixed status code.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode);

  final int statusCode;
  final List<RequestOptions> captured = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured.add(options);
    return ResponseBody.fromString('', statusCode);
  }

  @override
  void close({bool force = false}) {}
}

ApiClient makeClient({AuthNotifier? authNotifier, int stubStatus = 200}) {
  final cookieJar = MockCookieJar();
  when(cookieJar.loadForRequest(any)).thenAnswer((_) async => []);
  when(cookieJar.saveFromResponse(any, any)).thenAnswer((_) async {});

  final adapter = _StubAdapter(stubStatus);
  final client = ApiClient(
    baseUrl: 'http://127.0.0.1:3000',
    cookieJar: cookieJar,
  );
  client.testDio.httpClientAdapter = adapter;
  if (authNotifier != null) client.authNotifier = authNotifier;
  return client;
}

void main() {
  test('X-Requested-With header is injected on every request', () async {
    final cookieJar = MockCookieJar();
    when(cookieJar.loadForRequest(any)).thenAnswer((_) async => []);
    when(cookieJar.saveFromResponse(any, any)).thenAnswer((_) async {});

    final adapter = _StubAdapter(200);
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:3000',
      cookieJar: cookieJar,
    );
    client.testDio.httpClientAdapter = adapter;

    await client.get<dynamic>('/api/sessions');

    expect(adapter.captured, isNotEmpty);
    expect(
      adapter.captured.first.headers['X-Requested-With'],
      equals('XMLHttpRequest'),
    );
  });

  test('401 response triggers AuthNotifier.logout()', () async {
    final authNotifier = AuthNotifier()..setLoggedIn(true);
    final client = makeClient(authNotifier: authNotifier, stubStatus: 401);

    expect(authNotifier.isLoggedIn, isTrue);
    try {
      await client.get<dynamic>('/api/sessions');
    } catch (_) {}
    expect(authNotifier.isLoggedIn, isFalse);
  });

  test('non-401 errors do not trigger logout', () async {
    final authNotifier = AuthNotifier()..setLoggedIn(true);
    final client = makeClient(authNotifier: authNotifier, stubStatus: 500);

    try {
      await client.get<dynamic>('/api/sessions');
    } catch (_) {}
    expect(authNotifier.isLoggedIn, isTrue);
  });

  test('200 response does not trigger logout', () async {
    final authNotifier = AuthNotifier()..setLoggedIn(true);
    final client = makeClient(authNotifier: authNotifier, stubStatus: 200);

    await client.get<dynamic>('/api/sessions');
    expect(authNotifier.isLoggedIn, isTrue);
  });
}
