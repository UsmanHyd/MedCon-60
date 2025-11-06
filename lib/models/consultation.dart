import 'package:cloud_firestore/cloud_firestore.dart';

// Consultation status enum
enum ConsultationStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled,
}

// Consultation data model
class Consultation {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialization;
  final String symptoms;
  final String? description;
  final ConsultationStatus status;
  final DateTime requestedAt;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? prescription;
  final String? notes;
  final double? rating;
  final String? review;

  Consultation({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialization,
    required this.symptoms,
    this.description,
    required this.status,
    required this.requestedAt,
    this.scheduledAt,
    this.completedAt,
    this.prescription,
    this.notes,
    this.rating,
    this.review,
  });

  factory Consultation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Consultation(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      doctorSpecialization: data['doctorSpecialization'] ?? '',
      symptoms: data['symptoms'] ?? '',
      description: data['description'],
      status: ConsultationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ConsultationStatus.pending,
      ),
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      scheduledAt: data['scheduledAt'] != null 
          ? (data['scheduledAt'] as Timestamp).toDate() 
          : null,
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      prescription: data['prescription'],
      notes: data['notes'],
      rating: data['rating']?.toDouble(),
      review: data['review'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialization': doctorSpecialization,
      'symptoms': symptoms,
      'description': description,
      'status': status.toString().split('.').last,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'prescription': prescription,
      'notes': notes,
      'rating': rating,
      'review': review,
    };
  }

  Consultation copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialization,
    String? symptoms,
    String? description,
    ConsultationStatus? status,
    DateTime? requestedAt,
    DateTime? scheduledAt,
    DateTime? completedAt,
    String? prescription,
    String? notes,
    double? rating,
    String? review,
  }) {
    return Consultation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialization: doctorSpecialization ?? this.doctorSpecialization,
      symptoms: symptoms ?? this.symptoms,
      description: description ?? this.description,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }
}
