import 'package:equatable/equatable.dart';

/// One feature recap in the AI-generated "what's new for me" summary.
class WhatsNewItem extends Equatable {
  final String flagKey;
  final String title;
  final String summary;
  final String action;
  final bool alreadySeen;

  const WhatsNewItem({
    required this.flagKey,
    required this.title,
    required this.summary,
    required this.action,
    required this.alreadySeen,
  });

  factory WhatsNewItem.fromMap(Map<String, dynamic> map) {
    return WhatsNewItem(
      flagKey: (map['flagKey'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      summary: (map['summary'] ?? '').toString(),
      action: (map['action'] ?? '').toString(),
      alreadySeen: map['alreadySeen'] == true,
    );
  }

  @override
  List<Object?> get props => [flagKey, title, summary, action, alreadySeen];
}

/// Whole AI summary returned by `getWhatsNewForMe`.
class WhatsNewSummary extends Equatable {
  final String intro;
  final List<WhatsNewItem> items;
  final bool empty;

  const WhatsNewSummary({
    required this.intro,
    required this.items,
    required this.empty,
  });

  factory WhatsNewSummary.fromMap(Map<String, dynamic> map) {
    final rawItems = (map['items'] as List? ?? const []).whereType<Map>();
    return WhatsNewSummary(
      intro: (map['intro'] ?? '').toString(),
      items: rawItems
          .map((m) => WhatsNewItem.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      empty: map['empty'] == true,
    );
  }

  @override
  List<Object?> get props => [intro, items, empty];
}
