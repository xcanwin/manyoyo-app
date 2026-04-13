import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/models/fs_entry.dart';

const _kBg = Color(0xFF0F1A14);
const _kSurface = Color(0xFF172217);
const _kBorder = Color(0xFF2B4035);
const _kAccent = Color(0xFF3DDB87);
const _kAccentDim = Color(0xFF0B6E4F);
const _kTextHigh = Color(0xFFE8F5EE);
const _kTextMid = Color(0xFF7FA88E);
const _kTextLow = Color(0xFF3D5446);
const _kErrorText = Color(0xFFE06C5B);

class FileViewerPage extends StatefulWidget {
  const FileViewerPage({
    super.key,
    required this.sessionRef,
    required this.entry,
    required this.client,
  });

  final String sessionRef;
  final FsEntry entry;
  final ApiClient client;

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _error;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ref = Uri.encodeComponent(widget.sessionRef);
      final resp = await widget.client.get<Map<String, dynamic>>(
        '/api/sessions/$ref/fs/read',
        queryParameters: {'path': widget.entry.path},
      );
      final content = resp.data?['content'] as String? ?? '';
      _controller.text = content;
      _controller.addListener(() {
        if (!_dirty) setState(() => _dirty = true);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveFile() async {
    setState(() { _saving = true; _saveError = null; });
    try {
      final ref = Uri.encodeComponent(widget.sessionRef);
      await widget.client.put<dynamic>(
        '/api/sessions/$ref/fs/write',
        data: {
          'path': widget.entry.path,
          'content': _controller.text,
        },
      );
      if (mounted) setState(() => _dirty = false);
    } catch (e) {
      if (mounted) setState(() => _saveError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_dirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _kBorder),
        ),
        title: const Text('未保存的更改', style: TextStyle(color: _kTextHigh, fontSize: 16)),
        content: const Text(
          '有未保存的更改，确定要离开吗？',
          style: TextStyle(color: _kTextMid, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('继续编辑', style: TextStyle(color: _kTextMid)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('放弃更改', style: TextStyle(color: _kErrorText)),
          ),
        ],
      ),
    );
    return discard == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final should = await _onWillPop();
        if (should && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
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
                  style: const TextStyle(color: _kErrorText, fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            Expanded(child: _buildBody()),
          ],
        ),
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
        right: 8,
        bottom: 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: _kTextMid, size: 20),
            onPressed: () async {
              if (await _onWillPop() && context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      widget.entry.name,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: _kTextHigh,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_dirty) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kAccent,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  widget.entry.path,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: _kTextLow,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.entry.editable) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: (_saving || !_dirty) ? null : _saveFile,
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
          ] else ...[
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: _kTextMid),
              tooltip: '复制内容',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _controller.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已复制到剪贴板'),
                    backgroundColor: _kAccentDim,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
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
              onPressed: _loadFile,
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

    return TextField(
      controller: _controller,
      enabled: widget.entry.editable,
      maxLines: null,
      expands: true,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: _kTextHigh,
        height: 1.55,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _kBg,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
        hintText: widget.entry.editable ? null : '（只读文件）',
        hintStyle: const TextStyle(color: _kTextLow, fontFamily: 'monospace'),
      ),
      textAlignVertical: TextAlignVertical.top,
    );
  }
}
