import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/core/auth_notifier.dart';
import 'package:manyoyo_app/features/sessions/sessions_page.dart';

import '../../helpers/stub_adapter.dart';

void main() {
  testWidgets('creating a session closes sheet without controller disposal errors', (
    tester,
  ) async {
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:3000',
      cookieJar: CookieJar(),
    );
    client.testDio.httpClientAdapter = StubAdapter(
      statusCode: 200,
      body: jsonEncode({'containers': []}),
      headers: {
        'content-type': ['application/json'],
      },
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthNotifier>(
            create: (_) => AuthNotifier(),
          ),
          Provider<ApiClient>.value(value: client),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const SessionsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'demo-session');
    await tester.tap(find.text('Create'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
