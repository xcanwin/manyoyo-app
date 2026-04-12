import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/core/auth_notifier.dart';
import 'package:manyoyo_app/features/sessions/sessions_notifier.dart';
import 'package:manyoyo_app/models/session.dart';

// ─── palette (extends theme) ─────────────────────────────────────────────────
const _kBg = Color(0xFF0F1A14);          // deep forest black
const _kSurface = Color(0xFF172217);     // container card
const _kBorder = Color(0xFF2B4035);      // subtle green-tinted border
const _kAccent = Color(0xFF3DDB87);      // bright terminal green
const _kAccentDim = Color(0xFF0B6E4F);   // muted accent
const _kTextHigh = Color(0xFFE8F5EE);    // high-emphasis text
const _kTextMid = Color(0xFF7FA88E);     // mid-emphasis
const _kTextLow = Color(0xFF3D5446);     // low-emphasis / label
const _kRunning = Color(0xFF3DDB87);
const _kIdle = Color(0xFF2B4035);
const _kHistoryOnly = Color(0xFF1C2D24);

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  late final SessionsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = SessionsNotifier(context.read<ApiClient>());
    _notifier.loadSessions();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SessionsNotifier>.value(
      value: _notifier,
      child: const _SessionsScaffold(),
    );
  }
}

class _SessionsScaffold extends StatelessWidget {
  const _SessionsScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildTopBar(context),
          const Expanded(child: _SessionsList()),
        ],
      ),
      floatingActionButton: _NewSessionButton(),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        left: 20,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          // Logo / wordmark
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: _kAccentDim),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'MANYOYO',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 2,
                color: _kAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'agent sessions',
            style: TextStyle(
              fontSize: 13,
              color: _kTextMid,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          // Config button
          _IconBtn(
            icon: Icons.tune_rounded,
            tooltip: '配置',
            onTap: () => context.go('/config'),
          ),
          const SizedBox(width: 4),
          // Logout
          _IconBtn(
            icon: Icons.power_settings_new_rounded,
            tooltip: '退出登录',
            onTap: () async {
              context.read<AuthNotifier>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _SessionsList extends StatelessWidget {
  const _SessionsList();

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionsNotifier>(
      builder: (context, notifier, _) {
        if (notifier.isLoading && notifier.containers.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _kAccent,
              ),
            ),
          );
        }

        if (notifier.error != null && notifier.containers.isEmpty) {
          return _ErrorState(
            message: notifier.error!,
            onRetry: notifier.loadSessions,
          );
        }

        if (notifier.containers.isEmpty) {
          return _EmptyState(onRefresh: notifier.loadSessions);
        }

        return RefreshIndicator(
          color: _kAccent,
          backgroundColor: _kSurface,
          onRefresh: notifier.loadSessions,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: notifier.containers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _ContainerCard(group: notifier.containers[i]),
          ),
        );
      },
    );
  }
}

class _ContainerCard extends StatelessWidget {
  const _ContainerCard({required this.group});

