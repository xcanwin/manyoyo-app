import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/core/auth_notifier.dart';
import 'package:manyoyo_app/features/auth/login_page.dart';

import '../../helpers/stub_adapter.dart';

@GenerateMocks([CookieJar])
import 'login_page_test.mocks.dart';

ApiClient makeClient({required int loginStatus}) {
  final cookieJar = MockCookieJar();
  when(cookieJar.loadForRequest(any)).thenAnswer((_) async => []);
  when(cookieJar.saveFromResponse(any, any)).thenAnswer((_) async {});

  final client = ApiClient(
    baseUrl: 'http://127.0.0.1:3000',
    cookieJar: cookieJar,
  );
  client.testDio.httpClientAdapter = StubAdapter(statusCode: loginStatus);
  return client;
}

Widget buildLoginPage({
  required ApiClient apiClient,
  required AuthNotifier authNotifier,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/sessions',
        builder: (context, state) => const Scaffold(body: Text('sessions')),
      ),
    ],
    initialLocation: '/login',
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
      Provider<ApiClient>.value(value: apiClient),
    ],
    child: MaterialApp.router(theme: buildTheme(), routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('login page shows username and password fields', (tester) async {
    final authNotifier = AuthNotifier();
    final client = makeClient(loginStatus: 200);

    await tester.pumpWidget(
      buildLoginPage(apiClient: client, authNotifier: authNotifier),
    );
    await tester.pump();

    expect(find.text('登录'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('修改服务器地址'), findsOneWidget);
  });

  testWidgets('shows error when fields empty on submit', (tester) async {
    final authNotifier = AuthNotifier();
    final client = makeClient(loginStatus: 200);

    await tester.pumpWidget(
      buildLoginPage(apiClient: client, authNotifier: authNotifier),
    );
    await tester.pump();

    await tester.tap(find.text('登录').last);
    await tester.pump();

    expect(find.text('请输入用户名和密码。'), findsOneWidget);
  });

  testWidgets('successful login sets auth state and navigates to sessions', (
    tester,
  ) async {
    final authNotifier = AuthNotifier();
    final client = makeClient(loginStatus: 200);

    await tester.pumpWidget(
      buildLoginPage(apiClient: client, authNotifier: authNotifier),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'admin');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.text('登录').last);
    await tester.pumpAndSettle();

    expect(authNotifier.isLoggedIn, isTrue);
    expect(find.text('sessions'), findsOneWidget);
  });

  testWidgets('failed login shows error message', (tester) async {
    final authNotifier = AuthNotifier();
    final client = makeClient(loginStatus: 401);

    await tester.pumpWidget(
      buildLoginPage(apiClient: client, authNotifier: authNotifier),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'wrong');
    await tester.enterText(find.byType(TextField).last, 'wrong');
    await tester.tap(find.text('登录').last);
    await tester.pumpAndSettle();

    expect(authNotifier.isLoggedIn, isFalse);
    expect(find.textContaining('密码错误'), findsOneWidget);
  });
}
