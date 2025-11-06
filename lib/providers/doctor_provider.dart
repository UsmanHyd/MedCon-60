import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Doctor data model
class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String email;
  final String? phoneNumber;
  final String? profileImage;
  final double rating;
  final int reviewCount;
  final String location;
  final double latitude;
  final double longitude;
  final List<String> languages;
  final Map<String, dynamic>? additionalData;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.email,
    this.phoneNumber,
    this.profileImage,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.languages,
    this.additionalData,
  });

  factory Doctor.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    String? firstNonEmptyString(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return null;
    }

    // Normalize languages (can be List or comma-separated String)
    List<String> parseLanguages(dynamic raw) {
      if (raw is List) {
        return List<String>.from(
            raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty));
      }
      if (raw is String && raw.trim().isNotEmpty) {
        return raw
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return <String>[];
    }

    final String resolvedName = firstNonEmptyString([
          'name',
          'fullName',
          'displayName',
        ]) ??
        '';

    final String resolvedSpecialization = firstNonEmptyString([
          'specialization',
          'specialty',
          'specialisation',
          'specilization',
        ]) ??
        (() {
          // Check for specializations (plural) as a List
          final specsList = data['specializations'];
          if (specsList is List && specsList.isNotEmpty) {
            return specsList.map((e) => e.toString()).join(', ');
          }
          return '';
        })();

    final String? resolvedProfileImage = firstNonEmptyString([
      'profileImage',
      'avatar',
      'photoUrl',
      'photoURL',
      'imageUrl',
      'image',
      'profilePic',
      'profile_photo',
      'profilePhotoUrl',
      'picture',
    ]);

    final double resolvedRating = (data['rating'] is num)
        ? (data['rating'] as num).toDouble()
        : (data['avgRating'] is num)
            ? (data['avgRating'] as num).toDouble()
            : (data['reviewsAvg'] is num)
                ? (data['reviewsAvg'] as num).toDouble()
                : 0.0;

    final int resolvedReviewCount = (data['reviewCount'] is num)
        ? (data['reviewCount'] as num).toInt()
        : (data['reviewsCount'] is num)
            ? (data['reviewsCount'] as num).toInt()
            : (data['numReviews'] is num)
                ? (data['numReviews'] as num).toInt()
                : 0;

    final String resolvedLocation = firstNonEmptyString([
          'location',
          'city',
          'address',
          'clinic',
          'hospital',
        ]) ??
        '';

    final double resolvedLatitude =
        (data['latitude'] is num) ? (data['latitude'] as num).toDouble() : 0.0;
    final double resolvedLongitude = (data['longitude'] is num)
        ? (data['longitude'] as num).toDouble()
        : 0.0;

    final List<String> resolvedLanguages = parseLanguages(
      data['languages'] ?? data['language'] ?? data['langs'],
    );

    return Doctor(
      id: doc.id,
      name: resolvedName,
      specialization: resolvedSpecialization,
      email: (data['email'] ?? '').toString(),
      phoneNumber: data['phoneNumber']?.toString(),
      profileImage: resolvedProfileImage,
      rating: resolvedRating,
      reviewCount: resolvedReviewCount,
      location: resolvedLocation,
      latitude: resolvedLatitude,
      longitude: resolvedLongitude,
      languages: resolvedLanguages,
      additionalData: data,
    );
  }
}

// Search filters
class DoctorSearchFilters {
  final String? specialization;
  final double? minRating;
  final double? maxDistance;
  final String? location;
  final List<String>? languages;
  final String? sortBy; // 'rating', 'distance', 'name'

  DoctorSearchFilters({
    this.specialization,
    this.minRating,
    this.maxDistance,
    this.location,
    this.languages,
    this.sortBy,
  });

