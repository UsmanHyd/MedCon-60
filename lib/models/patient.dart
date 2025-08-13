import 'package:cloud_firestore/cloud_firestore.dart';

// Blood type enum
enum BloodType {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
}

// Gender enum
enum Gender {
  male,
  female,
  other,
  preferNotToSay,
}

// Patient data model
class Patient {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final Gender gender;
  final BloodType bloodType;
  final String? profileImage;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? address;
  final String? medicalHistory;
  final List<String> allergies;
  final List<String> medications;
  final List<String> conditions;
  final Map<String, dynamic>? vitals;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastActive;

  Patient({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.bloodType,
    this.profileImage,
    this.emergencyContact,
    this.emergencyPhone,
    this.address,
    this.medicalHistory,
    required this.allergies,
    required this.medications,
    required this.conditions,
    this.vitals,
    required this.isActive,
    required this.createdAt,
    required this.lastActive,
  });

  factory Patient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Patient(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      gender: Gender.values.firstWhere(
        (e) => e.toString().split('.').last == data['gender'],
        orElse: () => Gender.preferNotToSay,
      ),
      bloodType: BloodType.values.firstWhere(
        (e) => e.toString().split('.').last == data['bloodType'],
        orElse: () => BloodType.oPositive,
      ),
      profileImage: data['profileImage'],
      emergencyContact: data['emergencyContact'],
      emergencyPhone: data['emergencyPhone'],
      address: data['address'],
      medicalHistory: data['medicalHistory'],
      allergies: List<String>.from(data['allergies'] ?? []),
      medications: List<String>.from(data['medications'] ?? []),
      conditions: List<String>.from(data['conditions'] ?? []),
      vitals: data['vitals'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender.toString().split('.').last,
      'bloodType': bloodType.toString().split('.').last,
      'profileImage': profileImage,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'address': address,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'medications': medications,
      'conditions': conditions,
      'vitals': vitals,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  Patient copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    Gender? gender,
    BloodType? bloodType,
    String? profileImage,
    String? emergencyContact,
    String? emergencyPhone,
    String? address,
    String? medicalHistory,
    List<String>? allergies,
    List<String>? medications,
    List<String>? conditions,
    Map<String, dynamic>? vitals,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      profileImage: profileImage ?? this.profileImage,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      address: address ?? this.address,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      conditions: conditions ?? this.conditions,
      vitals: vitals ?? this.vitals,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  // Helper methods
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  String get ageDisplay => '$age years old';
  String get bloodTypeDisplay => bloodType.toString().split('.').last.toUpperCase();
  String get genderDisplay => gender.toString().split('.').last;
  
  bool get hasAllergies => allergies.isNotEmpty;
  bool get hasMedications => medications.isNotEmpty;
  bool get hasConditions => conditions.isNotEmpty;
  
  double? get bmi {
    if (vitals == null) return null;
    final weight = vitals!['weight']?.toDouble();
    final height = vitals!['height']?.toDouble();
    if (weight == null || height == null) return null;
    if (height <= 0) return null;
    return weight / ((height / 100) * (height / 100));
  }
  
  String? get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return null;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal weight';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }
}
