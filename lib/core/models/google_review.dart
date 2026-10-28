/// Un avis Google Places — jusqu'à 5 par studio Google (jamais pour un
/// partenaire/pro, dont les photos viennent de Firestore, pas de Google).
class GoogleReview {
  const GoogleReview({
    required this.authorName,
    required this.rating,
    required this.relativeTimeDescription,
    required this.text,
    this.authorPhotoUrl,
  });

  final String authorName;
  final String? authorPhotoUrl;
  final int rating;
  final String relativeTimeDescription;
  final String text;

  factory GoogleReview.fromJson(Map<String, dynamic> json) {
    return GoogleReview(
      authorName: json['author_name']?.toString() ?? '',
      authorPhotoUrl: json['profile_photo_url']?.toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      relativeTimeDescription:
          json['relative_time_description']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
}
