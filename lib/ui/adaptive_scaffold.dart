import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'role_picker.dart';
import 'widgets.dart';

/// Navigation destination descriptor.
///
/// [id] maps the destination to its screen module ('dashboard', 'fleet', …)
/// so the shell can rebuild the page set per role without relying on
/// positional indexes. [section] groups destinations under micro headers in
/// the rail; start a new group by changing the value between entries.
class AdaptiveDestination {
  final String id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String? badgeKey;
  final String section;

  const AdaptiveDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.section,
    this.selectedIcon,
    this.badgeKey,
  });
}

/// Role workspace data handed to the shell by the app state.
class RoleContext {
  final FleetRole role;
  final String userName;
  final int movingVehicles;
  final double? fleetSpeedKmh;

  const RoleContext({
    required this.role,
    required this.userName,
    required this.movingVehicles,
    this.fleetSpeedKmh,
  });
}

/// Adaptive layout shell:
///  • width ≥ 1100 → expanded navigation rail (labels + sections visible)
///  • 700–1100     → collapsed icon rail (tooltips, pin to expand)
///  • < 700        → bottom navigation bar (4 primary + "More" sheet)
///
/// The rail carries the operator identity card (tap to switch workspace),
/// grouped destinations with live badges and a telematics status strip.
class AdaptiveScaffold extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AdaptiveDestination> destinations;
  final Widget body;
  final RoleContext roleContext;
  final ValueChanged<FleetRole> onRoleChange;
  final Map<String, int> badgeCounts;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
    required this.body,
    required this.roleContext,
    required this.onRoleChange,
    this.badgeCounts = const {},
  });

  static bool isCompact(double width) => width < 700;
  static bool isMedium(double width) => width >= 700 && width < 1100;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  /// null → follow window width; otherwise the user-pinned rail mode.
  bool? _pinnedExpanded;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 700) {
      return _mobile(context);
    }
    final autoExpanded = width >= 1100;
    return _desktop(context, expanded: _pinnedExpanded ?? autoExpanded);
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
          Expanded(child: widget.body),
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
          // Brand + rail pin.
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(width: K.xs),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Tooltip(
                      message: expanded ? 'Collapse rail' : 'Expand rail',
                      child: InkWell(
                        onTap: () => setState(() => _pinnedExpanded = !expanded),
                        borderRadius: BorderRadius.circular(K.rSm),
                        child: Icon(
                          expanded ? Icons.keyboard_double_arrow_left_rounded : Icons.keyboard_double_arrow_right_rounded,
                          size: 14,
                          color: p.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: p.border),

          // Operator identity card → role workspace switcher.
          _userCard(context, expanded),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: K.xs),
              children: [
                for (var i = 0; i < widget.destinations.length; i++)
                  _sectionAwareItem(context, i, expanded),
              ],
            ),
          ),
          Divider(height: 1, color: p.border),
          _liveStrip(context, expanded),
        ],
      ),
    );
  }

  /// Inserts a section micro-header whenever the group changes.
  Widget _sectionAwareItem(BuildContext context, int index, bool expanded) {
    final d = widget.destinations[index];
    final prev = index > 0 ? widget.destinations[index - 1] : null;
    final startsSection = prev == null || prev.section != d.section;
    if (!startsSection) return _railItem(context, index, expanded);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(K.md, K.sm + 2, K.md, K.xxs + 1),
            child: Text(
              d.section.toUpperCase(),
              style: TextStyle(
                fontSize: K.micro,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                color: context.pal.textTertiary,
                fontFamily: 'Inter',
              ),
            ),
          )
        else
          const SizedBox(height: K.sm),
        _railItem(context, index, expanded),
      ],
    );
  }

  Widget _userCard(BuildContext context, bool expanded) {
    final p = context.pal;
    final rc = widget.roleContext;
    final color = roleColor(context, rc.role);

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openRolePicker(context),
        borderRadius: BorderRadius.circular(K.rSm),
        hoverColor: p.surfaceAlt,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            expanded ? K.xs : (K.railWidthCollapsed - 30) / 2,
            K.xs + 1,
            expanded ? K.xs : (K.railWidthCollapsed - 30) / 2,
            K.xs + 1,
          ),
          child: Row(
            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              RoleBadge(role: rc.role, size: expanded ? 28 : 30, color: color),
              if (expanded) ...[
                const SizedBox(width: K.sm + 1),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rc.userName,
                        style: TextStyle(
                          fontSize: K.body,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                          ),
                          const SizedBox(width: K.xs + 1),
                          Flexible(
                            child: Text(
                              rc.role.label,
                              style: TextStyle(
                                fontSize: K.caption,
                                fontWeight: FontWeight.w600,
                                color: color,
                                fontFamily: 'Inter',
                              ),
                              maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.expand_more_rounded, size: 14, color: p.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );

    if (expanded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(K.xs, K.xs, K.xs, K.xs + 1),
        child: Container(
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(K.rMd),
            border: Border.all(color: p.border),
          ),
          child: card,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: K.xs + 1),
      child: Tooltip(message: '${rc.userName} · ${rc.role.label}\nSwitch workspace', child: card),
    );
  }

  Widget _railItem(BuildContext context, int index, bool expanded) {
    final p = context.pal;
    final d = widget.destinations[index];
    final selected = index == widget.currentIndex;
    final icon = selected ? (d.selectedIcon ?? d.icon) : d.icon;
    final badge = d.badgeKey == null ? 0 : (widget.badgeCounts[d.badgeKey] ?? 0);

    final tile = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? K.xs : (K.railWidthCollapsed - 38) / 2,
        vertical: 1,
      ),
      child: Material(
        color: selected ? p.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(K.rSm),
        child: InkWell(
          onTap: () => widget.onTap(index),
          borderRadius: BorderRadius.circular(K.rSm),
          hoverColor: selected ? p.primarySoft : p.surfaceAlt,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? K.xs + 1 : 0,
              vertical: K.xs + 1,
            ),
            child: Row(
              mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                // Left accent indicator for the active module.
                AnimatedContainer(
                  duration: K.fast,
                  width: 3,
                  height: selected ? 16 : 0,
                  decoration: BoxDecoration(
                    color: p.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: expanded ? K.xs + 2 : 0),
                Badge(
                  isLabelVisible: badge > 0,
                  offset: expanded ? const Offset(9, -6) : const Offset(6, -6),
                  backgroundColor: p.critical,
                  textStyle: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                  label: Text(badge > 99 ? '99+' : '$badge'),
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

  Widget _liveStrip(BuildContext context, bool expanded) {
    final p = context.pal;
    final rc = widget.roleContext;
    final speed = rc.fleetSpeedKmh == null
        ? '—'
        : '${rc.fleetSpeedKmh!.round()} km/h';

    if (!expanded) {
      return Padding(
        padding: const EdgeInsets.only(bottom: K.xs + 1),
        child: Center(
          child: Tooltip(
            message: 'Telematics live · ${rc.movingVehicles} moving · $speed',
            child: const LiveDot(size: 6),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(K.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: K.sm + 2, vertical: K.xs + 1),
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(K.rSm),
          border: Border.all(color: p.border),
        ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: K.xs),
            Flexible(
              child: Text(
                '${rc.movingVehicles} mv · $speed',
                style: TextStyle(
                  fontSize: K.caption,
                  fontWeight: FontWeight.w700,
                  color: p.textSecondary,
                  fontFamily: 'Inter',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile: bottom navigation + More sheet ────────────────────────────────

  Widget _mobile(BuildContext context) {
    final p = context.pal;
    final primaryCount = widget.destinations.length > 5 ? 4 : widget.destinations.length;
    final hasMore = widget.destinations.length > primaryCount;

    return Scaffold(
      backgroundColor: p.bg,
      body: widget.body,
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
                if (hasMore) Expanded(child: _moreButton(context)),
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
    final d = widget.destinations[index];
    final selected = index == widget.currentIndex;
    final badge = d.badgeKey == null ? 0 : (widget.badgeCounts[d.badgeKey] ?? 0);

    return Expanded(
      child: InkWell(
        onTap: () => widget.onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              offset: const Offset(8, -5),
              backgroundColor: p.critical,
              textStyle: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
              label: Text(badge > 99 ? '99+' : '$badge'),
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
    final anySelected = widget.currentIndex >= 4;
    final moreLabel = anySelected ? widget.destinations[widget.currentIndex].label : 'More';

    return Expanded(
      child: InkWell(
        onTap: () => _openMoreSheet(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              anySelected
                  ? (widget.destinations[widget.currentIndex].selectedIcon ?? widget.destinations[widget.currentIndex].icon)
                  : Icons.grid_view_rounded,
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
    final primaryCount = widget.destinations.length > 5 ? 4 : widget.destinations.length;
    final rest = widget.destinations.sublist(primaryCount);
    final rc = widget.roleContext;
    final color = roleColor(context, rc.role);

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
              // Account section — switch workspace.
              Padding(
                padding: const EdgeInsets.fromLTRB(K.lg, K.md, K.lg, K.xs),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openRolePicker(context);
                  },
                  borderRadius: BorderRadius.circular(K.rMd),
                  child: Container(
                    padding: const EdgeInsets.all(K.sm + 2),
                    decoration: BoxDecoration(
                      color: p.surfaceAlt,
                      borderRadius: BorderRadius.circular(K.rMd),
                      border: Border.all(color: p.border),
                    ),
                    child: Row(
                      children: [
                        RoleBadge(role: rc.role, size: 30, color: color),
                        const SizedBox(width: K.sm + 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rc.userName,
                                style: TextStyle(
                                  fontSize: K.subtitle,
                                  fontWeight: FontWeight.w700,
                                  color: p.text,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              Text(
                                '${rc.role.label} · tap to switch workspace',
                                style: TextStyle(
                                  fontSize: K.caption,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.swap_horiz_rounded, size: 16, color: color),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(K.lg, K.xs, K.lg, K.xs),
                child: Text(
                  'ALL MODULES',
                  style: TextStyle(
                    fontSize: K.micro,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: p.textTertiary,
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
                    color: widget.currentIndex == primaryCount + i ? p.primary : p.textSecondary,
                  ),
                  title: Text(
                    rest[i].label,
                    style: TextStyle(
                      fontSize: K.body,
                      fontWeight: FontWeight.w600,
                      color: widget.currentIndex == primaryCount + i ? p.primary : p.text,
                      fontFamily: 'Inter',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    widget.onTap(primaryCount + i);
                  },
                ),
              const SizedBox(height: K.sm),
            ],
          ),
        );
      },
    );
  }

  // ── Role workspace switcher ───────────────────────────────────────────────

  void _openRolePicker(BuildContext context) => showRolePicker(context);
}
