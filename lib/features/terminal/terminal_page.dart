import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart' hide TerminalController;

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/app/widgets.dart';
import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/features/terminal/terminal_controller.dart';

// Terminal uses a slightly darker background than other dark pages.
const _kBg = Color(0xFF0D1511);

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
    _controller.disconnect();
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
        backgroundColor: _kBg,
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
      leading: const Icon(
        Icons.terminal_rounded,
        size: 16,
        color: kDarkAccentDim,
      ),
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
      child: TerminalView(
        controller.terminal,
        theme: const TerminalTheme(
          cursor: Color(0xFF3DDB87),
          selection: Color(0x440B6E4F),
          foreground: Color(0xFFE8F5EE),
          background: Color(0xFF0D1511),
          black: Color(0xFF0D1511),
          red: Color(0xFFE06C5B),
          green: Color(0xFF3DDB87),
          yellow: Color(0xFFE5C07B),
          blue: Color(0xFF61AFEF),
          magenta: Color(0xFFC678DD),
          cyan: Color(0xFF56B6C2),
          white: Color(0xFFABB2BF),
          brightBlack: Color(0xFF3D5446),
          brightRed: Color(0xFFE06C5B),
          brightGreen: Color(0xFF98C379),
          brightYellow: Color(0xFFE5C07B),
          brightBlue: Color(0xFF61AFEF),
          brightMagenta: Color(0xFFC678DD),
          brightCyan: Color(0xFF56B6C2),
          brightWhite: Color(0xFFE8F5EE),
          searchHitBackground: Color(0xFF0B6E4F),
          searchHitBackgroundCurrent: Color(0xFF3DDB87),
          searchHitForeground: Color(0xFF0D1511),
        ),
        textStyle: const TerminalStyle(fontSize: 13.5, fontFamily: 'monospace'),
        padding: const EdgeInsets.all(8),
        autofocus: true,
      ),
    );
  }
}
