import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/blocs/blocs_exports.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/favorite.dart';
import 'package:uzme/core/models/pro_profile.dart';
import 'package:uzme/widgets/common/detail_photo_header.dart';
import 'package:uzme/widgets/common/detail_sticky_header_bar.dart';
import 'package:uzme/widgets/common/smooth_draggable_widget.dart';
import 'package:uzme/widgets/favorite/favorite_button.dart';
import 'package:uzme/widgets/pro/pro_detail_actions.dart';
import 'package:uzme/widgets/pro/pro_detail_contact_footer.dart';
import 'package:uzme/widgets/pro/pro_detail_header.dart';
import 'package:uzme/widgets/pro/pro_detail_info.dart';

/// Bottom sheet showing detailed pro profile info.
class ProDetailBottomSheet extends StatelessWidget {
  final AppUser user;

  const ProDetailBottomSheet({super.key, required this.user});

  ProProfile get _profile => user.proProfile!;

  /// Photo de profil puis portfolio — dédupliquées (le portfolio peut déjà
  /// contenir l'avatar, ou une même photo plusieurs fois) pour la galerie
  /// du header.
  List<String> get _photoUrls {
    final avatar = user.displayPhotoUrl;
    final seen = <String>{if (avatar != null) avatar};
    return [
      if (avatar != null) avatar,
      for (final url in _profile.portfolioUrls)
        if (seen.add(url)) url,
    ];
  }

  static Future<void> show(BuildContext context, AppUser user) {
    final authBloc = context.read<AuthBloc>();
    final messagingBloc = context.read<MessagingBloc>();
    final favoriteBloc = context.read<FavoriteBloc>();

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // SmoothDraggableWidget gère déjà sa propre poignée de drag.
      enableDrag: false,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: messagingBloc),
          BlocProvider.value(value: favoriteBloc),
        ],
        child: ProDetailBottomSheet(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SmoothDraggableWidget(
      initial: 0.55,
      minSize: 0.35,
      maxSize: 0.92,
      pinnedHeader: DetailStickyHeaderBar(
        name: _profile.displayName,
        rating: _profile.rating,
      ),
      pinnedHeaderHeight: 44,
      pinnedFooter: ProDetailContactFooter(user: user, profile: _profile),
      bodyContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DetailPhotoHeader(
            photoUrls: _photoUrls,
            placeholderIcon: FontAwesomeIcons.user,
            topRight: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: FavoriteButton(
                targetId: user.uid,
                type: FavoriteType.pro,
                targetName: _profile.displayName,
                targetPhotoUrl: user.displayPhotoUrl,
                targetAddress: _profile.city,
                size: 20,
                inactiveColor: Colors.white,
              ),
            ),
          ),
          ProDetailTitleRow(user: user, profile: _profile),
          ProDetailInfo(profile: _profile),
          ProDetailActions(user: user, profile: _profile),
          // Espace réservé pour ne jamais passer sous la barre d'action ancrée.
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
