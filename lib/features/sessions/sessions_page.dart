import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:manyoyo_app/core/auth_notifier.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MANYOYO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '退出登录',
            onPressed: () async {
              context.read<AuthNotifier>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('会话列表加载中...'),
      ),
    );
  }
}
