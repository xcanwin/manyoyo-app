import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:manyoyo_app/app/theme.dart';

/// Compact icon button used in shared top bars and tool rows.
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: kGlassFillSoft,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: kDarkBorder),
              boxShadow: const [
                BoxShadow(
                  color: kGlassShadow,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Icon(icon, size: iconSize, color: kDarkTextMid),
            ),
          ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2F4F8), Color(0xFFEAEFF6), Color(0xFFF4F0EB)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -120,
              left: -40,
              child: _GlowOrb(
                size: 240,
                colors: [kGlassGlow, Color(0x00CFE0FF)],
              ),
            ),
            const Positioned(
              top: 120,
              right: -90,
              child: _GlowOrb(
                size: 260,
                colors: [kGlassGlowWarm, Color(0x00FFE7D6)],
              ),
            ),
            const Positioned(
              bottom: -110,
              left: 40,
              child: _GlowOrb(
                size: 220,
                colors: [Color(0x2FBFCFE1), Color(0x00BFCFE1)],
              ),
            ),
            Column(
              children: [
                header,
                Expanded(child: body),
                ?footer,
              ],
            ),
          ],
        ),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.paddingOf(context).top + 10,
        12,
        10,
      ),
      child: _GlassPanel(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (onBack != null)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.42),
                      shape: BoxShape.circle,
                      border: Border.all(color: kDarkBorder),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: kDarkTextMid,
                      ),
                      onPressed: onBack,
                      tooltip: '返回',
                    ),
                  ),
                if (leading != null) ...[
                  if (onBack == null) const SizedBox(width: 4),
                  leading!,
                  const SizedBox(width: 12),
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
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: kDarkTextLow,
                            letterSpacing: 0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ...actions,
                ],
              ],
            ),
            if (tabs.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tabs
                    .map((tab) => _DarkTabChip(tab: tab))
                    .toList(growable: false),
              ),
            ],
            if (bottom != null) ...[const SizedBox(height: 14), bottom!],
          ],
        ),
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
    return _GlassPanel(
      padding: padding,
      radius: radius,
      tint: color,
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
                      backgroundColor: kDarkAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
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
    final fg = tab.selected ? kDarkAccent : kDarkTextMid;
    final bg = tab.selected
        ? const Color(0xFFDCE4F2)
        : Colors.white.withValues(alpha: 0.3);
    final border = tab.selected ? const Color(0xFFB1C0D7) : kDarkBorder;

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
            boxShadow: const [
              BoxShadow(
                color: kGlassShadow,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
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

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    required this.padding,
    required this.radius,
    this.tint = kGlassFillSoft,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tint, Colors.white.withValues(alpha: 0.62)],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: kDarkBorder),
            boxShadow: const [
              BoxShadow(
                color: kGlassShadow,
                blurRadius: 28,
                offset: Offset(0, 16),
              ),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
