import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/google_review.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/detail_sheet_ink.dart';

/// Jusqu'à 5 avis Google — section absente pour un partenaire/pro (dont les
/// données ne viennent pas de Google), ou tant que l'appel Details n'a pas
/// encore répondu.
class StudioDetailReviews extends StatelessWidget {
  final List<GoogleReview> reviews;

  const StudioDetailReviews({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ink = DetailSheetInk(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.googleReviews,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            l10n.googleReviewsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: ink.mutedInk),
          ),
          const SizedBox(height: 10),
          for (final review in reviews) _ReviewTile(review: review, ink: ink),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final GoogleReview review;
  final DetailSheetInk ink;

  const _ReviewTile({required this.review, required this.ink});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: ink.chipBackground,
                backgroundImage: review.authorPhotoUrl != null
                    ? NetworkImage(review.authorPhotoUrl!)
                    : null,
                onBackgroundImageError: review.authorPhotoUrl != null
                    ? (_, _) {}
                    : null,
                child: review.authorPhotoUrl == null
                    ? Text(
                        review.authorName.isNotEmpty
                            ? review.authorName[0].toUpperCase()
                            : '?',
                        style: TextStyle(color: ink.accentInk),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => FaIcon(
                            i < review.rating
                                ? FontAwesomeIcons.solidStar
                                : FontAwesomeIcons.star,
                            size: 10,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          review.relativeTimeDescription,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ink.mutedInk,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
