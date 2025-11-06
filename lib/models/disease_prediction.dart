import 'package:cloud_firestore/cloud_firestore.dart';

// Symptom category enum
enum SymptomCategory {
  general,
  cardiovascular,
  respiratory,
  gastrointestinal,
  neurological,
  musculoskeletal,
  dermatological,
  endocrine,
  genitourinary,
  psychological,
  other,
}

// Symptom severity enum
enum SymptomSeverity {
  mild,
  moderate,
  severe,
  critical,
}

// Symptom data model
class Symptom {
  final String id;
  final String name;
  final String description;
  final SymptomCategory category;
  final SymptomSeverity severity;
  final List<String> relatedSymptoms;
  final List<String> possibleDiseases;
  final bool isSelected;

  Symptom({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.severity,
    required this.relatedSymptoms,
    required this.possibleDiseases,
    this.isSelected = false,
  });

  factory Symptom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Symptom(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: SymptomCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => SymptomCategory.general,
      ),
      severity: SymptomSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == data['severity'],
        orElse: () => SymptomSeverity.mild,
      ),
      relatedSymptoms: List<String>.from(data['relatedSymptoms'] ?? []),
      possibleDiseases: List<String>.from(data['possibleDiseases'] ?? []),
      isSelected: data['isSelected'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'relatedSymptoms': relatedSymptoms,
      'possibleDiseases': possibleDiseases,
      'isSelected': isSelected,
    };
  }

  Symptom copyWith({
    String? id,
    String? name,
    String? description,
    SymptomCategory? category,
    SymptomSeverity? severity,
    List<String>? relatedSymptoms,
    List<String>? possibleDiseases,
    bool? isSelected,
  }) {
    return Symptom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      relatedSymptoms: relatedSymptoms ?? this.relatedSymptoms,
      possibleDiseases: possibleDiseases ?? this.possibleDiseases,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  // Helper methods
  String get categoryDisplay => category.toString().split('.').last;
  String get severityDisplay => severity.toString().split('.').last;
  bool get isHighSeverity => severity == SymptomSeverity.severe || severity == SymptomSeverity.critical;
}

// Disease prediction result model
class DiseasePrediction {
  final String id;
  final String patientId;
  final List<String> selectedSymptoms;
  final Map<String, double> diseaseProbabilities;
  final String primaryDisease;
  final double primaryDiseaseConfidence;
  final List<String> recommendedTests;
  final List<String> recommendedSpecialists;
  final String? notes;
  final DateTime predictedAt;
  final bool isSaved;

  DiseasePrediction({
    required this.id,
    required this.patientId,
    required this.selectedSymptoms,
    required this.diseaseProbabilities,
    required this.primaryDisease,
    required this.primaryDiseaseConfidence,
    required this.recommendedTests,
    required this.recommendedSpecialists,
    this.notes,
    required this.predictedAt,
    required this.isSaved,
  });

  factory DiseasePrediction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiseasePrediction(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      selectedSymptoms: List<String>.from(data['selectedSymptoms'] ?? []),
      diseaseProbabilities: Map<String, double>.from(data['diseaseProbabilities'] ?? {}),
      primaryDisease: data['primaryDisease'] ?? '',
      primaryDiseaseConfidence: (data['primaryDiseaseConfidence'] ?? 0.0).toDouble(),
      recommendedTests: List<String>.from(data['recommendedTests'] ?? []),
      recommendedSpecialists: List<String>.from(data['recommendedSpecialists'] ?? []),
      notes: data['notes'],
      predictedAt: (data['predictedAt'] as Timestamp).toDate(),
      isSaved: data['isSaved'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'selectedSymptoms': selectedSymptoms,
      'diseaseProbabilities': diseaseProbabilities,
      'primaryDisease': primaryDisease,
      'primaryDiseaseConfidence': primaryDiseaseConfidence,
      'recommendedTests': recommendedTests,
      'recommendedSpecialists': recommendedSpecialists,
      'notes': notes,
      'predictedAt': Timestamp.fromDate(predictedAt),
      'isSaved': isSaved,
    };
  }

  DiseasePrediction copyWith({
    String? id,
    String? patientId,
    List<String>? selectedSymptoms,
    Map<String, double>? diseaseProbabilities,
    String? primaryDisease,
    double? primaryDiseaseConfidence,
    List<String>? recommendedTests,
    List<String>? recommendedSpecialists,
    String? notes,
    DateTime? predictedAt,
    bool? isSaved,
  }) {
    return DiseasePrediction(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      selectedSymptoms: selectedSymptoms ?? this.selectedSymptoms,
      diseaseProbabilities: diseaseProbabilities ?? this.diseaseProbabilities,
      primaryDisease: primaryDisease ?? this.primaryDisease,
      primaryDiseaseConfidence: primaryDiseaseConfidence ?? this.primaryDiseaseConfidence,
      recommendedTests: recommendedTests ?? this.recommendedTests,
      recommendedSpecialists: recommendedSpecialists ?? this.recommendedSpecialists,
      notes: notes ?? this.notes,
      predictedAt: predictedAt ?? this.predictedAt,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  // Helper methods
  String get confidenceDisplay => '${(primaryDiseaseConfidence * 100).toStringAsFixed(1)}%';
  bool get isHighConfidence => primaryDiseaseConfidence >= 0.7;
  bool get isMediumConfidence => primaryDiseaseConfidence >= 0.4 && primaryDiseaseConfidence < 0.7;
  bool get isLowConfidence => primaryDiseaseConfidence < 0.4;
  
  List<String> get topDiseases {
    final sorted = diseaseProbabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }
  
  String get riskLevel {
    if (primaryDiseaseConfidence >= 0.8) return 'High Risk';
    if (primaryDiseaseConfidence >= 0.6) return 'Medium Risk';
    if (primaryDiseaseConfidence >= 0.4) return 'Low Risk';
    return 'Very Low Risk';
  }
}
