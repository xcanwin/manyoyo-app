import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/app/widgets.dart';
import 'package:manyoyo_app/core/api_client.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _syncingText = false;
  String? _error;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
    _loadConfig();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (_syncingText || _dirty) {
      return;
    }
    if (mounted) {
      setState(() => _dirty = true);
    }
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = context.read<ApiClient>();
      final resp = await client.get<Map<String, dynamic>>('/api/config');
      final raw =
          resp.data?['raw'] as String? ??
          resp.data?['content'] as String? ??
          '';
      _syncingText = true;
      _controller.text = raw;
      _syncingText = false;
      _dirty = false;
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final client = context.read<ApiClient>();
      await client.put<dynamic>(
        '/api/config',
        data: {'content': _controller.text},
      );
      if (mounted) setState(() => _dirty = false);
    } catch (e) {
      if (mounted) setState(() => _saveError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DarkPageScaffold(
      header: _buildTopBar(),
      body: Column(
        children: [
          if (_saveError != null)
            Container(
              width: double.infinity,
              color: kErrorBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _saveError!,
                style: const TextStyle(
                  color: kDarkErrorText,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return DarkPageHeader(
      title: 'config',
      subtitle: 'manyoyo.json5 editor',
      onBack: () => context.go('/sessions'),
      leading: const Icon(Icons.tune_rounded, size: 16, color: kDarkAccent),
      actions: [
        if (_dirty)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kDarkAccent,
            ),
          ),
        FilledButton(
          onPressed: (_saving || !_dirty || _loading) ? null : _saveConfig,
          style: FilledButton.styleFrom(
            backgroundColor: kDarkAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            _saving ? '保存中...' : '保存',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: kDarkAccent),
        ),
      );
    }
    if (_error != null) {
      return DarkStateMessage(
        icon: Icons.settings_backup_restore_rounded,
        title: '配置读取失败',
        detail: _error!,
        actionLabel: '重试',
        onAction: _loadConfig,
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: kMutedPanel,
          child: const Text(
            '// JSON5 配置文件 — 敏感字段用 ***HIDDEN_SECRET*** 占位，保存时不会覆盖原始值',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: kDarkTextLow,
              height: 1.4,
            ),
          ),
        ),
        const Divider(color: kDarkBorder, height: 1),
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: kDarkTextHigh,
              height: 1.55,
            ),
            decoration: const InputDecoration(
              filled: true,
              fillColor: kEditorBg,
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            textAlignVertical: TextAlignVertical.top,
          ),
        ),
      ],
    );
  }
}
