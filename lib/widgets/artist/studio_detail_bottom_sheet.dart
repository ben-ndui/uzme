import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/blocs/blocs_exports.dart';
import 'package:uzme/core/blocs/map/map_bloc.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/models/favorite.dart';
import 'package:uzme/core/models/google_review.dart';
import 'package:uzme/core/services/payment_config_service.dart';
import 'package:uzme/core/services/studio_discovery_service.dart';
import 'package:uzme/widgets/artist/studio_detail_actions.dart';
import 'package:uzme/widgets/artist/studio_detail_badges.dart';
import 'package:uzme/widgets/artist/studio_detail_info.dart';
import 'package:uzme/widgets/artist/studio_detail_reviews.dart';
import 'package:uzme/widgets/common/detail_photo_header.dart';
import 'package:uzme/widgets/common/detail_sticky_header_bar.dart';
import 'package:uzme/widgets/common/smooth_draggable_widget.dart';
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
      // SmoothDraggableWidget gère déjà sa propre poignée de drag — un
      // deuxième système de drag (celui de la modale) ferait les deux se
      // disputer le même geste vertical.
      enableDrag: false,
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
  State<StudioDetailBottomSheet> createState() =>
      _StudioDetailBottomSheetState();
}

class _StudioDetailBottomSheetState extends State<StudioDetailBottomSheet> {
  late List<String> _photoUrls = widget.studio.photoUrls;
  List<String?> _photoAttributions = const [];
  List<GoogleReview> _reviews = const [];
  bool _loadingMorePhotos = false;
  bool _photosError = false;

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
      final discoveryService =
          widget.discoveryService ?? StudioDiscoveryService();
      discoveryService
          .getStudioPhotoUrls(widget.studio)
          .then((gallery) {
            if (!mounted) return;
            setState(() {
              _photoUrls = gallery.urls;
              _photoAttributions = gallery.attributions;
              _reviews = gallery.reviews;
              _loadingMorePhotos = false;
              _photosError = gallery.hasError;
            });
          })
          .catchError((Object _) {
            // Le service n'est pas censé laisser filtrer d'exception (toutes
            // les erreurs réseau sont déjà captées et traduites en hasError) —
            // ce filet évite juste au spinner de tourner pour toujours si ça
            // changeait un jour.
            if (!mounted) return;
            setState(() {
              _loadingMorePhotos = false;
              _photosError = true;
            });
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final studio = widget.studio;

    return SmoothDraggableWidget(
      initial: 0.55,
      minSize: 0.35,
      maxSize: 0.92,
      pinnedHeader: DetailStickyHeaderBar(
        name: studio.name,
        rating: studio.rating,
      ),
      pinnedHeaderHeight: 44,
      pinnedFooter: StudioDetailActions(studio: studio),
      bodyContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DetailPhotoHeader(
            photoUrls: _photoUrls,
            attributions: _photoAttributions,
            isLoading: _loadingMorePhotos,
            hasError: _photosError,
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
          StudioDetailInfo(
            studio: studio,
            paymentConfigService: widget.paymentConfigService,
          ),
          StudioDetailReviews(reviews: _reviews),
          // Espace réservé pour ne jamais passer sous la barre d'action ancrée.
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
