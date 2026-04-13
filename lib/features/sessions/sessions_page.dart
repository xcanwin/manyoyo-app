import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:manyoyo_app/app/theme.dart';
import 'package:manyoyo_app/app/widgets.dart';
import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/core/auth_notifier.dart';
import 'package:manyoyo_app/features/sessions/sessions_notifier.dart';
import 'package:manyoyo_app/models/session.dart';

// ─── page-specific colors ────────────────────────────────────────────────────
const _kRunning = Color(0xFF3DDB87);
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
      backgroundColor: kDarkBg,
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
    return DarkPageHeader(
      title: 'MANYOYO',
      subtitle: 'agent sessions',
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: kDarkAccentDim),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'MX',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            letterSpacing: 2,
            color: kDarkAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      actions: [
        DarkIconBtn(
          icon: Icons.tune_rounded,
          tooltip: '配置',
          onTap: () => context.go('/config'),
          iconSize: 20,
          padding: 8,
          borderRadius: 8,
        ),
        const SizedBox(width: 4),
        DarkIconBtn(
          icon: Icons.power_settings_new_rounded,
          tooltip: '退出登录',
          onTap: () async {
            context.read<AuthNotifier>().logout();
            context.go('/login');
          },
          iconSize: 20,
          padding: 8,
          borderRadius: 8,
        ),
      ],
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
                color: kDarkAccent,
              ),
            ),
          );
        }

        if (notifier.error != null && notifier.containers.isEmpty) {
          return DarkStateMessage(
            icon: Icons.cloud_off_rounded,
            title: '会话列表加载失败',
            detail: notifier.error!,
            actionLabel: '重试',
            onAction: notifier.loadSessions,
          );
        }

        if (notifier.containers.isEmpty) {
          return DarkStateMessage(
            icon: Icons.inbox_rounded,
            title: '还没有会话',
            detail: '先创建一个新的容器会话，再进入对话、终端或文件视图。',
            actionLabel: '刷新',
            onAction: notifier.loadSessions,
          );
        }

        return RefreshIndicator(
          color: kDarkAccent,
          backgroundColor: kDarkSurface,
          onRefresh: notifier.loadSessions,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: notifier.containers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
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
        color: kDarkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kDarkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.inbox_rounded, size: 14, color: kDarkTextLow),
                const SizedBox(width: 7),
                Text(
                  group.containerName,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: kDarkTextHigh,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Text(
                  '${group.agents.length} agent${group.agents.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: kDarkTextLow,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          if (group.agents.isNotEmpty) ...[
            const Divider(color: kDarkBorder, height: 1, thickness: 1),
            ...group.agents.map(
              (agent) =>
                  _AgentRow(agent: agent, isLast: agent == group.agents.last),
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
    if (agent.isHistoryOnly) return kDarkTextLow;
    return kDarkAccentDim;
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
                          color: kDarkTextHigh,
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
                                color: kDarkTextLow,
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
                  DarkIconBtn(
                    icon: Icons.terminal_rounded,
                    tooltip: '终端',
                    onTap: () => context.go(
                      '/sessions/${Uri.encodeComponent(agent.sessionRef)}/term',
                    ),
                    iconSize: 16,
                    padding: 6,
                  ),
                  const SizedBox(width: 2),
                ],
                DarkIconBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: 'Agent 对话',
                  onTap: () => context.go(
                    '/sessions/${Uri.encodeComponent(agent.sessionRef)}/chat',
                  ),
                  iconSize: 16,
                  padding: 6,
                ),
                const SizedBox(width: 2),
                _DeleteBtn(sessionRef: agent.sessionRef),
              ],
            ),
          ),
          if (!isLast)
            const Divider(color: kDarkBorder, height: 1, thickness: 1),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.color = kDarkAccentDim});

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
          color: color == kDarkTextLow ? kDarkTextMid : kDarkAccent,
          letterSpacing: 0.3,
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
    return DarkIconBtn(
      icon: Icons.delete_outline_rounded,
      tooltip: '删除',
      onTap: () => _confirmDelete(context),
      iconSize: 16,
      padding: 6,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kDarkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kDarkBorder),
        ),
        title: const Text(
          '删除会话',
          style: TextStyle(color: kDarkTextHigh, fontSize: 16),
        ),
        content: Text(
          '确认删除 $sessionRef？此操作会停止并删除对应容器。',
          style: const TextStyle(
            color: kDarkTextMid,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消', style: TextStyle(color: kDarkTextMid)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除', style: TextStyle(color: Color(0xFFE06C5B))),
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
      backgroundColor: kDarkAccentDim,
      foregroundColor: kDarkTextHigh,
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
      backgroundColor: kDarkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: kDarkBorder),
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
                color: kDarkTextHigh,
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
                  backgroundColor: kDarkAccentDim,
                  foregroundColor: kDarkTextHigh,
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
            color: kDarkTextLow,
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
            color: kDarkTextHigh,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: kDarkTextLow.withValues(alpha: 0.7),
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
              borderSide: const BorderSide(color: kDarkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: kDarkBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: kDarkAccentDim, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
