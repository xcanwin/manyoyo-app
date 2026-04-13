import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:manyoyo_app/core/api_client.dart';

const _kBg = Color(0xFF0F1A14);
const _kSurface = Color(0xFF172217);
const _kBorder = Color(0xFF2B4035);
const _kAccent = Color(0xFF3DDB87);
const _kAccentDim = Color(0xFF0B6E4F);
const _kTextHigh = Color(0xFFE8F5EE);
const _kTextMid = Color(0xFF7FA88E);
const _kTextLow = Color(0xFF3D5446);
const _kErrorText = Color(0xFFE06C5B);

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
  String? _error;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = context.read<ApiClient>();
      final resp = await client.get<Map<String, dynamic>>('/api/config');
      final raw = resp.data?['raw'] as String?
          ?? resp.data?['content'] as String?
          ?? '';
      _controller.text = raw;
      _controller.addListener(() {
        if (!_dirty) setState(() => _dirty = true);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() { _saving = true; _saveError = null; });
    try {
      final client = context.read<ApiClient>();
      await client.put<dynamic>('/api/config', data: {'content': _controller.text});
      if (mounted) setState(() => _dirty = false);
    } catch (e) {
      if (mounted) setState(() => _saveError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildTopBar(),
          if (_saveError != null)
            Container(
              width: double.infinity,
              color: const Color(0xFF2D1A18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _saveError!,
                style: const TextStyle(
                  color: _kErrorText,
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
          const Icon(Icons.tune_rounded, size: 14, color: _kAccentDim),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'config',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: _kTextHigh,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_dirty)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _kAccent,
              ),
            ),
          FilledButton(
            onPressed: (_saving || !_dirty || _loading) ? null : _saveConfig,
            style: FilledButton.styleFrom(
              backgroundColor: _kAccentDim,
              foregroundColor: _kTextHigh,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              _saving ? '保存中...' : '保存',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: _kTextMid, fontSize: 13)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadConfig,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kAccent,
                side: const BorderSide(color: _kAccentDim),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('retry', style: TextStyle(fontFamily: 'monospace')),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: const Color(0xFF0F1A14),
          child: const Text(
            '// JSON5 配置文件 — 敏感字段用 ***HIDDEN_SECRET*** 占位，保存时不会覆盖原始值',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: _kTextLow,
              height: 1.4,
            ),
          ),
        ),
        const Divider(color: _kBorder, height: 1),
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: _kTextHigh,
              height: 1.55,
            ),
            decoration: const InputDecoration(
              filled: true,
              fillColor: _kBg,
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
