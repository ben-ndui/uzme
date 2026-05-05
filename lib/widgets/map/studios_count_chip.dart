import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/blocs/map/map_bloc.dart';
import 'package:uzme/core/blocs/map/map_state.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// Floating chip on the studio map that shows how many studios are
/// currently visible around the user, and within what radius. Updates
/// reactively when the bloc loads new studios or when the radius changes.
class StudiosCountChip extends StatelessWidget {
  const StudiosCountChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<MapBloc, MapState>(
      buildWhen: (prev, curr) =>
          prev.nearbyStudios.length != curr.nearbyStudios.length ||
          prev.searchRadius != curr.searchRadius ||
          prev.isLoading != curr.isLoading,
      builder: (context, state) {
        if (state.isLoading && state.nearbyStudios.isEmpty) {
          return const SizedBox.shrink();
        }

        final count = state.nearbyStudios.length;
        final radiusKm = (state.searchRadius / 1000).toStringAsFixed(
          state.searchRadius % 1000 == 0 ? 0 : 1,
        );

        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surfaceContainerHigh.withValues(alpha: 0.85)
                  : cs.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : cs.outlineVariant,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.locationDot,
                  size: 14,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.studiosCount(count),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: l10n.studiosCountRadiusSuffix(radiusKm),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
