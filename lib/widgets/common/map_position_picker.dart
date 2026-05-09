import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/geocoding_service.dart';

/// Two-way address ↔ position picker used inside studio + manual studio
/// forms (and anywhere we need a structured place input).
///
/// Behaviour:
/// - User types an address → Places autocomplete suggestions are shown
///   in a dropdown. Tapping a suggestion resolves it to lat/lng (Place
///   Details), centers the map and drops the marker.
/// - User taps the map (or drags the marker) → reverse geocoding fills
///   the address field with the canonical formatted address.
/// - The picker is fully controlled: parent owns the
///   `MapPickerResult?` state and updates it via [onChanged].
///
/// The map is fixed-height so the picker fits inside any form layout
/// without internal scrolling. The autocomplete dropdown floats over
/// the map so we don't push form content around as suggestions show.
class MapPositionPicker extends StatefulWidget {
  /// Initial address pre-filled in the text field. If null, the field
  /// starts empty.
  final String? initialAddress;

  /// Initial lat/lng to focus the map on. If null, the map opens on
  /// [fallbackCenter] without a marker until the user picks something.
  final LatLng? initialPosition;

  /// Center used when no [initialPosition] is provided. Defaults to
  /// Paris (UZME's primary market). Pass the user's current location
  /// for better UX when known.
  final LatLng fallbackCenter;

  /// Decoration label for the address field — defaults to "Adresse".
  final String? labelText;

  /// Map widget height. Default fits typical forms.
  final double mapHeight;

  /// Notifies the parent every time the address or position changes.
  /// Receives null when the user clears the field.
  final ValueChanged<MapPickerResult?> onChanged;

  const MapPositionPicker({
    super.key,
    this.initialAddress,
    this.initialPosition,
    this.fallbackCenter = const LatLng(48.8566, 2.3522),
    this.labelText,
    this.mapHeight = 220,
    required this.onChanged,
  });

  @override
  State<MapPositionPicker> createState() => _MapPositionPickerState();
}

class _MapPositionPickerState extends State<MapPositionPicker> {
  final GeocodingService _geocoding = GeocodingService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  GoogleMapController? _mapController;

  Timer? _debounce;
  List<PlacesSuggestion> _suggestions = const [];
  bool _searching = false;
  bool _suppressNextAutocomplete = false;
  LatLng? _position;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialAddress ?? '';
    _position = widget.initialPosition;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _mapController = null;
    super.dispose();
  }

  void _onAddressChanged(String value) {
    if (_suppressNextAutocomplete) {
      _suppressNextAutocomplete = false;
      return;
    }
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _suggestions = const []);
      widget.onChanged(null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _searching = true);
      final results = await _geocoding.autocomplete(value, bias: _position);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _searching = false;
      });
    });
  }

  Future<void> _onSuggestionTap(PlacesSuggestion s) async {
    _focusNode.unfocus();
    _suppressNextAutocomplete = true;
    setState(() {
      _controller.text = s.description;
      _suggestions = const [];
      _searching = true;
    });
    final details = await _geocoding.getPlaceDetails(s.placeId);
    if (!mounted) return;
    setState(() => _searching = false);
    if (details == null) return;
    setState(() => _position = details.position);
    _suppressNextAutocomplete = true;
    _controller.text = details.formattedAddress;
    await _moveCamera(details.position);
    widget.onChanged(MapPickerResult(
      address: details.formattedAddress,
      position: details.position,
    ));
  }

  Future<void> _onMapTap(LatLng latLng) async {
    setState(() {
      _position = latLng;
      _suggestions = const [];
      _searching = true;
    });
    final address = await _geocoding.reverseGeocode(latLng);
    if (!mounted) return;
    setState(() => _searching = false);
    if (address != null) {
      _suppressNextAutocomplete = true;
      _controller.text = address;
      widget.onChanged(MapPickerResult(address: address, position: latLng));
    } else {
      // Reverse geocode failed — still report the position with
      // whatever the user had typed so we never lose data.
      widget.onChanged(MapPickerResult(
        address: _controller.text,
        position: latLng,
      ));
    }
  }

  Future<void> _moveCamera(LatLng to) async {
    if (_mapController == null) return;
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(to, 15),
      );
    } catch (_) {
      // Controller was disposed while we awaited — ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialCenter = _position ?? widget.fallbackCenter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Address field
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText ?? 'Adresse',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _suggestions = const [];
                            _position = null;
                          });
                          widget.onChanged(null);
                        },
                      )
                    : null),
          ),
          onChanged: _onAddressChanged,
        ),

        // Suggestions dropdown
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: _suggestions.map((s) {
                return InkWell(
                  onTap: () => _onSuggestionTap(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.locationDot, size: 14),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.mainText ?? s.description,
                                style: theme.textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (s.secondaryText != null)
                                Text(
                                  s.secondaryText!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 12),

        // Map
        SizedBox(
          height: widget.mapHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialCenter,
                zoom: _position != null ? 15 : 11,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: _onMapTap,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: _position == null
                  ? const {}
                  : {
                      Marker(
                        markerId: const MarkerId('picker'),
                        position: _position!,
                        draggable: true,
                        onDragEnd: _onMapTap,
                      ),
                    },
            ),
          ),
        ),

        const SizedBox(height: 8),
        Text(
          'Tape une adresse, clique sur la carte ou glisse l\'épingle pour ajuster.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// Output of [MapPositionPicker] — what gets handed back to the parent
/// every time the user changes the address or moves the marker.
class MapPickerResult {
  final String address;
  final LatLng position;

  const MapPickerResult({required this.address, required this.position});

  @override
  String toString() =>
      'MapPickerResult(address: $address, lat: ${position.latitude}, lng: ${position.longitude})';
}
