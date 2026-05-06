import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/routing/app_routes.dart';

/// Settings tile that opens the role comparator screen. Visually
/// emphasized with a gradient + glow so it stands out among regular
/// settings rows — Ben's spec is "mise en avant particulier
/// visuellement". Lives in the existing "Compte / Profil" section,
/// shared across artist / studio / engineer settings pages.
class SettingsRoleSwitchTile extends StatelessWidget {
  const SettingsRoleSwitchTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.roleSwitch),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                const Color(0xFFFFB800).withValues(alpha: 0.16),
                const Color(0xFF10B981).withValues(alpha: 0.18),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon stack — 3 micro-icons stacked to evoke "compare 3 roles"
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  children: [
                    _MiniIcon(
                      icon: FontAwesomeIcons.music,
                      color: const Color(0xFF8B5CF6),
                      offset: const Offset(0, 0),
                    ),
                    _MiniIcon(
                      icon: FontAwesomeIcons.buildingUser,
                      color: const Color(0xFFFFB800),
                      offset: const Offset(14, 14),
                    ),
                    _MiniIcon(
                      icon: FontAwesomeIcons.headphones,
                      color: const Color(0xFF10B981),
                      offset: const Offset(28, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.roleSwitchTileTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.roleSwitchTileSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 14,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Offset offset;
  const _MiniIcon({
    required this.icon,
    required this.color,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Center(child: FaIcon(icon, size: 11, color: Colors.white)),
      ),
    );
  }
}
