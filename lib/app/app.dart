import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cookie_jar/cookie_jar.dart';

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/core/auth_notifier.dart';
import 'package:manyoyo_app/core/server_config.dart';
import 'package:manyoyo_app/features/setup/setup_page.dart';
import 'package:manyoyo_app/features/auth/login_page.dart';
import 'package:manyoyo_app/features/sessions/sessions_page.dart';
import 'package:manyoyo_app/features/chat/chat_page.dart';
import 'package:manyoyo_app/features/terminal/terminal_page.dart';
import 'package:manyoyo_app/features/files/files_page.dart';
import 'package:manyoyo_app/features/config/config_page.dart';

class ManyoyoApp extends StatefulWidget {
  const ManyoyoApp({super.key});

  @override
  State<ManyoyoApp> createState() => _ManyoyoAppState();
}

class _ManyoyoAppState extends State<ManyoyoApp> {
  late final AuthNotifier _authNotifier;
  late final ApiClient _apiClient;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _authNotifier = AuthNotifier();
    _init();
  }

  Future<void> _init() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(
      storage: FileStorage('${appDir.path}/.cookies/'),
    );
    final serverConfig = ServerConfig();
    final baseUrl = await serverConfig.loadUrl();
    _apiClient = ApiClient(
      baseUrl: baseUrl.isNotEmpty ? baseUrl : 'http://127.0.0.1:3000',
      cookieJar: cookieJar,
    );
    _apiClient.authNotifier = _authNotifier;
    if (mounted) setState(() => _ready = true);
  }

  late final GoRouter _router = GoRouter(
    refreshListenable: _authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = _authNotifier.isLoggedIn;
      final onSetup = state.matchedLocation == '/setup';
      final onLogin = state.matchedLocation == '/login';

      if (onSetup) return null;
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/sessions';
      return null;
    },
    routes: [
      GoRoute(path: '/setup', builder: (_, __) => const SetupPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/sessions', builder: (_, __) => const SessionsPage()),
      GoRoute(
        path: '/sessions/:ref/chat',
        builder: (_, state) => ChatPage(
          sessionRef: state.pathParameters['ref']!,
        ),
      ),
      GoRoute(
        path: '/sessions/:ref/term',
        builder: (_, state) => TerminalPage(
          sessionRef: state.pathParameters['ref']!,
        ),
      ),
      GoRoute(
        path: '/sessions/:ref/files',
        builder: (_, state) => FilesPage(
          sessionRef: state.pathParameters['ref']!,
        ),
      ),
      GoRoute(path: '/config', builder: (_, __) => const ConfigPage()),
    ],
    initialLocation: '/setup',
  );

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: _authNotifier),
        Provider<ApiClient>.value(value: _apiClient),
        Provider<ServerConfig>(create: (_) => ServerConfig()),
      ],
      child: MaterialApp.router(
        title: 'MANYOYO',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: _router,
      ),
    );
  }
}
