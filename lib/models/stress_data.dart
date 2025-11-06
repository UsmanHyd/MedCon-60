import 'package:cloud_firestore/cloud_firestore.dart';

// Stress level enum
enum StressLevel {
  veryLow,
  low,
  moderate,
  high,
  veryHigh,
  critical,
}

// Stress symptom category
enum StressSymptomCategory {
  physical,
  emotional,
  cognitive,
  behavioral,
  social,
}

// Stress data model
class StressData {
  final String id;
  final String patientId;
  final StressLevel level;
  final int score; // 1-10 scale
  final List<String> symptoms;
  final String? notes;
  final String? trigger;
  final String? copingStrategy;
  final DateTime recordedAt;
  final Map<String, dynamic>? additionalData;

  StressData({
    required this.id,
    required this.patientId,
    required this.level,
    required this.score,
    required this.symptoms,
    this.notes,
    this.trigger,
    this.copingStrategy,
    required this.recordedAt,
    this.additionalData,
  });

  factory StressData.create({
    required String patientId,
    required int score,
    required List<String> symptoms,
    String? notes,
    String? trigger,
    String? copingStrategy,
    Map<String, dynamic>? additionalData,
  }) {
    final level = _getStressLevelFromScore(score);
    return StressData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: patientId,
      level: level,
      score: score,
      symptoms: symptoms,
      notes: notes,
      trigger: trigger,
      copingStrategy: copingStrategy,
      recordedAt: DateTime.now(),
      additionalData: additionalData,
    );
  }

  factory StressData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StressData(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      level: StressLevel.values.firstWhere(
        (e) => e.toString().split('.').last == data['level'],
        orElse: () => StressLevel.moderate,
      ),
      score: data['score'] ?? 5,
      symptoms: List<String>.from(data['symptoms'] ?? []),
      notes: data['notes'],
      trigger: data['trigger'],
      copingStrategy: data['copingStrategy'],
      recordedAt: (data['recordedAt'] as Timestamp).toDate(),
      additionalData: data['additionalData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'level': level.toString().split('.').last,
      'score': score,
      'symptoms': symptoms,
      'notes': notes,
      'trigger': trigger,
      'copingStrategy': copingStrategy,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'additionalData': additionalData,
    };
  }

  StressData copyWith({
    String? id,
    String? patientId,
    StressLevel? level,
    int? score,
    List<String>? symptoms,
    String? notes,
    String? trigger,
    String? copingStrategy,
    DateTime? recordedAt,
    Map<String, dynamic>? additionalData,
  }) {
    return StressData(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      level: level ?? this.level,
      score: score ?? this.score,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      trigger: trigger ?? this.trigger,
      copingStrategy: copingStrategy ?? this.copingStrategy,
      recordedAt: recordedAt ?? this.recordedAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Helper methods
  static StressLevel _getStressLevelFromScore(int score) {
    if (score <= 2) return StressLevel.veryLow;
    if (score <= 4) return StressLevel.low;
    if (score <= 6) return StressLevel.moderate;
    if (score <= 8) return StressLevel.high;
    if (score <= 9) return StressLevel.veryHigh;
    return StressLevel.critical;
  }

  String get levelDisplay => level.toString().split('.').last;
  String get scoreDisplay => '$score/10';
  bool get isHighStress => level == StressLevel.high || level == StressLevel.veryHigh || level == StressLevel.critical;
  bool get isLowStress => level == StressLevel.veryLow || level == StressLevel.low;
  bool get isModerateStress => level == StressLevel.moderate;
  
  String get levelDescription {
    switch (level) {
      case StressLevel.veryLow:
        return 'Very Low Stress';
      case StressLevel.low:
        return 'Low Stress';
      case StressLevel.moderate:
        return 'Moderate Stress';
      case StressLevel.high:
        return 'High Stress';
      case StressLevel.veryHigh:
        return 'Very High Stress';
      case StressLevel.critical:
        return 'Critical Stress Level';
    }
  }
  
  String get recommendation {
    if (isLowStress) return 'Maintain your current stress management practices.';
    if (isModerateStress) return 'Consider stress reduction techniques like meditation or exercise.';
    if (isHighStress) return 'Focus on stress management and consider professional help if needed.';
    return 'Seek immediate professional help for stress management.';
  }
}

// Stress insights model
class StressInsights {
  final double averageScore;
  final StressLevel averageLevel;
  final List<String> commonSymptoms;
  final List<String> commonTriggers;
  final List<String> effectiveCopingStrategies;
  final Map<String, int> symptomFrequency;
  final Map<String, int> triggerFrequency;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalEntries;

  StressInsights({
    required this.averageScore,
    required this.averageLevel,
    required this.commonSymptoms,
    required this.commonTriggers,
    required this.effectiveCopingStrategies,
    required this.symptomFrequency,
    required this.triggerFrequency,
    required this.periodStart,
    required this.periodEnd,
    required this.totalEntries,
  });

  // Helper methods
  String get averageScoreDisplay => averageScore.toStringAsFixed(1);
  String get periodDisplay => '${periodStart.day}/${periodStart.month} - ${periodEnd.day}/${periodEnd.month}';
  bool get hasTrend => totalEntries > 1;
  
  String get overallAssessment {
    if (averageScore <= 3) return 'Excellent stress management';
    if (averageScore <= 5) return 'Good stress management';
    if (averageScore <= 7) return 'Moderate stress levels';
    if (averageScore <= 9) return 'High stress levels';
    return 'Critical stress levels - seek help';
  }
  
  List<String> get topSymptoms => commonSymptoms.take(3).toList();
  List<String> get topTriggers => commonTriggers.take(3).toList();
  List<String> get topCopingStrategies => effectiveCopingStrategies.take(3).toList();
}

// Stress trend data
class StressTrend {
  final List<DateTime> dates;
  final List<double> scores;
  final List<StressLevel> levels;
  final double trendSlope; // Positive = increasing stress, Negative = decreasing stress

  StressTrend({
    required this.dates,
    required this.scores,
    required this.levels,
    required this.trendSlope,
  });

  // Helper methods
  bool get isImproving => trendSlope < -0.1;
  bool get isWorsening => trendSlope > 0.1;
  bool get isStable => trendSlope.abs() <= 0.1;
  
  String get trendDescription {
    if (isImproving) return 'Stress levels are improving';
    if (isWorsening) return 'Stress levels are increasing';
    return 'Stress levels are stable';
  }
  
  double get changeRate => (trendSlope * 100).abs();
  String get changeRateDisplay => '${changeRate.toStringAsFixed(1)}% per day';
}
