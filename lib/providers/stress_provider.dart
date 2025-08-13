import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stress level enum
enum StressLevel {
  low,
  moderate,
  high,
  severe,
}

// Stress data model
class StressData {
  final String id;
  final DateTime timestamp;
  final StressLevel level;
  final int score; // 1-10 scale
  final List<String> symptoms;
  final String? notes;
  final Map<String, dynamic>? additionalData;

  StressData({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.score,
    required this.symptoms,
    this.notes,
    this.additionalData,
  });

  factory StressData.create({
    required int score,
    required List<String> symptoms,
    String? notes,
  }) {
    StressLevel level;
    if (score <= 3) {
      level = StressLevel.low;
    } else if (score <= 6) {
      level = StressLevel.moderate;
    } else if (score <= 8) {
      level = StressLevel.high;
    } else {
      level = StressLevel.severe;
    }

    return StressData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: level,
      score: score,
      symptoms: symptoms,
      notes: notes,
    );
  }
}

// Stress insights model
class StressInsights {
  final double averageScore;
  final StressLevel overallLevel;
  final List<String> commonSymptoms;
  final String recommendation;
  final int totalEntries;
  final DateTime lastEntry;

  StressInsights({
    required this.averageScore,
    required this.overallLevel,
    required this.commonSymptoms,
    required this.recommendation,
    required this.totalEntries,
    required this.lastEntry,
  });
}

// Stress state notifier
class StressNotifier extends StateNotifier<AsyncValue<List<StressData>>> {
  List<StressData> _stressEntries = [];

  StressNotifier() : super(const AsyncValue.data([]));

  List<StressData> get stressEntries => List.unmodifiable(_stressEntries);

  void addStressEntry(StressData entry) {
    _stressEntries.add(entry);
    _stressEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = AsyncValue.data(_stressEntries);
  }

  void removeStressEntry(String id) {
    _stressEntries.removeWhere((entry) => entry.id == id);
    state = AsyncValue.data(_stressEntries);
  }

  void clearAllEntries() {
    _stressEntries.clear();
    state = const AsyncValue.data([]);
  }

  StressInsights getInsights() {
    if (_stressEntries.isEmpty) {
      return StressInsights(
        averageScore: 0,
        overallLevel: StressLevel.low,
        commonSymptoms: [],
        recommendation: 'No stress data available. Start tracking your stress levels.',
        totalEntries: 0,
        lastEntry: DateTime.now(),
      );
    }

    // Calculate average score
    final totalScore = _stressEntries.fold<int>(0, (sum, entry) => sum + entry.score);
    final averageScore = totalScore / _stressEntries.length;

    // Determine overall level
    StressLevel overallLevel;
    if (averageScore <= 3) {
      overallLevel = StressLevel.low;
    } else if (averageScore <= 6) {
      overallLevel = StressLevel.moderate;
    } else if (averageScore <= 8) {
      overallLevel = StressLevel.high;
    } else {
      overallLevel = StressLevel.severe;
    }

    // Find common symptoms
    final symptomCount = <String, int>{};
    for (final entry in _stressEntries) {
      for (final symptom in entry.symptoms) {
        symptomCount[symptom] = (symptomCount[symptom] ?? 0) + 1;
      }
    }
    
    final sortedSymptoms = symptomCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final commonSymptoms = sortedSymptoms.take(3).map((e) => e.key).toList();

    // Generate recommendation
    String recommendation;
    switch (overallLevel) {
      case StressLevel.low:
        recommendation = 'Great job managing stress! Keep up the healthy habits.';
        break;
      case StressLevel.moderate:
        recommendation = 'Consider stress management techniques like meditation or exercise.';
        break;
      case StressLevel.high:
        recommendation = 'High stress detected. Try deep breathing, take breaks, and consider professional help.';
        break;
      case StressLevel.severe:
        recommendation = 'Severe stress levels. Please consult a healthcare professional immediately.';
        break;
    }

    return StressInsights(
      averageScore: averageScore,
      overallLevel: overallLevel,
      commonSymptoms: commonSymptoms,
      recommendation: recommendation,
      totalEntries: _stressEntries.length,
      lastEntry: _stressEntries.first.timestamp,
    );
  }

  List<StressData> getEntriesForPeriod(DateTime start, DateTime end) {
    return _stressEntries
        .where((entry) => entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end))
        .toList();
  }

  List<StressData> getRecentEntries(int count) {
    return _stressEntries.take(count).toList();
  }

  double getTrend() {
    if (_stressEntries.length < 2) return 0;
    
    final recent = _stressEntries.take(7).toList();
    if (recent.length < 2) return 0;
    
    final firstHalf = recent.take(recent.length ~/ 2);
    final secondHalf = recent.skip(recent.length ~/ 2);
    
    final firstAvg = firstHalf.fold<int>(0, (sum, entry) => sum + entry.score) / firstHalf.length;
    final secondAvg = secondHalf.fold<int>(0, (sum, entry) => sum + entry.score) / secondHalf.length;
    
    return secondAvg - firstAvg; // Positive means increasing stress
  }
}

// Providers
final stressProvider = StateNotifierProvider<StressNotifier, AsyncValue<List<StressData>>>(
  (ref) => StressNotifier(),
);

final stressInsightsProvider = Provider<StressInsights>((ref) {
  final stressNotifier = ref.watch(stressProvider.notifier);
  return stressNotifier.getInsights();
});

final stressTrendProvider = Provider<double>((ref) {
  final stressNotifier = ref.watch(stressProvider.notifier);
  return stressNotifier.getTrend();
});

final recentStressEntriesProvider = Provider<List<StressData>>((ref) {
  final stressNotifier = ref.watch(stressProvider.notifier);
  return stressNotifier.getRecentEntries(5);
});

// Predefined stress symptoms for UI
final availableStressSymptomsProvider = Provider<List<String>>((ref) {
  return [
    'Headache',
    'Muscle tension',
    'Fatigue',
    'Irritability',
    'Difficulty concentrating',
    'Sleep problems',
    'Digestive issues',
    'Rapid heartbeat',
    'Sweating',
    'Feeling overwhelmed',
    'Mood swings',
    'Loss of appetite',
    'Social withdrawal',
    'Procrastination',
    'Nervous habits',
  ];
});
