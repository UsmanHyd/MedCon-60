import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../api_config.dart';

class DoctorRecommendation {
  final String id;
  final String name;
  final String specialization;
  final String email;
  final String? phone;
  final String? profileImage;
  final double rating;
  final int reviewCount;
  final int experienceYears;
  final String? hospital;
  final String? address;
  final double? consultationFee;

  DoctorRecommendation({
    required this.id,
    required this.name,
    required this.specialization,
    required this.email,
    this.phone,
    this.profileImage,
    required this.rating,
    required this.reviewCount,
    required this.experienceYears,
    this.hospital,
    this.address,
    this.consultationFee,
  });

  factory DoctorRecommendation.fromJson(Map<String, dynamic> json) {
    return DoctorRecommendation(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Doctor',
      specialization: json['specialization'] ?? 'General Practitioner',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImage: json['profileImage'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      experienceYears: json['experienceYears'] ?? 0,
      hospital: json['hospital'],
      address: json['address'],
      consultationFee: json['consultationFee']?.toDouble(),
    );
  }
}

class DiseaseSpecialtyMapping {
  final String disease;
  final String specialty;
  final String reason;

  DiseaseSpecialtyMapping({
    required this.disease,
    required this.specialty,
    required this.reason,
  });

  factory DiseaseSpecialtyMapping.fromJson(Map<String, dynamic> json) {
    return DiseaseSpecialtyMapping(
      disease: json['disease'] ?? '',
      specialty: json['specialty'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}

class DoctorRecommendationsResponse {
  final List<DoctorRecommendation> recommendedDoctors;
  final List<DoctorRecommendation> otherRelevantDoctors;
  final Map<String, List<DoctorRecommendation>> allDoctorsBySpecialty;
  final List<DiseaseSpecialtyMapping> diseaseSpecialtyMappings;
  final String message;

  DoctorRecommendationsResponse({
    required this.recommendedDoctors,
    required this.otherRelevantDoctors,
    required this.allDoctorsBySpecialty,
    required this.diseaseSpecialtyMappings,
    required this.message,
  });

  factory DoctorRecommendationsResponse.fromJson(Map<String, dynamic> json) {
    // Parse recommended doctors
    final recommendedList = (json['recommended_doctors'] as List<dynamic>?)
            ?.map((item) => DoctorRecommendation.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse other relevant doctors
    final otherList = (json['other_relevant_doctors'] as List<dynamic>?)
            ?.map((item) => DoctorRecommendation.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse all doctors by specialty
    final allDoctorsMap = <String, List<DoctorRecommendation>>{};
    if (json['all_doctors_by_specialty'] != null) {
      final allDoctorsJson = json['all_doctors_by_specialty'] as Map<String, dynamic>;
      allDoctorsJson.forEach((specialty, doctorsList) {
        allDoctorsMap[specialty] = (doctorsList as List<dynamic>)
            .map((item) => DoctorRecommendation.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    }

    // Parse disease specialty mappings
    final mappingsList = (json['disease_specialty_mappings'] as List<dynamic>?)
            ?.map((item) => DiseaseSpecialtyMapping.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return DoctorRecommendationsResponse(
      recommendedDoctors: recommendedList,
      otherRelevantDoctors: otherList,
      allDoctorsBySpecialty: allDoctorsMap,
      diseaseSpecialtyMappings: mappingsList,
      message: json['message'] ?? '',
    );
  }
}

class DoctorRecommendationService {
  static String get baseUrl => ApiConfig.doctorRecommendationServer;

  /// Get doctor recommendations based on user's latest disease predictions
  static Future<DoctorRecommendationsResponse> getDoctorRecommendations(
    String userId,
  ) async {
    try {
      print('🌐 Calling doctor recommendation API: $baseUrl/find-doctors');
      print('👤 User ID: $userId');

      final response = await http.post(
        Uri.parse('$baseUrl/find-doctors'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - server may be offline');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DoctorRecommendationsResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to get doctor recommendations: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error getting doctor recommendations: $e');
      rethrow;
    }
  }

  /// Get current user ID from Firebase Auth
  static String? getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Health check for the doctor recommendation server
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('💔 Health check failed: $e');
      return false;
    }
  }
}

