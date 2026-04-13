import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/app/widgets.dart';
import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/features/files/file_viewer_page.dart';
import 'package:manyoyo_app/models/fs_entry.dart';

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
    return DarkPageScaffold(
      header: _TopBar(
        sessionRef: widget.sessionRef,
        currentPath: _currentPath,
        canGoUp: _canGoUp(),
        onGoUp: _goUp,
        onRefresh: () => _loadDirectory(_currentPath),
      ),
      body: _buildBody(),
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
        icon: Icons.folder_off_rounded,
        title: '目录读取失败',
        detail: _error!,
        actionLabel: '重试',
        onAction: () => _loadDirectory(_currentPath),
      );
    }
    if (_entries.isEmpty) {
      return const DarkStateMessage(
        icon: Icons.folder_open_rounded,
        title: '目录为空',
        detail: '当前目录下还没有可浏览的文件或子目录。',
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
      separatorBuilder: (context, index) => const Divider(
        color: kDarkBorder,
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, i) =>
          _EntryTile(entry: sorted[i], onTap: () => _navigate(sorted[i])),
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
    return DarkPageHeader(
      title: sessionRef,
      subtitle: 'workspace explorer',
      onBack: () => context.go('/sessions'),
      leading: const Icon(
        Icons.folder_open_rounded,
        size: 16,
        color: kDarkAccentDim,
      ),
      tabs: buildSessionTabs(
        context: context,
        sessionRef: sessionRef,
        current: SessionPageSection.files,
      ),
      actions: [
        if (canGoUp)
          DarkIconBtn(
            icon: Icons.arrow_upward_rounded,
            tooltip: '上一级',
            onTap: onGoUp,
          ),
        DarkIconBtn(
          icon: Icons.refresh_rounded,
          tooltip: '刷新',
          onTap: onRefresh,
        ),
      ],
      bottom: Text(
        currentPath,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: kDarkTextLow,
          letterSpacing: 0.2,
        ),
        overflow: TextOverflow.ellipsis,
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
              entry.isDirectory
                  ? Icons.folder_rounded
                  : _fileIcon(entry.language),
              size: 16,
              color: entry.isDirectory ? kDarkAccentDim : kDarkTextLow,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.name,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: entry.isDirectory ? kDarkTextHigh : kDarkTextMid,
                ),
              ),
            ),
            if (!entry.isDirectory && entry.size != null)
              Text(
                _formatSize(entry.size!),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: kDarkTextLow,
                ),
              ),
            if (entry.isDirectory)
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: kDarkTextLow,
              ),
          ],
        ),
      ),
    );
  }

  IconData _fileIcon(String? lang) {
    return switch (lang) {
      'dart' ||
      'javascript' ||
      'typescript' ||
      'python' ||
      'go' ||
      'rust' => Icons.code_rounded,
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
