class SuraStats {
  final int suraId;
  final DateTime lastReviewedDate;
  final int totalReviewedTimes;

  SuraStats({
    required this.suraId,
    required this.lastReviewedDate,
    required this.totalReviewedTimes,
  });

  Map<String, dynamic> toMap() {
    return {
      'sura_id': suraId,
      'last_reviewed_date': lastReviewedDate.toIso8601String(),
      'total_reviewed_times': totalReviewedTimes,
    };
  }

  factory SuraStats.fromMap(Map<String, dynamic> map) {
    return SuraStats(
      suraId: map['sura_id'] as int,
      lastReviewedDate: DateTime.parse(map['last_reviewed_date'] as String),
      totalReviewedTimes: map['total_reviewed_times'] as int,
    );
  }
}
