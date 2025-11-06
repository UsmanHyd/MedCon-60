import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation.dart';

// Consultation state notifier
class ConsultationNotifier extends StateNotifier<AsyncValue<List<Consultation>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId;
  final String? _userRole;

  ConsultationNotifier({String? userId, String? userRole}) 
      : _userId = userId, 
        _userRole = userRole,
        super(const AsyncValue.loading()) {
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    try {
      state = const AsyncValue.loading();
      
      Query query;
      if (_userRole == 'doctor') {
        query = _firestore
            .collection('consultations')
            .where('doctorId', isEqualTo: _userId)
            .orderBy('requestedAt', descending: true);
      } else {
        query = _firestore
            .collection('consultations')
            .where('patientId', isEqualTo: _userId)
            .orderBy('requestedAt', descending: true);
      }

      final snapshot = await query.get();
      final consultations = snapshot.docs
          .map((doc) => Consultation.fromFirestore(doc))
          .toList();
      
      state = AsyncValue.data(consultations);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createConsultation({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialization,
    required String symptoms,
    String? description,
  }) async {
    try {
      final consultation = Consultation(
        id: '', // Will be set by Firestore
        patientId: patientId,
        patientName: patientName,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorSpecialization: doctorSpecialization,
        symptoms: symptoms,
        description: description,
        status: ConsultationStatus.pending,
        requestedAt: DateTime.now(),
      );

      await _firestore
          .collection('consultations')
          .add(consultation.toFirestore());
      
      await _loadConsultations();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateConsultationStatus(String consultationId, ConsultationStatus status) async {
    try {
      await _firestore
          .collection('consultations')
          .doc(consultationId)
          .update({
        'status': status.toString().split('.').last,
        if (status == ConsultationStatus.completed) 
          'completedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      await _loadConsultations();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addPrescription(String consultationId, String prescription, String notes) async {
    try {
      await _firestore
          .collection('consultations')
          .doc(consultationId)
          .update({
        'prescription': prescription,
        'notes': notes,
        'status': ConsultationStatus.completed.toString().split('.').last,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      await _loadConsultations();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshConsultations() async {
    await _loadConsultations();
  }
}

// Providers
final consultationProvider = StateNotifierProvider.family<ConsultationNotifier, AsyncValue<List<Consultation>>, Map<String, String>>(
  (ref, params) => ConsultationNotifier(
    userId: params['userId'],
    userRole: params['userRole'],
  ),
);

// Convenience providers
final pendingConsultationsProvider = Provider.family<List<Consultation>, Map<String, String>>((ref, params) {
  final consultations = ref.watch(consultationProvider(params));
  return consultations.when(
    data: (consultations) => consultations
        .where((c) => c.status == ConsultationStatus.pending)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final acceptedConsultationsProvider = Provider.family<List<Consultation>, Map<String, String>>((ref, params) {
  final consultations = ref.watch(consultationProvider(params));
  return consultations.when(
    data: (consultations) => consultations
        .where((c) => c.status == ConsultationStatus.accepted)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final completedConsultationsProvider = Provider.family<List<Consultation>, Map<String, String>>((ref, params) {
  final consultations = ref.watch(consultationProvider(params));
  return consultations.when(
    data: (consultations) => consultations
        .where((c) => c.status == ConsultationStatus.completed)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final consultationStatsProvider = Provider.family<Map<String, int>, Map<String, String>>((ref, params) {
  final consultations = ref.watch(consultationProvider(params));
  return consultations.when(
    data: (consultations) {
      final stats = <String, int>{};
      for (final status in ConsultationStatus.values) {
        stats[status.toString().split('.').last] = consultations
            .where((c) => c.status == status)
            .length;
      }
      return stats;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

final upcomingConsultationsProvider = Provider.family<List<Consultation>, Map<String, String>>((ref, params) {
  final consultations = ref.watch(consultationProvider(params));
  return consultations.when(
    data: (consultations) => consultations
        .where((c) => c.status == ConsultationStatus.accepted && 
                      c.scheduledAt != null &&
                      c.scheduledAt!.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!)),
    loading: () => [],
    error: (_, __) => [],
  );
});
