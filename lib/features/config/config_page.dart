import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置'),
        leading: BackButton(onPressed: () => context.go('/sessions')),
      ),
      body: const Center(child: Text('配置编辑 — 开发中')),
    );
  }
}
