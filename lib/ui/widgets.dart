import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Hairline card — the base surface of the compact system.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(K.m),
    this.onTap,
    this.hoverable = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool hoverable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(K.r),
        hoverColor: hoverable ? scheme.primary.withValues(alpha: 0.05) : null,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (!hoverable) return card;
    return MouseRegion(cursor: SystemMouseCursors.click, child: card);
  }
}

/// Uppercase micro section header, optionally with a trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.trailing, this.subtle = false});

  final String label;
  final Widget? trailing;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final style = microLabel(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: K.s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: subtle
                  ? style.copyWith(
                      color: style.color?.withValues(alpha: 0.6),
                    )
                  : style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Tiny rounded chip for metadata (category, due dates, priority).
class PillChip extends StatelessWidget {
  const PillChip(
    this.text, {
    super.key,
    this.color,
    this.icon,
    this.selected = false,
    this.onTap,
    this.dense = false,
  });

  final String text;
  final Color? color;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.onSurfaceVariant;
    final bg = selected
        ? scheme.primary.withValues(alpha: 0.16)
        : tint.withValues(alpha: 0.12);
    final fg = selected ? scheme.primary : tint;

    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2.5 : 3.5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ] else if (color != null && !selected) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: K.fontFamily,
              fontSize: dense ? 10 : 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: fg,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: chip),
    );
  }
}

/// Animated integer counter — counts up on first appearance.
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter(
    this.value, {
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  final int value;
  final TextStyle? style;
  final Duration duration;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  CurvedAnimation? _curve;
  int _from = 0;
  int _delta = 0;
  int _displayed = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addListener(_tick);
    _retarget(0, widget.value);
  }

  void _retarget(int from, int to) {
    _from = from;
    _delta = to - from;
    _curve?.dispose();
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller
      ..reset()
      ..forward();
  }

  void _tick() {
    final c = _curve;
    if (c == null) return;
    final v = (_from + _delta * c.value).round();
    if (v != _displayed) setState(() => _displayed = v);
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _retarget(_displayed, widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effective = widget.style ??
        Theme.of(context).textTheme.displaySmall!;
    return Text('$_displayed', style: effective);
  }
}

/// Friendly empty state with a soft icon bubble.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(K.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: scheme.primary),
              ),
              const SizedBox(height: K.l),
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: K.xs),
              Text(message,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: K.l), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact page header: title + optional subtitle + trailing actions.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, K.xs, 0, K.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.displaySmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: theme.textTheme.bodySmall!
                          .copyWith(letterSpacing: -0.05)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small circular "new" action button used in headers.
class HeaderAction extends StatelessWidget {
  const HeaderAction({super.key, required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(K.rS),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(K.rS),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 17, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Compact search field (36px tall).
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: K.inputH,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(Icons.search, size: 17, color: scheme.onSurfaceVariant),
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 15,
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    // notify listeners of the field
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
        ),
      ),
    );
  }
}
