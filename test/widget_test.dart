import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/core/auth_notifier.dart';
import 'package:manyoyo_app/core/server_config.dart';
import 'package:manyoyo_app/features/setup/setup_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('setup page renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthNotifier>(
            create: (_) => AuthNotifier(),
          ),
          Provider<ServerConfig>(create: (_) => ServerConfig()),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const SetupPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('MANYOYO 原生客户端'), findsOneWidget);
    expect(find.text('当前 MANYOYO 地址'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('填入本机地址'), findsOneWidget);
    expect(find.text('保存地址'), findsOneWidget);
    expect(find.text('检测连接'), findsOneWidget);
    expect(find.text('进入 MANYOYO'), findsOneWidget);
    expect(find.text('macOS'), findsOneWidget);
    expect(find.text('Windows'), findsOneWidget);
    expect(find.text('iOS'), findsOneWidget);
    expect(find.text('Android'), findsOneWidget);
  });
}
