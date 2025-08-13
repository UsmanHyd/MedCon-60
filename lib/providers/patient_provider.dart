import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Patient health data model
class PatientHealthData {
  final String id;
  final String patientId;
  final double? weight;
  final double? height;
  final String? bloodType;
  final List<String> allergies;
  final List<String> medications;
  final List<String> conditions;
  final DateTime lastUpdated;

  PatientHealthData({
    required this.id,
    required this.patientId,
    this.weight,
    this.height,
    this.bloodType,
    required this.allergies,
    required this.medications,
    required this.conditions,
    required this.lastUpdated,
  });

  factory PatientHealthData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientHealthData(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      weight: data['weight']?.toDouble(),
      height: data['height']?.toDouble(),
      bloodType: data['bloodType'],
      allergies: List<String>.from(data['allergies'] ?? []),
      medications: List<String>.from(data['medications'] ?? []),
      conditions: List<String>.from(data['conditions'] ?? []),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'weight': weight,
      'height': height,
      'bloodType': bloodType,
      'allergies': allergies,
      'medications': medications,
      'conditions': conditions,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  PatientHealthData copyWith({
    double? weight,
    double? height,
    String? bloodType,
    List<String>? allergies,
    List<String>? medications,
    List<String>? conditions,
  }) {
    return PatientHealthData(
      id: id,
      patientId: patientId,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      conditions: conditions ?? this.conditions,
      lastUpdated: DateTime.now(),
    );
  }
}

// Patient state notifier
class PatientNotifier extends StateNotifier<AsyncValue<PatientHealthData?>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _patientId;

  PatientNotifier(this._patientId) : super(const AsyncValue.loading()) {
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    try {
      state = const AsyncValue.loading();
      
      final doc = await _firestore
          .collection('patientHealth')
          .doc(_patientId)
          .get();
      
      if (doc.exists) {
        final healthData = PatientHealthData.fromFirestore(doc);
        state = AsyncValue.data(healthData);
      } else {
        // Create default health data if none exists
        final defaultData = PatientHealthData(
          id: _patientId,
          patientId: _patientId,
          allergies: [],
          medications: [],
          conditions: [],
          lastUpdated: DateTime.now(),
        );
        
        await _firestore
            .collection('patientHealth')
            .doc(_patientId)
            .set(defaultData.toFirestore());
        
        state = AsyncValue.data(defaultData);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateHealthData(PatientHealthData healthData) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore
          .collection('patientHealth')
          .doc(_patientId)
          .update(healthData.toFirestore());
      
      await _loadHealthData();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addAllergy(String allergy) async {
    try {
      final currentData = state.value;
      if (currentData == null) return;
      
      if (!currentData.allergies.contains(allergy)) {
        final updatedData = currentData.copyWith(
          allergies: [...currentData.allergies, allergy],
        );
        await updateHealthData(updatedData);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeAllergy(String allergy) async {
    try {
      final currentData = state.value;
      if (currentData == null) return;
      
      final updatedData = currentData.copyWith(
        allergies: currentData.allergies.where((a) => a != allergy).toList(),
      );
      await updateHealthData(updatedData);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addMedication(String medication) async {
    try {
      final currentData = state.value;
      if (currentData == null) return;
      
      if (!currentData.medications.contains(medication)) {
        final updatedData = currentData.copyWith(
          medications: [...currentData.medications, medication],
        );
        await updateHealthData(updatedData);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeMedication(String medication) async {
    try {
      final currentData = state.value;
      if (currentData == null) return;
      
      final updatedData = currentData.copyWith(
        medications: currentData.medications.where((m) => m != medication).toList(),
      );
      await updateHealthData(updatedData);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateVitals({double? weight, double? height}) async {
    try {
      final currentData = state.value;
      if (currentData == null) return;
      
      final updatedData = currentData.copyWith(
        weight: weight,
        height: height,
      );
      await updateHealthData(updatedData);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshHealthData() async {
    await _loadHealthData();
  }
}

// Providers
final patientHealthProvider = StateNotifierProvider.family<PatientNotifier, AsyncValue<PatientHealthData?>, String>(
  (ref, patientId) => PatientNotifier(patientId),
);

// Convenience providers
final patientAllergiesProvider = Provider.family<List<String>, String>((ref, patientId) {
  final healthData = ref.watch(patientHealthProvider(patientId));
  return healthData.when(
    data: (data) => data?.allergies ?? [],
    loading: () => [],
    error: (_, __) => [],
  );
});

final patientMedicationsProvider = Provider.family<List<String>, String>((ref, patientId) {
  final healthData = ref.watch(patientHealthProvider(patientId));
  return healthData.when(
    data: (data) => data?.medications ?? [],
    loading: () => [],
    error: (_, __) => [],
  );
});

final patientBMICalculatorProvider = Provider.family<double?, String>((ref, patientId) {
  final healthData = ref.watch(patientHealthProvider(patientId));
  return healthData.when(
    data: (data) {
      if (data?.weight != null && data?.height != null) {
        final heightInMeters = data!.height! / 100;
        return data.weight! / (heightInMeters * heightInMeters);
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
