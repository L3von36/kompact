import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'widgets.dart';

/// Navigation destination descriptor.
class AdaptiveDestination {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String? badgeKey;

  const AdaptiveDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badgeKey,
  });
}

/// Adaptive layout shell:
///  • width ≥ 1100 → expanded navigation rail (labels visible)
///  • 700–1100     → collapsed icon rail
///  • < 700        → bottom navigation bar (5 primary + "More" sheet)
class AdaptiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AdaptiveDestination> destinations;
  final Widget body;
  final int badgeCount;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
    required this.body,
    this.badgeCount = 0,
  });

  static bool isCompact(double width) => width < 700;
  static bool isMedium(double width) => width >= 700 && width < 1100;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 700) {
      return _mobile(context);
    }
    return _desktop(context, expanded: width >= 1100);
  }

  // ── Desktop: navigation rail ──────────────────────────────────────────────

  Widget _desktop(BuildContext context, {required bool expanded}) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.bg,
      body: Row(
        children: [
          _rail(context, expanded),
          VerticalDivider(width: 1, thickness: 1, color: p.border),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _rail(BuildContext context, bool expanded) {
    final p = context.pal;
    return Container(
      width: expanded ? K.railWidth : K.railWidthCollapsed,
      color: p.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand.
          SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: K.sm),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.primary,
                      borderRadius: BorderRadius.circular(K.rSm),
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      size: 14,
                      color: p.primaryFg,
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: K.sm),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KOMPACT',
                            style: TextStyle(
                              fontSize: K.subtitle,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: p.text,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            'Fleet Management',
                            style: TextStyle(
                              fontSize: K.micro,
                              fontWeight: FontWeight.w600,
                              color: p.textTertiary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Divider(height: 1, color: p.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: K.xs),
              children: [
                for (var i = 0; i < destinations.length; i++)
                  _railItem(context, i, expanded),
              ],
            ),
          ),
          Divider(height: 1, color: p.border),
          Padding(
            padding: const EdgeInsets.all(K.sm),
            child: Row(
              children: [
                const LiveDot(size: 6),
                const SizedBox(width: K.xs + 1),
                Expanded(
                  child: Text(
                    'Telematics live',
                    style: TextStyle(
                      fontSize: K.caption,
                      fontWeight: FontWeight.w600,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _railItem(BuildContext context, int index, bool expanded) {
    final p = context.pal;
    final d = destinations[index];
    final selected = index == currentIndex;
    final icon = selected ? (d.selectedIcon ?? d.icon) : d.icon;
    final showBadge = d.badgeKey == 'alerts' && badgeCount > 0;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: K.xs, vertical: 1),
      child: Material(
        color: selected ? p.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(K.rSm),
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(K.rSm),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? K.sm : 0,
              vertical: K.xs + 1,
            ),
            child: Row(
              mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Badge(
                  isLabelVisible: showBadge,
                  offset: expanded ? const Offset(9, -6) : const Offset(6, -6),
                  backgroundColor: p.critical,
                  textStyle: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                  label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                  child: Icon(
                    icon,
                    size: 16,
                    color: selected ? p.primary : p.textSecondary,
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: K.sm),
                  Expanded(
                    child: Text(
                      d.label,
                      style: TextStyle(
                        fontSize: K.body,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? p.primary : p.textSecondary,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (expanded) return tile;
    return Tooltip(message: d.label, child: tile);
  }

  // ── Mobile: bottom navigation + More sheet ────────────────────────────────

  Widget _mobile(BuildContext context) {
    final p = context.pal;
    final primaryCount = destinations.length > 5 ? 4 : destinations.length;
    final hasMore = destinations.length > primaryCount;

    return Scaffold(
      backgroundColor: p.bg,
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, color: p.border),
          Container(
            color: p.surface,
            height: 58,
            child: Row(
              children: [
                for (var i = 0; i < primaryCount; i++) _navItem(context, i),
                if (hasMore)
                  Expanded(
                    child: _moreButton(context),
                  ),
              ],
            ),
          ),
          // Safe-area inset for gesture bar.
          Container(color: p.surface, height: MediaQuery.viewPaddingOf(context).bottom),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, int index) {
    final p = context.pal;
    final d = destinations[index];
    final selected = index == currentIndex;
    final showBadge = d.badgeKey == 'alerts' && badgeCount > 0;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: showBadge,
              offset: const Offset(8, -5),
              backgroundColor: p.critical,
              textStyle: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
              label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
              child: Icon(
                selected ? (d.selectedIcon ?? d.icon) : d.icon,
                size: 19,
                color: selected ? p.primary : p.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              d.label,
              style: TextStyle(
                fontSize: K.caption,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? p.primary : p.textTertiary,
                fontFamily: 'Inter',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _moreButton(BuildContext context) {
    final p = context.pal;
    final anySelected = currentIndex >= 4;
    final moreLabel = anySelected ? destinations[currentIndex].label : 'More';

    return Expanded(
      child: InkWell(
        onTap: () => _openMoreSheet(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              anySelected ? (destinations[currentIndex].selectedIcon ?? destinations[currentIndex].icon) : Icons.grid_view_rounded,
              size: 19,
              color: anySelected ? p.primary : p.textTertiary,
            ),
            const SizedBox(height: 2),
            Text(
              moreLabel,
              style: TextStyle(
                fontSize: K.caption,
                fontWeight: anySelected ? FontWeight.w700 : FontWeight.w500,
                color: anySelected ? p.primary : p.textTertiary,
                fontFamily: 'Inter',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMoreSheet(BuildContext context) async {
    final p = context.pal;
    final primaryCount = destinations.length > 5 ? 4 : destinations.length;
    final rest = destinations.sublist(primaryCount);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(K.rLg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(K.lg, K.md, K.lg, K.xs),
                child: Text(
                  'All modules',
                  style: TextStyle(
                    fontSize: K.subtitle,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              for (var i = 0; i < rest.length; i++)
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(
                    rest[i].selectedIcon ?? rest[i].icon,
                    size: 18,
                    color: currentIndex == primaryCount + i ? p.primary : p.textSecondary,
                  ),
                  title: Text(
                    rest[i].label,
                    style: TextStyle(
                      fontSize: K.body,
                      fontWeight: FontWeight.w600,
                      color: currentIndex == primaryCount + i ? p.primary : p.text,
                      fontFamily: 'Inter',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onTap(primaryCount + i);
                  },
                ),
              const SizedBox(height: K.sm),
            ],
          ),
        );
      },
    );
  }
}
