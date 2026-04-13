import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/features/terminal/terminal_controller.dart';

const _kBg = Color(0xFF0D1511);
const _kSurface = Color(0xFF172217);
const _kBorder = Color(0xFF2B4035);
const _kAccent = Color(0xFF3DDB87);
const _kAccentDim = Color(0xFF0B6E4F);
const _kTextHigh = Color(0xFFE8F5EE);
const _kTextMid = Color(0xFF7FA88E);
const _kTextLow = Color(0xFF3D5446);

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key, required this.sessionRef});

  final String sessionRef;

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> with WidgetsBindingObserver {
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
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            _TopBar(sessionRef: widget.sessionRef, onReconnect: _connect),
            Expanded(child: _buildBody()),
          ],
        ),
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
                color: _kAccent,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'connecting...',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: _kTextLow,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ERR',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 24,
                  color: Color(0xFFE06C5B),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _kTextMid, height: 1.5),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _connect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kAccent,
                  side: const BorderSide(color: _kAccentDim),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'reconnect',
                  style: TextStyle(fontFamily: 'monospace', letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ),
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
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 6,
        left: 8,
        right: 12,
        bottom: 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: _kTextMid, size: 20),
            onPressed: () => context.go('/sessions'),
            tooltip: '返回',
          ),
          const SizedBox(width: 4),
          const Icon(Icons.terminal_rounded, size: 14, color: _kAccentDim),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              sessionRef,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: _kTextMid,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Consumer<TerminalController>(
            builder: (_, ctrl, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ctrl.isConnected ? _kAccent : _kTextLow,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  ctrl.isConnected ? 'connected' : 'disconnected',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: ctrl.isConnected ? _kAccent : _kTextLow,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.refresh_rounded,
            tooltip: '重新连接',
            onTap: onReconnect,
          ),
        ],
      ),
    );
  }
}

class _TerminalView extends StatelessWidget {
  const _TerminalView({required this.controller});

  final TerminalController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
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
        textStyle: const TerminalStyle(
          fontSize: 13.5,
          fontFamily: 'monospace',
        ),
        padding: const EdgeInsets.all(8),
        autofocus: true,
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: _kTextMid),
        ),
      ),
    );
  }
}
