import 'package:cloud_firestore/cloud_firestore.dart';

// Doctor specialization enum
enum DoctorSpecialization {
  cardiology,
  dermatology,
  endocrinology,
  gastroenterology,
  general,
  neurology,
  oncology,
  ophthalmology,
  orthopedics,
  pediatrics,
  psychiatry,
  radiology,
  surgery,
  urology,
  other,
}

// Doctor availability enum
enum AvailabilityStatus {
  available,
  busy,
  offline,
  onCall,
}

// Doctor data model
class Doctor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String specialization;
  final String? profileImage;
  final String? bio;
  final String? licenseNumber;
  final String? hospital;
  final String? address;
  final double rating;
  final int reviewCount;
  final int experienceYears;
  final List<String> languages;
  final List<String> certifications;
  final AvailabilityStatus availability;
  final Map<String, dynamic>? workingHours;
  final double? consultationFee;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime lastActive;

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialization,
    this.profileImage,
    this.bio,
    this.licenseNumber,
    this.hospital,
    this.address,
    required this.rating,
    required this.reviewCount,
    required this.experienceYears,
    required this.languages,
    required this.certifications,
    required this.availability,
    this.workingHours,
    this.consultationFee,
    required this.isVerified,
    required this.createdAt,
    required this.lastActive,
  });

  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Doctor(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      specialization: data['specialization'] ?? '',
      profileImage: data['profileImage'],
      bio: data['bio'],
      licenseNumber: data['licenseNumber'],
      hospital: data['hospital'],
      address: data['address'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      experienceYears: data['experienceYears'] ?? 0,
      languages: List<String>.from(data['languages'] ?? []),
      certifications: List<String>.from(data['certifications'] ?? []),
      availability: AvailabilityStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['availability'],
        orElse: () => AvailabilityStatus.offline,
      ),
      workingHours: data['workingHours'],
      consultationFee: data['consultationFee']?.toDouble(),
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'specialization': specialization,
      'profileImage': profileImage,
      'bio': bio,
      'licenseNumber': licenseNumber,
      'hospital': hospital,
      'address': address,
      'rating': rating,
      'reviewCount': reviewCount,
      'experienceYears': experienceYears,
      'languages': languages,
      'certifications': certifications,
      'availability': availability.toString().split('.').last,
      'workingHours': workingHours,
      'consultationFee': consultationFee,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  Doctor copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? specialization,
    String? profileImage,
    String? bio,
    String? licenseNumber,
    String? hospital,
    String? address,
    double? rating,
    int? reviewCount,
    int? experienceYears,
    List<String>? languages,
    List<String>? certifications,
    AvailabilityStatus? availability,
    Map<String, dynamic>? workingHours,
    double? consultationFee,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      hospital: hospital ?? this.hospital,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      experienceYears: experienceYears ?? this.experienceYears,
      languages: languages ?? this.languages,
      certifications: certifications ?? this.certifications,
      availability: availability ?? this.availability,
      workingHours: workingHours ?? this.workingHours,
      consultationFee: consultationFee ?? this.consultationFee,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  // Helper methods
  bool get isAvailable => availability == AvailabilityStatus.available;
  bool get isOnline => availability != AvailabilityStatus.offline;
  String get ratingDisplay => rating.toStringAsFixed(1);
  String get experienceDisplay => '$experienceYears years';
}
