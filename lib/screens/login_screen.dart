import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/widgets.dart';

/// Sign-in experience: pick a demo account, authenticate (simulated), land
/// in that role's workspace. Wide screens get a brand panel with a live
/// fleet teaser; small screens a compact single column.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  FleetUser? _selected;
  final _password = TextEditingController();
  bool _obscure = true;
  bool _signingIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Preselect the account matching the last workspace for convenience.
    final state = context.read<AppState>();
    _selected = kFleetUsers.where((u) => u.role == state.role).firstOrNull;
    _password.text = 'kompact'; // demo credential, pre-filled
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _signIn() {
    final user = _selected;
    if (user == null) {
      setState(() => _error = 'Select an account to continue.');
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter a password (demo: any password works).');
      return;
    }
    setState(() {
      _error = null;
      _signingIn = true;
    });
    // Simulated handshake with the telematics cloud, then enter the shell.
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      context.read<AppState>().signIn(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final wide = MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      backgroundColor: p.bg,
      body: wide
          ? Row(
              children: [
                Expanded(child: _brandPanel(context)),
                SizedBox(
                  width: 460,
                  child: Center(child: _signInCard(context)),
                ),
              ],
            )
          : _narrow(context),
    );
  }

  // ── Narrow (phone) layout ────────────────────────────────────────────────

  Widget _narrow(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(K.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _logoLockup(context, center: true),
                const SizedBox(height: K.xl),
                _signInCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Brand panel (desktop left side) ──────────────────────────────────────

  Widget _brandPanel(BuildContext context) {
    final state = context.watch<AppState>();
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF0D1526), Color(0xFF0B0F16)]
              : const [Color(0xFF101B33), Color(0xFF1C2E54)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(K.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _logoLockup(context, onDark: true),
              const Spacer(),
              Text(
                'One telematics pipeline.\nSeven role-based workspaces.',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: K.md),
              Text(
                'Kompact frames live fleet data for the decision each persona actually makes — from the driver\'s HOS clock to the boardroom benchmark scorecard.',
                style: TextStyle(
                  fontSize: K.subtitle,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.72),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: K.xxxl),
              _teaserStats(context, state),
              const Spacer(),
              Row(
                children: [
                  const LiveDot(size: 6, color: Color(0xFF4ADE80)),
                  const SizedBox(width: K.sm),
                  Text(
                    'IoT · Cloud telematics · Predictive maintenance · Geofencing',
                    style: TextStyle(
                      fontSize: K.label,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.55),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: K.xs),
              Text(
                'Fleet demo environment — simulated data, no real vehicles were harmed.',
                style: TextStyle(
                  fontSize: K.caption,
                  color: Colors.white.withValues(alpha: 0.38),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teaserStats(BuildContext context, AppState state) {
    final stats = <(String, String)>[
      ('${state.vehicles.length}', 'Assets tracked'),
      ('${state.onRouteCount}', 'On route now'),
      ('${(state.avgOnTimeRate * 100).toStringAsFixed(0)}%', 'On-time rate'),
      (state.avgSafetyScore.toStringAsFixed(0), 'Safety score'),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: K.xl),
            Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.14)),
            const SizedBox(width: K.xl),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats[i].$1,
                style: TextStyle(
                  fontSize: K.display,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: K.xxs),
              Text(
                stats[i].$2.toUpperCase(),
                style: TextStyle(
                  fontSize: K.micro,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _logoLockup(BuildContext context, {bool onDark = false, bool center = false}) {
    final p = context.pal;
    return Row(
      mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: onDark ? Colors.white : p.primary,
            borderRadius: BorderRadius.circular(K.rMd),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.local_shipping_rounded,
            size: 19,
            color: onDark ? const Color(0xFF101B33) : p.primaryFg,
          ),
        ),
        const SizedBox(width: K.md),
        Column(
          crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              'KOMPACT',
              style: TextStyle(
                fontSize: K.headline,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: onDark ? Colors.white : p.text,
                fontFamily: 'Inter',
              ),
            ),
            Text(
              'Fleet Management',
              style: TextStyle(
                fontSize: K.label,
                fontWeight: FontWeight.w600,
                color: onDark ? Colors.white.withValues(alpha: 0.6) : p.textTertiary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Sign-in card ─────────────────────────────────────────────────────────

  Widget _signInCard(BuildContext context) {
    final p = context.pal;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(K.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign in',
              style: TextStyle(
                fontSize: K.display,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: p.text,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: K.xxs + 1),
            Text(
              'Choose a demo account — each opens a different workspace.',
              style: TextStyle(
                fontSize: K.body,
                height: 1.4,
                color: p.textTertiary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: K.lg),

            // Account directory.
            Text(
              'DEMO ACCOUNTS',
              style: TextStyle(
                fontSize: K.micro,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                color: p.textTertiary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: K.sm),
            for (final u in kFleetUsers)
              _accountTile(context, u),
            const SizedBox(height: K.lg),

            // Credential field.
            if (_selected != null) ...[
              _credentialField(context),
              const SizedBox(height: K.md),
            ],

            if (_error != null) ...[
              Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 13, color: p.critical),
                  const SizedBox(width: K.sm),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w600,
                        color: p.critical,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: K.md),
            ],

            _signInButton(context),

            const SizedBox(height: K.md),
            Center(
              child: Text(
                'Sessions persist on this device · Passwords are simulated for the demo',
                style: TextStyle(
                  fontSize: K.caption,
                  color: p.textTertiary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountTile(BuildContext context, FleetUser u) {
    final p = context.pal;
    final selected = _selected?.id == u.id;
    final color = roleColor(context, u.role);

    return Padding(
      padding: const EdgeInsets.only(bottom: K.xs + 1),
      child: Material(
        color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(K.rMd),
        child: InkWell(
          onTap: () => setState(() {
            _selected = u;
            _error = null;
          }),
          borderRadius: BorderRadius.circular(K.rMd),
          hoverColor: p.surfaceAlt,
          child: Container(
            padding: const EdgeInsets.all(K.sm + 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(K.rMd),
              border: Border.all(
                color: selected ? color.withValues(alpha: 0.55) : p.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar with initials on the role hue.
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HSLColor.fromAHSL(1, u.hue.toDouble(), 0.55, 0.42).toColor(),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    u.initials,
                    style: const TextStyle(
                      fontSize: K.label,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: K.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              u.name,
                              style: TextStyle(
                                fontSize: K.subtitle,
                                fontWeight: FontWeight.w700,
                                color: p.text,
                                fontFamily: 'Inter',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check_circle_rounded, size: 15, color: color),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: K.xs + 2, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(K.rSm),
                            ),
                            child: Text(
                              u.role.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: K.micro,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: color,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          const SizedBox(width: K.sm),
                          Flexible(
                            child: Text(
                              u.title,
                              style: TextStyle(
                                fontSize: K.caption,
                                color: p.textTertiary,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _credentialField(BuildContext context) {
    final p = context.pal;
    final u = _selected!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          u.email,
          style: TextStyle(
            fontSize: K.body,
            fontWeight: FontWeight.w600,
            color: p.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: K.sm),
        TextField(
          controller: _password,
          obscureText: _obscure,
          onSubmitted: (_) => _signIn(),
          style: TextStyle(fontSize: K.body, fontFamily: 'Inter', color: p.text),
          decoration: InputDecoration(
            isDense: true,
            labelText: 'Password',
            labelStyle: TextStyle(fontSize: K.label, fontFamily: 'Inter'),
            prefixIcon: Icon(Icons.lock_outline_rounded, size: 15, color: p.textTertiary),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 15, color: p.textTertiary),
              onPressed: () => setState(() => _obscure = !_obscure),
              visualDensity: VisualDensity.compact,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: K.md, vertical: K.sm + 2),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(K.rMd),
              borderSide: BorderSide(color: p.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(K.rMd),
              borderSide: BorderSide(color: p.primary, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _signInButton(BuildContext context) {
    final p = context.pal;
    final color = _selected == null ? p.primary : roleColor(context, _selected!.role);

    return SizedBox(
      height: 42,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rMd)),
          textStyle: const TextStyle(
            fontSize: K.subtitle,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            fontFamily: 'Inter',
          ),
        ),
        onPressed: _signingIn ? null : _signIn,
        child: _signingIn
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(_selected == null
                ? 'Select an account'
                : 'Sign in as ${_selected!.role.shortLabel}'),
      ),
    );
  }
}