  final ContainerGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.inbox_rounded,
                  size: 14,
                  color: _kTextLow,
                ),
                const SizedBox(width: 7),
                Text(
                  group.containerName,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: _kTextHigh,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Text(
                  '${group.agents.length} agent${group.agents.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTextLow,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          if (group.agents.isNotEmpty) ...[
            const Divider(color: _kBorder, height: 1, thickness: 1),
            ...group.agents.map(
              (agent) => _AgentRow(
                agent: agent,
                isLast: agent == group.agents.last,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgentRow extends StatelessWidget {
  const _AgentRow({required this.agent, required this.isLast});

  final AgentSession agent;
  final bool isLast;

  Color get _statusColor {
    if (agent.running) return _kRunning;
    if (agent.isHistoryOnly) return _kTextLow;
    return _kAccentDim;
  }

  String get _statusLabel {
    if (agent.running) return 'running';
    if (agent.isHistoryOnly) return 'history';
    return 'idle';
  }

  Color get _rowBg {
    if (agent.running) return const Color(0xFF1C3228);
    if (agent.isHistoryOnly) return _kHistoryOnly;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _rowBg,
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              )
            : BorderRadius.zero,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor,
                  ),
                ),
                const SizedBox(width: 10),
                // Agent name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.agentId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: _kTextHigh,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (agent.yolo != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _Badge(label: agent.yolo!),
                            if (agent.contextMode != null) ...[
                              const SizedBox(width: 4),
                              _Badge(
                                label: agent.contextMode!,
                                color: _kTextLow,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Status label
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: _statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Action buttons
                if (!agent.isHistoryOnly) ...[
                  _SmallIconBtn(
                    icon: Icons.terminal_rounded,
                    tooltip: '终端',
                    onTap: () => context.go(
                      '/sessions/${Uri.encodeComponent(agent.sessionRef)}/term',
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
                _SmallIconBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: 'Agent 对话',
                  onTap: () => context.go(
                    '/sessions/${Uri.encodeComponent(agent.sessionRef)}/chat',
                  ),
                ),
                const SizedBox(width: 2),
                _DeleteBtn(sessionRef: agent.sessionRef),
              ],
            ),
          ),
          if (!isLast) const Divider(color: _kBorder, height: 1, thickness: 1),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.color = _kAccentDim});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          color: color == _kTextLow ? _kTextMid : _kAccent,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  const _SmallIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

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
          child: Icon(icon, size: 16, color: _kTextMid),
        ),
      ),
    );
  }
}

class _DeleteBtn extends StatelessWidget {
  const _DeleteBtn({required this.sessionRef});

  final String sessionRef;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '删除',
      child: InkWell(
        onTap: () => _confirmDelete(context),
        borderRadius: BorderRadius.circular(6),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.delete_outline_rounded,
            size: 16,
            color: _kTextLow,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _kBorder),
        ),
        title: const Text(
          '删除会话',
          style: TextStyle(color: _kTextHigh, fontSize: 16),
        ),
        content: Text(
          '确认删除 $sessionRef？此操作会停止并删除对应容器。',
          style: const TextStyle(color: _kTextMid, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消', style: TextStyle(color: _kTextMid)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '删除',
              style: TextStyle(color: Color(0xFFE06C5B)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<SessionsNotifier>().removeSession(sessionRef);
    }
  }
}

class _NewSessionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateDialog(context),
      backgroundColor: _kAccentDim,
      foregroundColor: _kTextHigh,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'New Session',
        style: TextStyle(fontFamily: 'monospace', letterSpacing: 0.5),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final yoloController = TextEditingController();

    final notifier = context.read<SessionsNotifier>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: _kBorder),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Session',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: _kTextHigh,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            _DarkTextField(
              controller: nameController,
              label: 'Container name',
              hint: 'my-agent-001',
              autofocus: true,
            ),
            const SizedBox(height: 12),
            _DarkTextField(
              controller: yoloController,
              label: 'Agent (optional)',
              hint: 'claude / gemini / codex',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _kAccentDim,
                  foregroundColor: _kTextHigh,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.of(ctx).pop();
                  await notifier.createSession(
                    containerName: name,
                    yolo: yoloController.text.trim().isEmpty
                        ? null
                        : yoloController.text.trim(),
                  );
                },
                child: const Text(
                  'Create',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    yoloController.dispose();
  }
}

class _DarkTextField extends StatelessWidget {
  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _kTextLow,
            letterSpacing: 0.5,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: autofocus,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: _kTextHigh,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _kTextLow.withValues(alpha: 0.7),
              fontFamily: 'monospace',
            ),
            filled: true,
            fillColor: const Color(0xFF0F1A14),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _kAccentDim, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: _kTextMid),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '[ ]',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 36,
              color: _kTextLow,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'no sessions',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: _kTextLow,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onRefresh,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kTextMid,
              side: const BorderSide(color: _kBorder),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'refresh',
              style: TextStyle(fontFamily: 'monospace', letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
                fontSize: 28,
                color: Color(0xFFE06C5B),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _kTextMid,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kAccent,
                side: const BorderSide(color: _kAccentDim),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'retry',
                style: TextStyle(fontFamily: 'monospace', letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
