import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:manyoyo_app/app/theme.dart';

/// Compact icon button used in dark-themed top bars and tool rows.
class DarkIconBtn extends StatelessWidget {
  const DarkIconBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconSize = 18,
    this.padding = 6,
    this.borderRadius = 6,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double iconSize;
  final double padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(icon, size: iconSize, color: kDarkTextMid),
        ),
      ),
    );
  }
}

class DarkPageTab {
  const DarkPageTab({
    required this.label,
    required this.icon,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;
}

enum SessionPageSection { chat, terminal, files }

List<DarkPageTab> buildSessionTabs({
  required BuildContext context,
  required String sessionRef,
  required SessionPageSection current,
}) {
  final encoded = Uri.encodeComponent(sessionRef);
  return [
    DarkPageTab(
      label: '对话',
      icon: Icons.chat_bubble_outline_rounded,
      selected: current == SessionPageSection.chat,
      onTap: current == SessionPageSection.chat
          ? null
          : () => context.go('/sessions/$encoded/chat'),
    ),
    DarkPageTab(
      label: '终端',
      icon: Icons.terminal_rounded,
      selected: current == SessionPageSection.terminal,
      onTap: current == SessionPageSection.terminal
          ? null
          : () => context.go('/sessions/$encoded/term'),
    ),
    DarkPageTab(
      label: '文件',
      icon: Icons.folder_open_rounded,
      selected: current == SessionPageSection.files,
      onTap: current == SessionPageSection.files
          ? null
          : () => context.go('/sessions/$encoded/files'),
    ),
  ];
}

class DarkPageScaffold extends StatelessWidget {
  const DarkPageScaffold({
    super.key,
    required this.header,
    required this.body,
    this.footer,
    this.backgroundColor = kDarkBg,
  });

  final Widget header;
  final Widget body;
  final Widget? footer;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          header,
          Expanded(child: body),
          ?footer,
        ],
      ),
    );
  }
}

class DarkPageHeader extends StatelessWidget {
  const DarkPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.leading,
    this.actions = const <Widget>[],
    this.tabs = const <DarkPageTab>[],
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget> actions;
  final List<DarkPageTab> tabs;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kDarkSurface,
        border: Border(bottom: BorderSide(color: kDarkBorder)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        left: 12,
        right: 12,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: kDarkTextMid,
                  ),
                  onPressed: onBack,
                  tooltip: '返回',
                ),
              if (leading != null) ...[
                if (onBack == null) const SizedBox(width: 4),
                leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: kDarkTextHigh,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: kDarkTextLow,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[const SizedBox(width: 8), ...actions],
            ],
          ),
          if (tabs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tabs
                  .map((tab) => _DarkTabChip(tab: tab))
                  .toList(growable: false),
            ),
          ],
          if (bottom != null) ...[const SizedBox(height: 12), bottom!],
        ],
      ),
    );
  }
}

class DarkSurfaceCard extends StatelessWidget {
  const DarkSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 12,
    this.color = kDarkSurface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: kDarkBorder),
      ),
      padding: padding,
      child: child,
    );
  }
}

class DarkStateMessage extends StatelessWidget {
  const DarkStateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DarkSurfaceCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: kDarkTextLow),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: kDarkTextHigh,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kDarkTextMid,
                    height: 1.6,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: kDarkAccentDim,
                      foregroundColor: kDarkTextHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkTabChip extends StatelessWidget {
  const _DarkTabChip({required this.tab});

  final DarkPageTab tab;

  @override
  Widget build(BuildContext context) {
    final fg = tab.selected ? kDarkTextHigh : kDarkTextMid;
    final bg = tab.selected ? const Color(0xFF223328) : const Color(0xFF111A14);
    final border = tab.selected ? kDarkAccentDim : kDarkBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tab.onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, size: 15, color: fg),
              const SizedBox(width: 8),
              Text(
                tab.label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: fg,
                  fontWeight: tab.selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
