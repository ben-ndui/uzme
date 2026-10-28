// Morceau interne de [SmoothDraggableWidget] — cf. `smooth_draggable_widget.dart`.
part of 'smooth_draggable_widget.dart';

extension _SmoothDraggableWidgetStateBuilders on _SmoothDraggableWidgetState {
  Widget _buildDragHandle() {
    return ValueListenableBuilder<bool>(
      valueListenable: showDragHandle,
      builder: (context, isVisible, child) {
        final handleColor = Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.25);
        return AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatButtons() {
    // Account for bottom safe area (nav bar, gesture bar, etc.)
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;

    return ValueListenableBuilder<bool>(
      valueListenable: showButtons,
      builder: (context, isVisible, child) {
        return Positioned(
          right: 20,
          bottom: widget.floatingBottomPadding + bottomSafeArea,
          child: AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: isVisible
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: widget.floatButtons
                        .map(
                          (btn) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: btn,
                          ),
                        )
                        .toList(),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Background container — gradient in dark mode, surface in light mode
class _SmoothBackground extends StatelessWidget {
  final Widget child;
  final Color color1;
  final Color color2;
  final bool isDark;

  const _SmoothBackground({
    required this.child,
    required this.color1,
    required this.color2,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: child,
    );
  }
}
