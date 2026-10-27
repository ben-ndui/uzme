import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/blocs/blocs_exports.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/favorite.dart';
import 'package:uzme/core/models/pro_profile.dart';
import 'package:uzme/widgets/common/detail_photo_header.dart';
import 'package:uzme/widgets/favorite/favorite_button.dart';
import 'package:uzme/widgets/pro/pro_detail_actions.dart';
import 'package:uzme/widgets/pro/pro_detail_header.dart';
import 'package:uzme/widgets/pro/pro_detail_info.dart';

/// Bottom sheet showing detailed pro profile info.
class ProDetailBottomSheet extends StatelessWidget {
  final AppUser user;

  const ProDetailBottomSheet({super.key, required this.user});

  ProProfile get _profile => user.proProfile!;

  /// Photo de profil puis portfolio — dédupliquées (le portfolio peut déjà
  /// contenir l'avatar) pour la galerie du header.
  List<String> get _photoUrls {
    final avatar = user.displayPhotoUrl;
    return [
      if (avatar != null) avatar,
      ..._profile.portfolioUrls.where((url) => url != avatar),
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
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DetailPhotoHeader(
              photoUrls: _photoUrls,
              placeholderIcon: FontAwesomeIcons.user,
              topRight: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
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
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
