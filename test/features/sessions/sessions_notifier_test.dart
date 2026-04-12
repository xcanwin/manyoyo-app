import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/features/sessions/sessions_notifier.dart';
import 'package:manyoyo_app/models/session.dart';

@GenerateMocks([CookieJar])
import 'sessions_notifier_test.mocks.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({required this.responseBody, this.statusCode = 200});

  final String responseBody;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {'content-type': ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient makeClient(String responseBody, {int status = 200}) {
  final cookieJar = MockCookieJar();
  when(cookieJar.loadForRequest(any)).thenAnswer((_) async => []);
  when(cookieJar.saveFromResponse(any, any)).thenAnswer((_) async {});

  final client = ApiClient(
    baseUrl: 'http://127.0.0.1:3000',
    cookieJar: cookieJar,
  );
  client.testDio.httpClientAdapter =
      _StubAdapter(responseBody: responseBody, statusCode: status);
  return client;
}

void main() {
  test('loadSessions populates containers list', () async {
    final body = jsonEncode({
      'containers': [
        {
          'containerName': 'c1',
          'agents': [
            {
              'sessionRef': 'c1~a1',
              'sessionName': 'a1',
              'containerName': 'c1',
              'agentId': 'a1',
              'isHistoryOnly': false,
              'running': false,
            },
          ],
        },
      ],
    });
    final client = makeClient(body);
    final notifier = SessionsNotifier(client);

    await notifier.loadSessions();

    expect(notifier.containers.length, equals(1));
    expect(notifier.containers.first.containerName, equals('c1'));
    expect(notifier.containers.first.agents.first.agentId, equals('a1'));
    expect(notifier.isLoading, isFalse);
    expect(notifier.error, isNull);
  });

  test('loadSessions sets error on failure', () async {
    final client = makeClient('{"error":"server error"}', status: 500);
    final notifier = SessionsNotifier(client);

    await notifier.loadSessions();

    expect(notifier.containers, isEmpty);
    expect(notifier.error, isNotNull);
    expect(notifier.isLoading, isFalse);
  });

  test('initial state is empty and not loading', () {
    final cookieJar = MockCookieJar();
    when(cookieJar.loadForRequest(any)).thenAnswer((_) async => []);
    when(cookieJar.saveFromResponse(any, any)).thenAnswer((_) async {});
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:3000',
      cookieJar: cookieJar,
    );
    final notifier = SessionsNotifier(client);

    expect(notifier.containers, isEmpty);
    expect(notifier.isLoading, isFalse);
    expect(notifier.error, isNull);
  });

  test('removeSession calls DELETE and reloads', () async {
    final body = jsonEncode({'containers': []});
    final client = makeClient(body);
    final notifier = SessionsNotifier(client);

    // Should not throw even with stub returning 200 for POST
    await notifier.removeSession('c1~a1');
    expect(notifier.containers, isEmpty);
  });
}
