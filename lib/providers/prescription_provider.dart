import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Recently prescribed medication model
class RecentlyPrescribedMedication {
  final String id;
  final String name;
  final String? dose;
  final String? description;
  final String? quantity;
  final String? refills;
  final DateTime prescribedAt;
  final String doctorName;
  final String consultationId;

  RecentlyPrescribedMedication({
    required this.id,
    required this.name,
    this.dose,
    this.description,
    this.quantity,
    this.refills,
    required this.prescribedAt,
    required this.doctorName,
    required this.consultationId,
  });

  factory RecentlyPrescribedMedication.fromPrescriptionString({
    required String prescription,
    required DateTime prescribedAt,
    required String doctorName,
    required String consultationId,
  }) {
    // Parse prescription string to extract medication details
    // This is a simple parser - you might need to adjust based on your prescription format
    final lines = prescription
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    String name = '';
    String? dose;
    String? description;
    String? quantity;
    String? refills;

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty) {
        // Try to extract medication name (usually the first non-empty line)
        if (name.isEmpty) {
          name = trimmedLine;
        }
        // Look for dose information
        if (trimmedLine.toLowerCase().contains('mg') ||
            trimmedLine.toLowerCase().contains('tablet') ||
            trimmedLine.toLowerCase().contains('capsule')) {
          dose = trimmedLine;
        }
        // Look for quantity information
        if (trimmedLine.toLowerCase().contains('qty') ||
            trimmedLine.toLowerCase().contains('quantity')) {
          quantity = trimmedLine;
        }
        // Look for refills information
        if (trimmedLine.toLowerCase().contains('refill')) {
          refills = trimmedLine;
        }
        // Use longer lines as description
        if (trimmedLine.length > 20 && description == null) {
          description = trimmedLine;
        }
      }
    }

    return RecentlyPrescribedMedication(
      id: consultationId,
      name: name.isNotEmpty ? name : 'Unknown Medication',
      dose: dose,
      description: description,
      quantity: quantity,
      refills: refills,
      prescribedAt: prescribedAt,
      doctorName: doctorName,
      consultationId: consultationId,
    );
  }
}

// Prescription state notifier
class PrescriptionNotifier
    extends StateNotifier<AsyncValue<List<RecentlyPrescribedMedication>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _patientId;

  PrescriptionNotifier(this._patientId) : super(const AsyncValue.loading()) {
    _loadRecentlyPrescribed();
  }

  Future<void> _loadRecentlyPrescribed() async {
    try {
      state = const AsyncValue.loading();

      // Get completed consultations for this patient
      final snapshot = await _firestore
          .collection('consultations')
          .where('patientId', isEqualTo: _patientId)
          .where('status', isEqualTo: 'completed')
          .where('prescription', isNotEqualTo: null)
          .orderBy('prescription')
          .orderBy('completedAt', descending: true)
          .limit(20) // Limit to last 20 prescriptions
          .get();

      final medications = <RecentlyPrescribedMedication>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final prescription = data['prescription'] as String?;
        final completedAt = data['completedAt'] as Timestamp?;
        final doctorName = data['doctorName'] as String?;

        if (prescription != null &&
            prescription.isNotEmpty &&
            completedAt != null &&
            doctorName != null) {
          final medication =
              RecentlyPrescribedMedication.fromPrescriptionString(
            prescription: prescription,
            prescribedAt: completedAt.toDate(),
            doctorName: doctorName,
            consultationId: doc.id,
          );

          medications.add(medication);
        }
      }

      state = AsyncValue.data(medications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshRecentlyPrescribed() async {
    await _loadRecentlyPrescribed();
  }
}

// Providers
final prescriptionProvider = StateNotifierProvider.family<PrescriptionNotifier,
    AsyncValue<List<RecentlyPrescribedMedication>>, String>(
  (ref, patientId) => PrescriptionNotifier(patientId),
);

// Convenience providers
final recentlyPrescribedMedicationsProvider =
    Provider.family<List<RecentlyPrescribedMedication>, String>(
        (ref, patientId) {
  final prescriptions = ref.watch(prescriptionProvider(patientId));
  return prescriptions.when(
    data: (medications) => medications,
    loading: () => [],
    error: (_, __) => [],
  );
});

final recentlyPrescribedNamesProvider =
    Provider.family<List<String>, String>((ref, patientId) {
  final medications =
      ref.watch(recentlyPrescribedMedicationsProvider(patientId));
  return medications.map((med) => med.name).toList();
});
