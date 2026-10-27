import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/blocs/blocs_exports.dart';
import 'package:uzme/core/blocs/map/map_bloc.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/models/favorite.dart';
import 'package:uzme/core/services/payment_config_service.dart';
import 'package:uzme/core/services/studio_discovery_service.dart';
import 'package:uzme/widgets/artist/studio_detail_actions.dart';
import 'package:uzme/widgets/artist/studio_detail_badges.dart';
import 'package:uzme/widgets/artist/studio_detail_info.dart';
import 'package:uzme/widgets/common/detail_photo_header.dart';
import 'package:uzme/widgets/favorite/favorite_button.dart';

/// Bottom sheet showing studio details for authenticated artists
class StudioDetailBottomSheet extends StatefulWidget {
  final DiscoveredStudio studio;
  final StudioDiscoveryService? discoveryService;
  final PaymentConfigService? paymentConfigService;

  const StudioDetailBottomSheet({
    super.key,
    required this.studio,
    this.discoveryService,
    this.paymentConfigService,
  });

  static Future<void> show(BuildContext context, DiscoveredStudio studio) {
    final authBloc = context.read<AuthBloc>();
    final favoriteBloc = context.read<FavoriteBloc>();
    // MapBloc may not exist if opened from outside the map screen
    MapBloc? mapBloc;
    try {
      mapBloc = context.read<MapBloc>();
    } catch (_) {}

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: favoriteBloc),
          if (mapBloc != null) BlocProvider.value(value: mapBloc),
        ],
        child: StudioDetailBottomSheet(studio: studio),
      ),
    );
  }

  @override
  State<StudioDetailBottomSheet> createState() => _StudioDetailBottomSheetState();
}

class _StudioDetailBottomSheetState extends State<StudioDetailBottomSheet> {
  late List<String> _photoUrls = widget.studio.photoUrls;
  bool _loadingMorePhotos = false;

  @override
  void initState() {
    super.initState();
    // Studio Google (non-partenaire, non-pro) : un seul appel Details à
    // l'ouverture, jamais depuis la liste/carte — caché par placeId côté
    // service. Un partenaire ou un pro a déjà sa galerie définitive
    // (Firestore), appeler le service dessus gaspillerait une requête
    // Google avec un placeId qui n'en est pas un.
    if (!widget.studio.isPartner && !widget.studio.isPro) {
      // Nearby/Text Search ne rendent jamais plus d'une photo : tant qu'on
      // n'a rien du tout, le header doit afficher un vrai indicateur de
      // chargement plutôt qu'un vide silencieux.
      _loadingMorePhotos = _photoUrls.isEmpty;
      final discoveryService = widget.discoveryService ?? StudioDiscoveryService();
      discoveryService.getStudioPhotoUrls(widget.studio).then((urls) {
        if (!mounted) return;
        setState(() {
          _photoUrls = urls;
          _loadingMorePhotos = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studio = widget.studio;

    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DetailPhotoHeader(
              photoUrls: _photoUrls,
              isLoading: _loadingMorePhotos,
              placeholderIcon: FontAwesomeIcons.buildingUser,
              topRight: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: FavoriteButton(
                  targetId: studio.id,
                  type: FavoriteType.studio,
                  targetName: studio.name,
                  targetPhotoUrl: studio.photoUrl,
                  targetAddress: studio.address,
                  size: 20,
                  inactiveColor: Colors.white,
                ),
              ),
            ),
            StudioDetailTitleRow(studio: studio),
            StudioDetailInfo(studio: studio, paymentConfigService: widget.paymentConfigService),
            StudioDetailActions(studio: studio),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
