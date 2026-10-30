import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uzme/config/useme_theme.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/map/custom_studio_pin.dart';
import 'package:uzme/widgets/map/studio_map_view.dart';

/// Génération et cache des pins custom (studio/pro/partenaire/sélectionné)
/// — extrait de `_StudioMapViewState` pour tenir sous 250 lignes.
mixin StudioMapPinsMixin on State<StudioMapView> {
  BitmapDescriptor? partnerPin;
  BitmapDescriptor? defaultPin;
  BitmapDescriptor? proPin;
  final Map<String, BitmapDescriptor> studioPins = {};

  String? selectedStudioId;
  BitmapDescriptor? selectedStudioPin;
  Brightness? lastBrightness;

  Color pinColorFor(DiscoveredStudio studio) {
    if (studio.isPioneer) return const Color(0xFFFFD700); // Gold
    if (studio.isPro) return UseMeTheme.accentColor;
    if (studio.isPartner) return Colors.green;
    return UseMeTheme.primaryColor;
  }

  Future<void> loadDefaultPins() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    partnerPin = await CustomStudioPin.createPinWithImage(
      imageUrl: null,
      pinColor: Colors.green,
      isDark: isDark,
    );
    defaultPin = await CustomStudioPin.createPinWithImage(
      imageUrl: null,
      pinColor: UseMeTheme.primaryColor,
      isDark: isDark,
    );
    proPin = await CustomStudioPin.createPinWithImage(
      imageUrl: null,
      pinColor: UseMeTheme.accentColor,
      isDark: isDark,
    );
    if (mounted) setState(() {});
  }

  Future<void> updateSelectedPin(DiscoveredStudio? studio) async {
    if (studio == null) {
      if (selectedStudioId != null) {
        setState(() {
          selectedStudioId = null;
          selectedStudioPin = null;
        });
      }
      return;
    }
    if (studio.id == selectedStudioId) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pin = await CustomStudioPin.createPinWithImage(
      imageUrl: studio.photoUrl,
      pinColor: pinColorFor(studio),
      isSelected: true,
      isDark: isDark,
    );
    if (mounted) {
      setState(() {
        selectedStudioId = studio.id;
        selectedStudioPin = pin;
      });
    }
  }

  Future<void> loadStudioPins(List<DiscoveredStudio> studios) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    for (final studio in studios) {
      if (!studioPins.containsKey(studio.id) && studio.photoUrl != null) {
        try {
          final pin = await CustomStudioPin.createPinWithImage(
            imageUrl: studio.photoUrl,
            pinColor: pinColorFor(studio),
            isDark: isDark,
          );
          if (mounted) {
            setState(() {
              studioPins[studio.id] = pin;
            });
          }
        } catch (e) {
          // Use default pin
        }
      }
    }
  }

  Set<Marker> buildMarkers(
    List<DiscoveredStudio> studios,
    void Function(DiscoveredStudio) onSelect,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final markers = <Marker>{};

    for (final studio in studios) {
      final isSelected = studio.id == selectedStudioId;
      BitmapDescriptor icon;
      if (isSelected && selectedStudioPin != null) {
        icon = selectedStudioPin!;
      } else if (studioPins.containsKey(studio.id)) {
        icon = studioPins[studio.id]!;
      } else if (studio.isPro && proPin != null) {
        icon = proPin!;
      } else if (studio.isPartner && partnerPin != null) {
        icon = partnerPin!;
      } else if (defaultPin != null) {
        icon = defaultPin!;
      } else {
        icon = studio.isPro
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
            : studio.isPartner
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      }

      markers.add(
        Marker(
          markerId: MarkerId(studio.id),
          position: studio.position,
          infoWindow: InfoWindow(
            title: studio.name,
            snippet: studio.isPro
                ? '${studio.formattedDistance} • Pro'
                : '${studio.formattedDistance}${studio.isPartner ? ' • ${l10n.partnerLabel}' : ''}',
          ),
          icon: icon,
          onTap: () => onSelect(studio),
        ),
      );
    }

    return markers;
  }
}
