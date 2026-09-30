import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'widgets.dart';

/// Opens the role workspace switcher — bottom sheet on phones, dialog on
/// desktop. Switching re-frames the entire shell: dashboard, modules and
/// sidebar badges all follow the selected persona.
Future<void> showRolePicker(BuildContext context) {
  final isMobile = MediaQuery.sizeOf(context).width < 700;
  if (isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.pal.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(K.rLg)),
      ),
      builder: (_) => const RolePickerSheet(),
    );
  }
  return showDialog<void>(context: context, builder: (_) => const RolePickerDialog());
}

/// Compact chip showing the active workspace; tap to switch. Placed in the
/// page header of every role dashboard so the switcher is always one tap
/// away, even on mobile where there is no rail.
class RoleSwitchChip extends StatelessWidget {
  const RoleSwitchChip({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final role = state.role;
    final color = roleColor(context, role);

    return Tooltip(
      message: 'Switch workspace',
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(K.rSm),
        child: InkWell(
          onTap: () => showRolePicker(context),
          borderRadius: BorderRadius.circular(K.rSm),
          hoverColor: color.withValues(alpha: 0.16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: K.sm + 2, vertical: K.xs + 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoleBadge(role: role, size: 16, color: color),
                const SizedBox(width: K.xs + 1),
                Text(
                  role.shortLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: K.micro,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: color,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: K.xxs + 1),
                Icon(Icons.swap_vert_rounded, size: 11, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Role identity disc — icon on the role's hue.
class RoleBadge extends StatelessWidget {
  final FleetRole role;
  final double size;
  final Color color;

  const RoleBadge({super.key, required this.role, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      alignment: Alignment.center,
      child: Icon(role.icon, size: size * 0.52, color: Colors.white),
    );
  }
}

/// Desktop role switcher: one card per persona with its mandate.
class RolePickerDialog extends StatelessWidget {
  const RolePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final state = context.watch<AppState>();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(K.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Switch workspace',
                          style: TextStyle(
                            fontSize: K.headline,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: p.text,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Each role gets its own dashboard and modules.',
                          style: TextStyle(
                            fontSize: K.label,
                            color: p.textTertiary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: K.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final r in FleetRole.values)
                        RoleOptionCard(
                          role: r,
                          selected: r == state.role,
                          showDemoUser: true,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile role switcher sheet — same content, bottom-sheet chrome.
class RolePickerSheet extends StatelessWidget {
  const RolePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final state = context.watch<AppState>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(K.lg, K.md, K.lg, K.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Switch workspace',
              style: TextStyle(
                fontSize: K.headline,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: p.text,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'Each role gets its own dashboard and modules.',
              style: TextStyle(
                fontSize: K.label,
                color: p.textTertiary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: K.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final r in FleetRole.values)
                      RoleOptionCard(role: r, selected: r == state.role, showDemoUser: false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selectable persona card: badge, label, mandate, demo identity.
class RoleOptionCard extends StatelessWidget {
  final FleetRole role;
  final bool selected;
  final bool showDemoUser;

  const RoleOptionCard({
    super.key,
    required this.role,
    required this.selected,
    this.showDemoUser = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final color = roleColor(context, role);
    final state = context.read<AppState>();

    return Padding(
      padding: const EdgeInsets.only(bottom: K.xs + 1),
      child: Material(
        color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(K.rMd),
        child: InkWell(
          onTap: () {
            state.setRole(role);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(K.rMd),
          hoverColor: p.surfaceAlt,
          child: Container(
            padding: const EdgeInsets.all(K.sm + 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(K.rMd),
              border: Border.all(color: selected ? color.withValues(alpha: 0.5) : p.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoleBadge(role: role, size: 30, color: color),
                const SizedBox(width: K.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              role.label,
                              style: TextStyle(
                                fontSize: K.subtitle,
                                fontWeight: FontWeight.w700,
                                color: p.text,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check_circle_rounded, size: 15, color: color),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        role.mandate,
                        style: TextStyle(
                          fontSize: K.label,
                          height: 1.35,
                          color: p.textSecondary,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showDemoUser) ...[
                        const SizedBox(height: K.xxs + 1),
                        Text(
                          'Demo user: ${role.demoUser}',
                          style: TextStyle(
                            fontSize: K.caption,
                            fontWeight: FontWeight.w600,
                            color: p.textTertiary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
