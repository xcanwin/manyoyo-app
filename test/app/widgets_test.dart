import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/app/widgets.dart';

void main() {
  testWidgets('DarkPageHeader renders title, tabs, and actions', (
    tester,
  ) async {
    var backTapped = false;
    var filesTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          backgroundColor: kDarkBg,
          body: DarkPageHeader(
            title: 'session-a',
            subtitle: 'agent chat',
            onBack: () => backTapped = true,
            tabs: [
              const DarkPageTab(
                label: '聊天',
                icon: Icons.chat_bubble_outline_rounded,
                selected: true,
              ),
              DarkPageTab(
                label: '文件',
                icon: Icons.folder_open_rounded,
                onTap: () => filesTapped = true,
              ),
            ],
            actions: [
              DarkIconBtn(
                icon: Icons.refresh_rounded,
                tooltip: '刷新',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('session-a'), findsOneWidget);
    expect(find.text('agent chat'), findsOneWidget);
    expect(find.text('聊天'), findsOneWidget);
    expect(find.text('文件'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pump();
    expect(backTapped, isTrue);

    await tester.tap(find.text('文件'));
    await tester.pump();
    expect(filesTapped, isTrue);
  });

  testWidgets('DarkStateMessage renders title, detail, and action', (
    tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          backgroundColor: kDarkBg,
          body: DarkStateMessage(
            icon: Icons.error_outline_rounded,
            title: '服务不可用',
            detail: '请检查 MANYOYO 是否已启动。',
            actionLabel: '重试',
            onAction: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('服务不可用'), findsOneWidget);
    expect(find.text('请检查 MANYOYO 是否已启动。'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(retried, isTrue);
  });
}
