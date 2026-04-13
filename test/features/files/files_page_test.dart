import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/features/files/files_page.dart';

class _FilesAdapter implements HttpClientAdapter {
  final List<RequestOptions> captured = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured.add(options);

    if (options.path == '/api/sessions/demo/detail') {
      return ResponseBody.fromString(
        jsonEncode({
          'detail': {
            'containerPath': '/workspace/custom',
            'applied': {'containerPath': '/workspace/custom'},
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (options.path == '/api/sessions/demo/fs/list') {
      return ResponseBody.fromString(
        jsonEncode({
          'path': '/workspace/custom',
          'entries': [
            {
              'name': 'docs',
              'path': '/workspace/custom/docs',
              'kind': 'directory',
            },
            {
              'name': 'README.md',
              'path': '/workspace/custom/README.md',
              'kind': 'file',
              'size': 128,
            },
          ],
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'error': 'not found'}),
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MemoryCookieJar implements CookieJar {
  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) async {}

  @override
  Future<void> deleteAll() async {}

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async => const [];

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {}
}

void main() {
  testWidgets('FilesPage loads list from session containerPath', (tester) async {
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:3000',
      cookieJar: _MemoryCookieJar(),
    );
    final adapter = _FilesAdapter();
    client.testDio.httpClientAdapter = adapter;

    await tester.pumpWidget(
      Provider<ApiClient>.value(
        value: client,
        child: const MaterialApp(
          home: FilesPage(sessionRef: 'demo'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('/workspace/custom'), findsOneWidget);
    expect(find.text('docs'), findsOneWidget);
    expect(find.text('README.md'), findsOneWidget);

    final detailRequest = adapter.captured.firstWhere(
      (request) => request.path == '/api/sessions/demo/detail',
    );
    final listRequest = adapter.captured.firstWhere(
      (request) => request.path == '/api/sessions/demo/fs/list',
    );

    expect(detailRequest.method, equals('GET'));
    expect(listRequest.queryParameters['path'], equals('/workspace/custom'));
  });
}
