import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/app/widgets.dart';
import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/models/fs_entry.dart';

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
  bool _syncingText = false;
  String? _error;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
    _loadFile();
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

  Future<void> _loadFile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ref = Uri.encodeComponent(widget.sessionRef);
      final resp = await widget.client.get<Map<String, dynamic>>(
        '/api/sessions/$ref/fs/read',
        queryParameters: {'path': widget.entry.path},
      );
      final content = resp.data?['content'] as String? ?? '';
      _syncingText = true;
      _controller.text = content;
      _syncingText = false;
      _dirty = false;
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveFile() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final ref = Uri.encodeComponent(widget.sessionRef);
      await widget.client.put<dynamic>(
        '/api/sessions/$ref/fs/write',
        data: {'path': widget.entry.path, 'content': _controller.text},
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
        backgroundColor: kGlassFillStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: kDarkBorder),
        ),
        title: const Text(
          '未保存的更改',
          style: TextStyle(color: kDarkTextHigh, fontSize: 16),
        ),
        content: const Text(
          '有未保存的更改，确定要离开吗？',
          style: TextStyle(color: kDarkTextMid, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('继续编辑', style: TextStyle(color: kDarkTextMid)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('放弃更改', style: TextStyle(color: kDarkErrorText)),
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
      child: DarkPageScaffold(
        header: _buildTopBar(),
        body: Column(
          children: [
            if (_saveError != null)
              Container(
                width: double.infinity,
                color: kErrorBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
      ),
    );
  }

  Widget _buildTopBar() {
    return DarkPageHeader(
      title: widget.entry.name,
      subtitle: widget.entry.path,
      onBack: () async {
        final navigator = Navigator.of(context);
        if (await _onWillPop()) {
          navigator.pop();
        }
      },
      leading: const Icon(
        Icons.description_outlined,
        size: 16,
        color: kDarkAccent,
      ),
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
        if (widget.entry.editable)
          FilledButton(
            onPressed: (_saving || !_dirty) ? null : _saveFile,
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
          )
        else
          DarkIconBtn(
            icon: Icons.copy_rounded,
            tooltip: '复制内容',
            onTap: () {
              Clipboard.setData(ClipboardData(text: _controller.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已复制到剪贴板'),
                  backgroundColor: kDarkAccent,
                  duration: Duration(seconds: 2),
                ),
              );
            },
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
        icon: Icons.description_outlined,
        title: '文件读取失败',
        detail: _error!,
        actionLabel: '重试',
        onAction: _loadFile,
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
        color: kDarkTextHigh,
        height: 1.55,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: kEditorBg,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
        hintText: widget.entry.editable ? null : '（只读文件）',
        hintStyle: const TextStyle(
          color: kDarkTextLow,
          fontFamily: 'monospace',
        ),
      ),
      textAlignVertical: TextAlignVertical.top,
    );
  }
}
