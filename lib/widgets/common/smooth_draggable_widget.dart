import 'package:flutter/material.dart';
import 'package:uzme/config/useme_theme.dart';

part 'smooth_draggable_background.dart';

/// Collapsible draggable sheet widget - adapted from Viba
class SmoothDraggableWidget extends StatefulWidget {
  const SmoothDraggableWidget({
    super.key,
    required this.bodyContent,
    this.floatButtons = const [],
    this.maxSize = 1,
    this.minSize = 0.12,
    this.initial = 0.5,
    this.threshold = 0.6,
    this.color1,
    this.color2,
    this.bottomPadding = 20,
    this.floatingBottomPadding = 40,
    this.pinnedHeader,
    this.pinnedHeaderHeight = 0,
    this.pinnedFooter,
  });

  final Widget bodyContent;
  final List<Widget> floatButtons;
  final double maxSize;
  final double minSize;
  final double initial;
  final double threshold;
  final Color? color1;
  final Color? color2;
  final double bottomPadding;
  final double floatingBottomPadding;

  /// Barre compacte (ex. nom + note) toujours visible sous la poignée,
  /// même feuille repliée — contrairement au contenu de [bodyContent], qui
  /// défile. Nécessite [pinnedHeaderHeight] pour réserver sa place dans le
  /// scroll (sinon le premier élément de [bodyContent] démarre dessous).
  final Widget? pinnedHeader;
  final double pinnedHeaderHeight;

  /// Barre d'action ancrée en bas, toujours visible (contrairement à
  /// [floatButtons], qui n'apparaît qu'au-delà de [threshold]). Gère
  /// elle-même sa zone de sécurité bas d'écran.
  final Widget? pinnedFooter;

  @override
  State<SmoothDraggableWidget> createState() => _SmoothDraggableWidgetState();
}

class _SmoothDraggableWidgetState extends State<SmoothDraggableWidget> {
  DraggableScrollableController controller = DraggableScrollableController();
  final ValueNotifier<bool> showButtons = ValueNotifier(false);
  final ValueNotifier<bool> showDragHandle = ValueNotifier(true);
  final ValueNotifier<double> safeAreaPadding = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    controller.addListener(_onSheetScroll);
  }

  void _onSheetScroll() {
    final normalizedSize =
        (controller.size - widget.minSize) / (widget.maxSize - widget.minSize);

    // Update floating action buttons visibility
    if (controller.size <= widget.minSize) {
      if (showButtons.value != false) showButtons.value = false;
    } else if (normalizedSize > widget.threshold) {
      if (showButtons.value != true) showButtons.value = true;
    }

    // Handle drag handle visibility
    final shouldShowDragHandle = controller.size <= widget.maxSize * 0.9;
    if (showDragHandle.value != shouldShowDragHandle) {
      showDragHandle.value = shouldShowDragHandle;
    }

    // SafeArea padding management
    final safePadding = MediaQuery.of(context).padding.top;
    final targetPadding = controller.size >= widget.maxSize * 0.99
        ? safePadding
        : 0;
    if (safeAreaPadding.value != targetPadding) {
      safeAreaPadding.value = targetPadding.toDouble();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    showButtons.dispose();
    showDragHandle.dispose();
    safeAreaPadding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // In dark mode: branded blue gradient. In light mode: theme surface.
    final defaultColor1 =
        widget.color1 ??
        (isDark
            ? UseMeTheme.primaryColor
            : Theme.of(context).colorScheme.surface);
    final defaultColor2 =
        widget.color2 ??
        (isDark
            ? UseMeTheme.secondaryColor
            : Theme.of(context).colorScheme.surfaceContainerLow);

    final sheet = DraggableScrollableSheet(
      initialChildSize: widget.initial,
      minChildSize: widget.minSize,
      maxChildSize: widget.maxSize,
      controller: controller,
      builder: (context, scrollController) {
        return _SmoothBackground(
          color1: defaultColor1,
          color2: defaultColor2,
          isDark: isDark,
          child: Stack(
            children: [
              CustomScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildDragHandle()),
                  if (widget.pinnedHeader != null)
                    SliverToBoxAdapter(
                      child: SizedBox(height: widget.pinnedHeaderHeight),
                    ),
                  SliverList(
                    delegate: SliverChildListDelegate([
                      ValueListenableBuilder<double>(
                        valueListenable: safeAreaPadding,
                        builder: (context, padding, child) {
                          return AnimatedPadding(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: EdgeInsets.only(
                              top: padding,
                              bottom: widget.bottomPadding,
                            ),
                            child: widget.bodyContent,
                          );
                        },
                      ),
                    ]),
                  ),
                ],
              ),
              if (widget.pinnedHeader != null)
                Positioned(
                  top: 28,
                  left: 0,
                  right: 0,
                  child: widget.pinnedHeader!,
                ),
              if (widget.floatButtons.isNotEmpty) _buildFloatButtons(),
            ],
          ),
        );
      },
    );

    if (widget.pinnedFooter == null) return sheet;

    // ⚠️ Le footer vit HORS de la feuille draggable, pas dedans : la feuille
    // ne touche jamais le vrai bas d'écran (maxChildSize < 1), donc un footer
    // "pinned" À L'INTÉRIEUR laissait voir le voile de la modale sous lui —
    // un bandeau noir, relevé par Ben le 28/10.
    //
    // ⚠️ Un `Stack` seul ne suffit pas : sans enfant non-positionné de
    // référence, il se contente de la taille de `sheet` — qui ne se résout
    // pas forcément sur la hauteur PLEINE de la modale. Et `SizedBox.expand`
    // s'est révélé tout aussi fragile ici (les contraintes qu'une modale
    // transmet à son contenu ne sont pas garanties bornées) : il a produit
    // un footer posé PLUS BAS que l'écran lui-même en test, pas seulement
    // trop haut. `MediaQuery.sizeOf(context).height` est la référence que
    // `DraggableScrollableSheet` utilise lui-même en interne pour ses
    // fractions — s'y aligner explicitement évite toute divergence entre
    // "la feuille se voit à telle hauteur" et "le footer se pose à telle
    // hauteur". Retrouvé le 28/10 après DEUX correctifs insuffisants.
    final screenHeight = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: screenHeight,
      child: Stack(
        children: [
          sheet,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: widget.pinnedFooter!,
          ),
        ],
      ),
    );
  }

}

