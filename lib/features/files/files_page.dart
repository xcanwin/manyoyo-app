import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/features/files/file_viewer_page.dart';
import 'package:manyoyo_app/models/fs_entry.dart';

const _kBg = Color(0xFF0F1A14);
const _kSurface = Color(0xFF172217);
const _kBorder = Color(0xFF2B4035);
const _kAccent = Color(0xFF3DDB87);
const _kAccentDim = Color(0xFF0B6E4F);
const _kTextHigh = Color(0xFFE8F5EE);
const _kTextMid = Color(0xFF7FA88E);
const _kTextLow = Color(0xFF3D5446);

class FilesPage extends StatefulWidget {
  const FilesPage({super.key, required this.sessionRef});

  final String sessionRef;

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  late final ApiClient _client;
  final List<String> _pathStack = ['/workspace'];
  List<FsEntry> _entries = [];
  bool _loading = true;
  String? _error;

  String get _currentPath => _pathStack.last;

  @override
  void initState() {
    super.initState();
    _client = context.read<ApiClient>();
    _loadDirectory(_currentPath);
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ref = Uri.encodeComponent(widget.sessionRef);
      final resp = await _client.get<Map<String, dynamic>>(
        '/api/sessions/$ref/fs/list',
        queryParameters: {'path': path},
      );
      final raw = resp.data?['entries'] as List<dynamic>? ?? [];
      setState(() => _entries = FsEntry.listFromJson(raw));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigate(FsEntry entry) {
    if (entry.isDirectory) {
      _pathStack.add(entry.path);
      _loadDirectory(entry.path);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FileViewerPage(
            sessionRef: widget.sessionRef,
            entry: entry,
            client: _client,
          ),
        ),
      );
    }
  }

  bool _canGoUp() => _pathStack.length > 1;

  void _goUp() {
    if (!_canGoUp()) return;
    _pathStack.removeLast();
    _loadDirectory(_currentPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _TopBar(
            sessionRef: widget.sessionRef,
            currentPath: _currentPath,
            canGoUp: _canGoUp(),
            onGoUp: _goUp,
            onRefresh: () => _loadDirectory(_currentPath),
          ),
          Expanded(child: _buildBody()),
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
              onPressed: () => _loadDirectory(_currentPath),
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
    if (_entries.isEmpty) {
      return const Center(
        child: Text(
          'empty directory',
          style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: _kTextLow),
        ),
      );
    }

    // Sort: directories first, then files, both alphabetically.
    final sorted = [..._entries]
      ..sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.compareTo(b.name);
      });

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const Divider(
        color: _kBorder, height: 1, thickness: 1, indent: 16, endIndent: 16,
      ),
      itemBuilder: (context, i) => _EntryTile(
        entry: sorted[i],
        onTap: () => _navigate(sorted[i]),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.sessionRef,
    required this.currentPath,
    required this.canGoUp,
    required this.onGoUp,
    required this.onRefresh,
  });

  final String sessionRef;
  final String currentPath;
  final bool canGoUp;
  final VoidCallback onGoUp;
  final VoidCallback onRefresh;

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
        right: 8,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _kTextMid, size: 20),
                onPressed: () => context.go('/sessions'),
                tooltip: '返回会话列表',
              ),
              const Icon(Icons.folder_open_rounded, size: 14, color: _kAccentDim),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  sessionRef,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: _kTextMid,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canGoUp)
                _IconBtn(icon: Icons.arrow_upward_rounded, tooltip: '上一级', onTap: onGoUp),
              _IconBtn(icon: Icons.refresh_rounded, tooltip: '刷新', onTap: onRefresh),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: Text(
              currentPath,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: _kTextLow,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onTap});

  final FsEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              entry.isDirectory ? Icons.folder_rounded : _fileIcon(entry.language),
              size: 16,
              color: entry.isDirectory ? _kAccentDim : _kTextLow,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.name,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: entry.isDirectory ? _kTextHigh : _kTextMid,
                ),
              ),
            ),
            if (!entry.isDirectory && entry.size != null)
              Text(
                _formatSize(entry.size!),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: _kTextLow,
                ),
              ),
            if (entry.isDirectory)
              const Icon(Icons.chevron_right_rounded, size: 16, color: _kTextLow),
          ],
        ),
      ),
    );
  }

  IconData _fileIcon(String? lang) {
    return switch (lang) {
      'dart' || 'javascript' || 'typescript' || 'python' || 'go' || 'rust' =>
        Icons.code_rounded,
      'markdown' => Icons.article_outlined,
      'json' || 'yaml' || 'toml' => Icons.data_object_rounded,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}K';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
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
