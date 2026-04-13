import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart' hide TerminalController;

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/app/widgets.dart';
import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/features/terminal/terminal_controller.dart';

const _kTerminalPanel = Color(0xFF102033);

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key, required this.sessionRef});

  final String sessionRef;

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage>
    with WidgetsBindingObserver {
  late final TerminalController _controller;
  late final ApiClient _client;
  String? _error;
  bool _connecting = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _client = context.read<ApiClient>();
    _controller = TerminalController();
    _connect();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.disconnect());
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final ref = Uri.encodeComponent(widget.sessionRef);
      final wsPath = '/api/sessions/$ref/terminal/ws?cols=120&rows=36';
      final wsBase = _client.baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
      final cookieHeader = await _client.getCookieHeader();
      await _controller.connect(
        wsUrl: '$wsBase$wsPath',
        cookieHeader: cookieHeader,
        cols: 120,
        rows: 36,
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  void didChangeMetrics() {
    // Re-send resize on window size change (desktop/tablet).
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    // Estimate cols/rows from window size (approx 8×16 px per cell).
    final cols = (size.width / 8).floor().clamp(40, 240);
    final rows = ((size.height - 80) / 16).floor().clamp(12, 80);
    _controller.resize(cols, rows);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TerminalController>.value(
      value: _controller,
      child: DarkPageScaffold(
        header: _TopBar(sessionRef: widget.sessionRef, onReconnect: _connect),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_connecting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kDarkAccent,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'connecting...',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: kDarkTextLow,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return DarkStateMessage(
        icon: Icons.portable_wifi_off_rounded,
        title: '终端连接失败',
        detail: _error!,
        actionLabel: '重新连接',
        onAction: _connect,
      );
    }

    return _TerminalView(controller: _controller);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.sessionRef, required this.onReconnect});

  final String sessionRef;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    return DarkPageHeader(
      title: sessionRef,
      subtitle: 'live terminal',
      onBack: () => context.go('/sessions'),
      leading: const Icon(Icons.terminal_rounded, size: 16, color: kDarkAccent),
      tabs: buildSessionTabs(
        context: context,
        sessionRef: sessionRef,
        current: SessionPageSection.terminal,
      ),
      actions: [
        Consumer<TerminalController>(
          builder: (context, ctrl, child) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ctrl.isConnected ? kDarkAccent : kDarkTextLow,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                ctrl.isConnected ? 'connected' : 'disconnected',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: ctrl.isConnected ? kDarkAccent : kDarkTextLow,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        DarkIconBtn(
          icon: Icons.refresh_rounded,
          tooltip: '重新连接',
          onTap: onReconnect,
        ),
      ],
    );
  }
}

class _TerminalView extends StatelessWidget {
  const _TerminalView({required this.controller});

  final TerminalController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        decoration: BoxDecoration(
          color: _kTerminalPanel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF29405A)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A243956),
              blurRadius: 24,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: TerminalView(
            controller.terminal,
            theme: const TerminalTheme(
              cursor: Color(0xFF9DDBFF),
              selection: Color(0x66356EA5),
              foreground: Color(0xFFEFF6FF),
              background: _kTerminalPanel,
              black: _kTerminalPanel,
              red: Color(0xFFFF8D8D),
              green: Color(0xFF8DE0A6),
              yellow: Color(0xFFFFD58A),
              blue: Color(0xFF8FC5FF),
              magenta: Color(0xFFE0B3FF),
              cyan: Color(0xFF7FE0E3),
              white: Color(0xFFD8E6F7),
              brightBlack: Color(0xFF5F7896),
              brightRed: Color(0xFFFFA6A6),
              brightGreen: Color(0xFFAEF1BF),
              brightYellow: Color(0xFFFFE3A6),
              brightBlue: Color(0xFFB1D6FF),
              brightMagenta: Color(0xFFEBC6FF),
              brightCyan: Color(0xFFA4F4F0),
              brightWhite: Color(0xFFF8FBFF),
              searchHitBackground: Color(0xFF355C8E),
              searchHitBackgroundCurrent: Color(0xFF6EA7FF),
              searchHitForeground: Color(0xFFF8FBFF),
            ),
            textStyle: const TerminalStyle(
              fontSize: 13.5,
              fontFamily: 'monospace',
            ),
            padding: const EdgeInsets.all(12),
            autofocus: true,
          ),
        ),
      ),
    );
  }
}
