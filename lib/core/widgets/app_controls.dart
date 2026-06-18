import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

enum AppButtonTone { primary, secondary, ghost }

class AppPillButton extends StatelessWidget {
  const AppPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = AppButtonTone.primary,
    this.compact = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonTone tone;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null;
    final foreground = tone == AppButtonTone.primary
        ? Colors.white
        : dark
        ? const Color(0xFFE8EDF6)
        : const Color(0xFF1F2A3A);
    final background = switch (tone) {
      AppButtonTone.primary => palette.primary,
      AppButtonTone.secondary =>
        dark
            ? const Color.fromRGBO(255, 255, 255, 0.075)
            : const Color(0xFFF0F3F8),
      AppButtonTone.ghost => Colors.transparent,
    };
    final borderColor = switch (tone) {
      AppButtonTone.primary => Colors.transparent,
      AppButtonTone.secondary => palette.stroke,
      AppButtonTone.ghost => Colors.transparent,
    };

    final child = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.42,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: compact ? 30 : 36,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 15),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(compact ? 8 : 10),
          border: Border.all(color: borderColor),
          boxShadow: tone == AppButtonTone.primary
              ? [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: foreground, size: compact ? 15 : 16),
              SizedBox(width: compact ? 6 : 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onPressed : null,
        child: expand ? SizedBox(width: double.infinity, child: child) : child,
      ),
    );
  }
}

class AppToolButton extends StatelessWidget {
  const AppToolButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.selected = false,
    this.filled = false,
    this.size = 30,
    this.iconSize = 17,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;
  final bool filled;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null;
    final background = selected
        ? palette.primarySoft
        : filled
        ? dark
              ? const Color.fromRGBO(255, 255, 255, 0.055)
              : const Color.fromRGBO(31, 42, 58, 0.045)
        : Colors.transparent;
    final iconColor = selected
        ? palette.primary
        : dark
        ? const Color(0xFFD9E0EA)
        : const Color(0xFF263244);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.7,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: filled ? Border.all(color: palette.stroke) : null,
            ),
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = value
        ? palette.primary
        : dark
        ? const Color.fromRGBO(255, 255, 255, 0.10)
        : const Color(0xFFE4E9F1);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 38,
          height: 22,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: value ? Colors.transparent : palette.stroke,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppDialogPanel extends StatelessWidget {
  const AppDialogPanel({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 420,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.panelBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.stroke),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(alpha: 0.72),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              child,
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final action in actions) ...[
                    action,
                    if (action != actions.last) const SizedBox(width: 10),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