  DoctorSearchFilters copyWith({
    String? specialization,
    double? minRating,
    double? maxDistance,
    String? location,
    List<String>? languages,
    String? sortBy,
  }) {
    return DoctorSearchFilters(
      specialization: specialization ?? this.specialization,
      minRating: minRating ?? this.minRating,
      maxDistance: maxDistance ?? this.maxDistance,
      location: location ?? this.location,
      languages: languages ?? this.languages,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

// Doctor state notifier
class DoctorNotifier extends StateNotifier<AsyncValue<List<Doctor>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DoctorSearchFilters _filters = DoctorSearchFilters();
  List<Doctor> _allDoctors = [];

  DoctorNotifier() : super(const AsyncValue.loading()) {
    _loadDoctors();
  }

  DoctorSearchFilters get filters => _filters;

  Future<void> _loadDoctors() async {
    try {
      state = const AsyncValue.loading();

      Query<Map<String, dynamic>> query = _firestore.collection('doctors');

      if (_filters.specialization != null &&
          _filters.specialization!.isNotEmpty &&
          _filters.specialization != 'All') {
        query =
            query.where('specialization', isEqualTo: _filters.specialization);
      }
      if (_filters.minRating != null && _filters.minRating! > 0) {
        query =
            query.where('rating', isGreaterThanOrEqualTo: _filters.minRating);
      }

      final snapshot = await query.get();
      _allDoctors =
          snapshot.docs.map((doc) => Doctor.fromFirestore(doc)).toList();

      _applyFiltersAndSort();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Removed mock doctors method; using Firestore now

  void _applyFiltersAndSort() {
    List<Doctor> filteredDoctors = List.from(_allDoctors);

    // Apply specialization filter
    if (_filters.specialization != null &&
        _filters.specialization!.isNotEmpty &&
        _filters.specialization != 'All') {
      filteredDoctors = filteredDoctors.where((doctor) {
        return doctor.specialization.toLowerCase() ==
            _filters.specialization!.toLowerCase();
      }).toList();
    }

    // Apply rating filter
    if (_filters.minRating != null && _filters.minRating! > 0) {
      filteredDoctors = filteredDoctors.where((doctor) {
        return doctor.rating >= _filters.minRating!;
      }).toList();
    }

    // Apply distance filter if location is provided
    if (_filters.location != null && _filters.maxDistance != null) {
      // Simple distance filtering (placeholder)
      filteredDoctors = filteredDoctors.where((doctor) {
        return true;
      }).toList();
    }

    // Apply language filter
    if (_filters.languages != null && _filters.languages!.isNotEmpty) {
      filteredDoctors = filteredDoctors.where((doctor) {
        return _filters.languages!
            .any((lang) => doctor.languages.contains(lang));
      }).toList();
    }

    // Apply sorting
    switch (_filters.sortBy) {
      case 'rating':
        filteredDoctors.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'name':
        filteredDoctors.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'distance':
        // Implement distance-based sorting if needed
        break;
      default:
        // Default: sort by rating
        filteredDoctors.sort((a, b) => b.rating.compareTo(a.rating));
    }

    state = AsyncValue.data(filteredDoctors);
  }

  Future<void> updateFilters(DoctorSearchFilters newFilters) async {
    _filters = newFilters;
    await _loadDoctors();
  }

  Future<void> searchDoctors(String queryText) async {
    try {
      state = const AsyncValue.loading();

      // Name range query
      final nameSnap = await _firestore
          .collection('doctors')
          .where('name', isGreaterThanOrEqualTo: queryText)
          .where('name', isLessThan: queryText + '\uf8ff')
          .get();
      final nameResults =
          nameSnap.docs.map((d) => Doctor.fromFirestore(d)).toList();

      // Specialization range query
      final specSnap = await _firestore
          .collection('doctors')
          .where('specialization', isGreaterThanOrEqualTo: queryText)
          .where('specialization', isLessThan: queryText + '\uf8ff')
          .get();
      final specResults =
          specSnap.docs.map((d) => Doctor.fromFirestore(d)).toList();

      // Merge unique by id
      final Map<String, Doctor> byId = {
        for (final d in [...nameResults, ...specResults]) d.id: d,
      };
      _allDoctors = byId.values.toList();

      _applyFiltersAndSort();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshDoctors() async {
    await _loadDoctors();
  }

  Future<Doctor?> getDoctorById(String doctorId) async {
    try {
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      if (doc.exists) {
        return Doctor.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

// Providers
final doctorProvider =
    StateNotifierProvider<DoctorNotifier, AsyncValue<List<Doctor>>>(
  (ref) => DoctorNotifier(),
);

final doctorFiltersProvider = Provider<DoctorSearchFilters>((ref) {
  final doctorNotifier = ref.watch(doctorProvider.notifier);
  return doctorNotifier.filters;
});

// Convenience providers
final availableSpecializationsProvider = Provider<List<String>>((ref) {
  final doctors = ref.watch(doctorProvider);
  return doctors.when(
    data: (doctors) {
      final specializations =
          doctors.map((d) => d.specialization).toSet().toList();
      specializations.sort();
      return specializations;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final topRatedDoctorsProvider = Provider<List<Doctor>>((ref) {
  final doctors = ref.watch(doctorProvider);
  return doctors.when(
    data: (doctors) {
      final sorted = List<Doctor>.from(doctors);
      sorted.sort((a, b) => b.rating.compareTo(a.rating));
      return sorted.take(5).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
