import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Adaptive navigation shell.
///
/// Compact design: a 72dp icon rail on wide screens, a slim bottom bar on
/// narrow ones. Content is center-constrained on very wide displays so the
/// information density never stretches apart.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
    required this.body,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AdaptiveDestination> destinations;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 780;
    if (wide) return _wide(context);
    return _narrow(context);
  }

  Widget _wide(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            labelType: NavigationRailLabelType.all,
            minWidth: 68,
            minExtendedWidth: 76,
            leading: Padding(
              padding: const EdgeInsets.only(top: K.l, bottom: K.m),
              child: _Logo(),
            ),
            groupAlignment: -1,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon ?? d.icon),
                  label: Text(d.label),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                ),
            ],
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _narrow(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon ?? d.icon),
              label: d.label,
              tooltip: d.label,
            ),
        ],
      ),
    );
  }
}

class AdaptiveDestination {
  const AdaptiveDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Kompact',
      waitDuration: const Duration(milliseconds: 500),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Center(
          child: Text(
            'K',
            style: TextStyle(
              fontFamily: 'InterDisplay',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Page padding that adapts: tighter on mobile, roomier on wide screens.
class PagePadding extends StatelessWidget {
  const PagePadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 780;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        wide ? K.xl : K.l,
        wide ? K.l : K.l,
        wide ? K.xl : K.l,
        K.l,
      ),
      child: child,
    );
  }
}
