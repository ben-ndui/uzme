import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Header carrousel plein cadre pour un bottom sheet de détail (studio, pro).
///
/// Gère ses quatre états lui-même : chargement (aucune photo connue pour
/// l'instant, ex. premier appel Google Places Details en cours), erreur
/// (l'appel a échoué et on n'a aucune photo de repli — distinct du vide,
/// sinon un studio sans photo et un échec réseau se ressemblent), vide
/// (aucune photo du tout — icône de repli), et galerie (une ou plusieurs
/// photos, avec pastilles de pagination au-delà de la première).
class DetailPhotoHeader extends StatefulWidget {
  final List<String> photoUrls;
  final List<String?> attributions;
  final bool isLoading;
  final bool hasError;
  final FaIconData placeholderIcon;
  final Widget? topRight;
  final double height;

  const DetailPhotoHeader({
    super.key,
    required this.photoUrls,
    required this.placeholderIcon,
    this.attributions = const [],
    this.isLoading = false,
    this.hasError = false,
    this.topRight,
    this.height = 220,
  });

  @override
  State<DetailPhotoHeader> createState() => _DetailPhotoHeaderState();
}

class _DetailPhotoHeaderState extends State<DetailPhotoHeader> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void didUpdateWidget(DetailPhotoHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La galerie peut grandir après-coup (fetch Google en arrière-plan) :
    // si elle rétrécit sous la page affichée, revenir à la première photo
    // plutôt que de pointer hors liste.
    if (_page >= widget.photoUrls.length && widget.photoUrls.isNotEmpty) {
      _page = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) _pageController.jumpToPage(0);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Pas d'arrondi ici : la photo est désormais sous la poignée + la barre
    // compacte du sheet (SmoothDraggableWidget), qui porte déjà le seul
    // arrondi visible en haut — un second rayon ici créait un "step" disgracieux.
    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildGallery(theme),
          if (widget.topRight != null)
            Positioned(top: 12, right: 12, child: widget.topRight!),
          if (widget.photoUrls.length > 1) _buildDots(theme),
          _buildAttribution(theme),
        ],
      ),
    );
  }

  Widget _buildGallery(ThemeData theme) {
    if (widget.photoUrls.isEmpty) {
      if (widget.isLoading) {
        return _placeholder(theme, child: const CircularProgressIndicator());
      }
      if (widget.hasError) {
        return _placeholder(
          theme,
          child: FaIcon(
            FontAwesomeIcons.triangleExclamation,
            size: 40,
            color: theme.colorScheme.error,
          ),
        );
      }
      return _placeholder(
        theme,
        child: FaIcon(
          widget.placeholderIcon,
          size: 40,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: widget.photoUrls.length,
      onPageChanged: (i) => setState(() => _page = i),
      itemBuilder: (_, i) => Image.network(
        widget.photoUrls[i],
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : _placeholder(theme, child: const CircularProgressIndicator()),
        errorBuilder: (_, __, ___) => _placeholder(
          theme,
          child: FaIcon(
            widget.placeholderIcon,
            size: 40,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// Crédit obligatoire (CGU Google Places) de la photo affichée — absent
  /// hors Google (partenaire, pro) où [DetailPhotoHeader.attributions] est vide.
  Widget _buildAttribution(ThemeData theme) {
    if (_page >= widget.attributions.length) return const SizedBox.shrink();
    final credit = widget.attributions[_page];
    if (credit == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 6,
      left: 10,
      child: Text(
        credit,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.85),
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 3),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme, {required Widget child}) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildDots(ThemeData theme) {
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.photoUrls.length, (i) {
          final active = i == _page;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: active ? 1 : 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}
