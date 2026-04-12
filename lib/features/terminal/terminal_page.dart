import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TerminalPage extends StatelessWidget {
  const TerminalPage({super.key, required this.sessionRef});

  final String sessionRef;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sessionRef),
        leading: BackButton(onPressed: () => context.go('/sessions')),
      ),
      body: const Center(child: Text('终端 — 开发中')),
    );
  }
}
