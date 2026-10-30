import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smoothandesign_package/core/widgets/common/common_exports.dart';
import 'package:uzme/config/map_styles.dart';
import 'package:uzme/core/blocs/map/map_bloc.dart';
import 'package:uzme/core/blocs/map/map_event.dart';
import 'package:uzme/core/blocs/map/map_state.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/widgets/common/permission_dialog.dart';
import 'package:uzme/widgets/map/map_search_bar.dart';
import 'package:uzme/widgets/map/studio_map_list_fallback.dart';
import 'package:uzme/widgets/map/studio_map_loading.dart';
import 'package:uzme/widgets/map/studio_map_pins_mixin.dart';
import 'package:uzme/widgets/map/studios_count_chip.dart';

/// Google Maps view showing nearby studios with custom pins.
///
/// Sur macOS : `google_maps_flutter` n'a aucune implémentation pour cette
/// plateforme (bannière "not yet supported", constaté 30/10/2026) — on bascule
/// sur une liste ([StudioMapListFallback]) plutôt que de laisser un écran
/// cassé. Même source de données (`MapBloc`), juste sans widget carte.
class StudioMapView extends StatefulWidget {
  final Function(GoogleMapController)? onMapCreated;
  final Function(DiscoveredStudio)? onStudioTap;

  const StudioMapView({super.key, this.onMapCreated, this.onStudioTap});

  @override
  State<StudioMapView> createState() => _StudioMapViewState();
}

class _StudioMapViewState extends State<StudioMapView> with StudioMapPinsMixin {
  GoogleMapController? _mapController;
  bool _isControllerDisposed = false;
  LatLng? _currentCameraPosition;

  /// Cache statique : une fois la permission accordée, ne plus redemander
  static bool _locationPermissionHandled = false;

  @override
  void initState() {
    super.initState();
    _initWithPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (lastBrightness != brightness) {
      lastBrightness = brightness;
      loadDefaultPins();
    }
  }

  Future<void> _initWithPermission() async {
    if (!_locationPermissionHandled) {
      final geoPermission = await geo.Geolocator.checkPermission();
      final alreadyGranted =
          geoPermission == geo.LocationPermission.whileInUse ||
              geoPermission == geo.LocationPermission.always;

      if (alreadyGranted) {
        _locationPermissionHandled = true;
      } else {
        if (!mounted) return;
        final granted = await PermissionDialog.requestPermission(
          context,
          type: AppPermissionType.location,
        );
        if (granted) _locationPermissionHandled = true;
      }
    }
    if (!mounted) return;
    context.read<MapBloc>().add(const InitMapEvent());
  }

  @override
  void dispose() {
    _isControllerDisposed = true;
    _mapController = null;
    super.dispose();
  }

  void _safeAnimateCamera(LatLng location, double zoom) {
    if (_isControllerDisposed || _mapController == null || !mounted) return;
    try {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, zoom));
    } catch (e) {
      // Controller was disposed, ignore
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    widget.onMapCreated?.call(controller);
  }

  void _onSelectStudio(DiscoveredStudio studio) {
    context.read<MapBloc>().add(SelectStudioEvent(studio: studio));
    widget.onStudioTap?.call(studio);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MapBloc, MapState>(
      listenWhen: (previous, current) {
        if (!mounted || _isControllerDisposed) return false;
        final searchCompleted = previous.isSearchingAddress && !current.isSearchingAddress;
        final studiosLoaded = previous.isLoading && !current.isLoading;
        final newStudios = previous.nearbyStudios.length != current.nearbyStudios.length;
        final selectionChanged = previous.selectedStudio != current.selectedStudio;
        final directionsChanged = previous.directions != current.directions;
        return searchCompleted || studiosLoaded || newStudios || selectionChanged || directionsChanged;
      },
      listener: (context, state) {
        if (!mounted || _isControllerDisposed) return;

        if (state.hasDirections && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(state.directions!.bounds, 80),
          );
          return;
        }

        if (_mapController != null && !state.isSearchingAddress) {
          final zoom = state.selectedStudio != null ? 16.0 : 13.0;
          _safeAnimateCamera(state.searchCenter, zoom);
        }
        updateSelectedPin(state.selectedStudio);
        if (mounted) loadStudioPins(state.nearbyStudios);
      },
      builder: (context, state) {
        if (Platform.isMacOS) {
          return Stack(
            children: [
              StudioMapListFallback(
                isLoading: state.isLoading,
                studios: state.filteredStudios,
                onStudioTap: _onSelectStudio,
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: const MapSearchBar(),
              ),
            ],
          );
        }

        if (state.isLoading && state.nearbyStudios.isEmpty) {
          return StudioMapLoading(state: state, onMapCreated: _onMapCreated);
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: state.userLocation, zoom: 14),
              style: MapStyles.forBrightness(Theme.of(context).brightness),
              markers: buildMarkers(state.filteredStudios, _onSelectStudio),
              polylines: state.routePolylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              onMapCreated: _onMapCreated,
              onCameraMove: (position) => _currentCameraPosition = position.target,
              onCameraIdle: () {
                if (_currentCameraPosition != null) {
                  context.read<MapBloc>().add(
                        UpdateSearchCenterEvent(center: _currentCameraPosition!),
                      );
                }
              },
              onTap: (_) => context.read<MapBloc>().add(const DeselectStudioEvent()),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: const MapSearchBar(),
            ),
            DraggableWidget(
              initialX: MediaQuery.of(context).size.width - 180 - 16,
              initialY: MediaQuery.of(context).padding.top + 60 + 48 + 12,
              child: const StudiosCountChip(),
            ),
            Positioned(
              bottom: 180,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'location',
                backgroundColor: Theme.of(context).colorScheme.surface,
                onPressed: () => _safeAnimateCamera(state.userLocation, 15),
                child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}
