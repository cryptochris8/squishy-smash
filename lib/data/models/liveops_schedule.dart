class FeaturedWeek {
  const FeaturedWeek({
    required this.weekOf,
    required this.featuredPack,
    required this.eventModifier,
    required this.promoLabel,
  });

  final DateTime weekOf;
  final String featuredPack;
  final String eventModifier;
  final String promoLabel;

  factory FeaturedWeek.fromJson(Map<String, dynamic> json) => FeaturedWeek(
        weekOf: DateTime.parse(json['weekOf'] as String),
        featuredPack: json['featuredPack'] as String,
        eventModifier: json['eventModifier'] as String,
        promoLabel: json['promoLabel'] as String,
      );
}

class LiveOpsSchedule {
  const LiveOpsSchedule({required this.featuredRotation});

  final List<FeaturedWeek> featuredRotation;

  factory LiveOpsSchedule.fromJson(Map<String, dynamic> json) => LiveOpsSchedule(
        featuredRotation: (json['featuredRotation'] as List)
            .cast<Map<String, dynamic>>()
            .map(FeaturedWeek.fromJson)
            .toList(growable: false),
      );

  FeaturedWeek? currentWeek(DateTime now) {
    FeaturedWeek? best;
    for (final week in featuredRotation) {
      if (!week.weekOf.isAfter(now) && (best == null || week.weekOf.isAfter(best.weekOf))) {
        best = week;
      }
    }
    return best;
  }
}
