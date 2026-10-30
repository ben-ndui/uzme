import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uzme/config/map_styles.dart';
import 'package:uzme/core/blocs/map/map_state.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// Carte en cours de premier chargement — extrait de `StudioMapView` pour
/// tenir sous 250 lignes.
class StudioMapLoading extends StatelessWidget {
  final MapState state;
  final void Function(GoogleMapController) onMapCreated;

  const StudioMapLoading({
    super.key,
    required this.state,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0D0D0F) : Colors.grey.shade200,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: state.userLocation, zoom: 14),
            style: MapStyles.forBrightness(Theme.of(context).brightness),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: onMapCreated,
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.searchingStudios),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
