import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Disease prediction model
class DiseasePrediction {
  final String disease;
  final double confidence;
  final List<String> symptoms;
  final String description;
  final List<String> recommendations;

  DiseasePrediction({
    required this.disease,
    required this.confidence,
    required this.symptoms,
    required this.description,
    required this.recommendations,
  });
}

// Multiple disease predictions model
class DiseasePredictions {
  final List<DiseasePrediction> predictions;
  final List<String> symptoms;

  DiseasePredictions({
    required this.predictions,
    required this.symptoms,
  });
}

// Symptom data model
class Symptom {
  final String name;
  final String category;
  final bool isSelected;

  Symptom({
    required this.name,
    required this.category,
    this.isSelected = false,
  });

  Symptom copyWith({bool? isSelected}) {
    return Symptom(
      name: name,
      category: category,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

// Disease state notifier
class DiseaseNotifier extends StateNotifier<AsyncValue<DiseasePredictions?>> {
  DiseasePredictions? _lastPredictions;

  DiseaseNotifier() : super(const AsyncValue.data(null));

  Future<void> predictDisease(List<String> symptoms) async {
    if (symptoms.isEmpty) {
      state = AsyncValue.error('No symptoms selected', StackTrace.current);
      return;
    }

    try {
      state = const AsyncValue.loading();

      // Call the real ML model API
      final response = await http.post(
        Uri.parse('http://192.168.0.107:8000/predict'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'symptoms': symptoms,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = data['predictions'] as List;

        if (predictions.isNotEmpty) {
          // Convert all predictions and calculate confidence based on symptom matching
          final List<DiseasePrediction> diseasePredictions =
              predictions.map((prediction) {
            // Calculate confidence based on symptom matching
            final List<dynamic> matchedSymptoms =
                prediction['matched_symptoms'] ?? [];
            final List<dynamic> totalSymptoms =
                prediction['total_symptoms'] ?? [];

            double confidence;
            if (totalSymptoms.isNotEmpty) {
              // If we have total symptoms info, calculate based on matching
              confidence = matchedSymptoms.length / totalSymptoms.length;
            } else {
              // Fallback to ML model confidence if no total symptoms info
              confidence = (prediction['confidence'] ?? 0.0) / 100.0;
            }

            return DiseasePrediction(
              disease: prediction['disease'] ?? 'Unknown Disease',
              confidence: confidence,
              symptoms: symptoms,
              description: _formatDescription(
                matchedSymptoms,
                prediction['treatments'] ?? [],
              ),
              recommendations:
                  List<String>.from(prediction['treatments'] ?? []),
            );
          }).toList();

          // Sort by confidence (highest first) and take top 5
          diseasePredictions
              .sort((a, b) => b.confidence.compareTo(a.confidence));
          final top5Predictions = diseasePredictions.take(5).toList();

          final diseasePredictionsResult = DiseasePredictions(
            predictions: top5Predictions,
            symptoms: symptoms,
          );

          _lastPredictions = diseasePredictionsResult;
          state = AsyncValue.data(diseasePredictionsResult);
        } else {
          state = AsyncValue.error(
              'No predictions returned from ML model', StackTrace.current);
        }
      } else {
        state = AsyncValue.error(
            'Failed to get prediction: ${response.statusCode}',
            StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  String _formatDescription(
      List<dynamic> matchedSymptoms, List<dynamic> treatments) {
    String desc = '';
    if (matchedSymptoms.isNotEmpty) {
      desc += 'Matched symptoms: ${matchedSymptoms.join(', ')}. ';
    }
    if (treatments.isNotEmpty) {
      desc += 'Recommendations: ${treatments.join(', ')}.';
    }
    if (desc.isEmpty) {
      desc = 'Please consult a healthcare professional for accurate diagnosis.';
    }
    return desc;
  }

  Future<void> savePrediction() async {
    // Save prediction to local storage or database
    // This could be useful for tracking health history
  }
}

// Symptoms state notifier
class SymptomsNotifier extends StateNotifier<List<String>> {
  SymptomsNotifier() : super([]);

  void toggleSymptom(String symptom) {
    if (state.contains(symptom)) {
      state = state.where((s) => s != symptom).toList();
    } else {
      state = [...state, symptom];
    }
  }

  void clearSymptoms() {
    state = [];
  }

  void addCustomSymptom(String symptom) {
    if (!state.contains(symptom)) {
      state = [...state, symptom];
    }
  }
}

// Providers
final diseaseProvider =
    StateNotifierProvider<DiseaseNotifier, AsyncValue<DiseasePredictions?>>(
  (ref) => DiseaseNotifier(),
);

final symptomsProvider = StateNotifierProvider<SymptomsNotifier, List<String>>(
  (ref) => SymptomsNotifier(),
);

final selectedSymptomsProvider = Provider<List<String>>((ref) {
  return ref.watch(symptomsProvider);
});

// Predefined symptoms for UI
final availableSymptomsProvider = Provider<List<Symptom>>((ref) {
  return [
    Symptom(name: 'Fever', category: 'General'),
    Symptom(name: 'Headache', category: 'Neurological'),
    Symptom(name: 'Cough', category: 'Respiratory'),
    Symptom(name: 'Fatigue', category: 'General'),
    Symptom(name: 'Nausea', category: 'Digestive'),
    Symptom(name: 'Dizziness', category: 'Neurological'),
    Symptom(name: 'Chest Pain', category: 'Cardiovascular'),
    Symptom(name: 'Shortness of Breath', category: 'Respiratory'),
    Symptom(name: 'Abdominal Pain', category: 'Digestive'),
    Symptom(name: 'Joint Pain', category: 'Musculoskeletal'),
    Symptom(name: 'Rash', category: 'Dermatological'),
    Symptom(name: 'Swelling', category: 'General'),
    Symptom(name: 'Loss of Appetite', category: 'General'),
    Symptom(name: 'Insomnia', category: 'Sleep'),
    Symptom(name: 'Anxiety', category: 'Mental Health'),
  ];
});

final symptomsByCategoryProvider = Provider<Map<String, List<Symptom>>>((ref) {
  final symptoms = ref.watch(availableSymptomsProvider);
  final grouped = <String, List<Symptom>>{};

  for (final symptom in symptoms) {
    grouped.putIfAbsent(symptom.category, () => []).add(symptom);
  }

  return grouped;
});
