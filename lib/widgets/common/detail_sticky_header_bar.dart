import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Barre compacte (nom + note) posée en [SmoothDraggableWidget.pinnedHeader] —
/// reste visible même feuille repliée, pour qu'on sache toujours de qui on
/// parle sans avoir à ré-ouvrir la feuille en grand.
class DetailStickyHeaderBar extends StatelessWidget {
  final String name;
  final double? rating;

  const DetailStickyHeaderBar({super.key, required this.name, this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (rating != null) ...[
            const SizedBox(width: 8),
            FaIcon(FontAwesomeIcons.solidStar, size: 13, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              rating!.toStringAsFixed(1),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
