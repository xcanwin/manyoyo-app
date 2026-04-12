import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/core/server_config.dart';
import 'package:manyoyo_app/features/setup/desktop_auto_serve.dart';

const String _manyoyoServerUrl = String.fromEnvironment(
  'MANYOYO_SERVER_URL',
  defaultValue: '',
);

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> with WidgetsBindingObserver {
  final _serverConfig = ServerConfig();
  final _urlController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _checking = false;
  String? _statusMessage;
  bool? _reachable;
  Process? _desktopServerProcess;
  bool _desktopAutoServeOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (shouldAutoServeOnDesktop()) {
      _startAutoServe();
    } else {
      _loadInitialUrl();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _desktopServerProcess?.kill();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUrl() async {
    final saved = await _serverConfig.loadUrl();
    final initial =
        saved.isNotEmpty ? saved : _manyoyoServerUrl.trim();
    if (!mounted) return;
    setState(() {
      _urlController.text = initial;
      _loading = false;
    });
  }

  Future<void> _startAutoServe() async {
    if (mounted) {
      setState(() {
        _statusMessage = '正在启动本地 MANYOYO 服务...';
        _reachable = null;
      });
    }
    try {
      final result = await startDesktopAutoServe(onLog: (_) {});
      _desktopServerProcess = result.process;

      if (!mounted) return;
      setState(() {
        _urlController.text = result.baseUrl;
        _loading = false;
        _reachable = true;
        _statusMessage = '本地 MANYOYO 服务已启动，正在进入客户端。';
      });

      await _serverConfig.saveUrl(result.baseUrl);

      if (!_desktopAutoServeOpened && mounted) {
        _desktopAutoServeOpened = true;
        context.go('/login');
      }
    } catch (error) {
      _desktopServerProcess?.kill();
      _desktopServerProcess = null;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _reachable = false;
        _statusMessage = '桌面端自动启动 MANYOYO 服务失败：$error';
      });
    }
  }

  String get _currentUrl => _urlController.text.trim();

  bool get _hasConfiguredUrl => _currentUrl.isNotEmpty;

  String get _connectionStageLabel => switch (_reachable) {
    true => '服务在线',
    false => '等待修复',
    null when _hasConfiguredUrl => '等待检测',
    _ => '尚未配置',
  };

  String get _connectionSummary => switch (_reachable) {
    true => '地址已可访问，可以直接进入 MANYOYO。',
    false => '最近一次检测失败，请确认 MANYOYO 服务已启动。',
    null when _hasConfiguredUrl => '地址已填写，建议先检测连接，再进入 MANYOYO。',
    _ => '先填入 MANYOYO 地址，再保存并进入。',
  };

  Color get _badgeColor => switch (_reachable) {
    true => kGreenBadge,
    false => kRedBadge,
    _ => kNeutralBadge,
  };

  Uri? _parseUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri;
  }

  Future<void> _saveUrl() async {
    final value = _currentUrl;
    setState(() {
      _saving = true;
      _statusMessage = null;
    });
    try {
      await _serverConfig.saveUrl(value);
      if (!mounted) return;
      setState(() {
        _statusMessage = value.isEmpty ? '已清空本地 MANYOYO 地址。' : '已保存 MANYOYO 地址。';
        _reachable = null;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _checkConnection() async {
    final uri = _parseUrl(_currentUrl);
    if (uri == null) {
      setState(() {
        _statusMessage = '请输入合法的 MANYOYO 地址，例如 http://127.0.0.1:3000';
        _reachable = false;
      });
      return;
    }
    setState(() {
      _checking = true;
      _statusMessage = '正在检测连接...';
      _reachable = null;
    });
    try {
      final reachable = await probeManyoyo(uri);
      if (!mounted) return;
      setState(() {
        _reachable = reachable;
        _statusMessage = reachable ? '连接成功，服务已响应。' : '服务不可用，请检查地址和服务状态。';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _reachable = false;
        _statusMessage = '连接失败：$error';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _enterManyoyo() {
    final uri = _parseUrl(_currentUrl);
    if (uri == null) {
      setState(() {
        _statusMessage = '请输入合法的 MANYOYO 地址，例如 http://127.0.0.1:3000';
        _reachable = false;
      });
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = switch (_reachable) {
      true => kPrimarySeed,
      false => kErrorText,
      _ => kTextLight,
    };

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.22),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x330F2A22),
                          blurRadius: 32,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBadge(colorScheme, textTheme),
                          const SizedBox(height: 18),
                          Text(
                            'MANYOYO 原生客户端',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: kTextDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '纯 Flutter 原生 UI，直接消费 MANYOYO 后端 API，支持 macOS、Windows、iOS、Android。',
                            style: textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              color: kTextMid,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildStatusCard(textTheme),
                          const SizedBox(height: 18),
                          _buildUrlCard(colorScheme, textTheme, statusColor),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: const [
                              _PlatformChip(label: 'macOS'),
                              _PlatformChip(label: 'Windows'),
                              _PlatformChip(label: 'iOS'),
                              _PlatformChip(label: 'Android'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'MANYOYO NATIVE',
        style: textTheme.labelSmall?.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStatusCard(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3F8F5), Color(0xFFE8F1EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _connectionStageLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF173429),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 460,
            child: Text(
              _connectionSummary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: const Color(0xFF42524B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlCard(
    ColorScheme colorScheme,
    TextTheme textTheme,
    Color statusColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前 MANYOYO 地址',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF284238),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _urlController,
            enabled: !_loading,
            decoration: const InputDecoration(
              hintText: 'http://127.0.0.1:3000',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () {
                        _urlController.text = 'http://127.0.0.1:3000';
                        setState(() {
                          _statusMessage = '已填入本机默认地址。';
                          _reachable = null;
                        });
                      },
                child: const Text('填入本机地址'),
              ),
              FilledButton(
                onPressed: _loading || _saving ? null : _saveUrl,
                child: Text(_saving ? '保存中...' : '保存地址'),
              ),
              OutlinedButton(
                onPressed: _loading || _checking ? null : _checkConnection,
                child: Text(_checking ? '检测中...' : '检测连接'),
              ),
              FilledButton(
                onPressed: _loading ? null : _enterManyoyo,
                child: const Text('进入 MANYOYO'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _statusMessage ??
                '可通过 --dart-define=MANYOYO_SERVER_URL=https://... 提供默认地址；桌面端可通过 MANYOYO_DESKTOP_AUTO_SERVE=1 自动拉起本地服务。',
            style: textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kTextDark,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
