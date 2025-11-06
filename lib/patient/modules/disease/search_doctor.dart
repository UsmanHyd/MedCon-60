import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'doctor_profile.dart';
import 'package:medcon30/services/doctor_recommendation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchDoctorScreen extends ConsumerStatefulWidget {
  final String? symptomCheckId;
  const SearchDoctorScreen({super.key, this.symptomCheckId});

  @override
  ConsumerState<SearchDoctorScreen> createState() => _SearchDoctorScreenState();
}

class _SearchDoctorScreenState extends ConsumerState<SearchDoctorScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: Recommended, 1: Other Doctors, 2: All Doctors
  late TabController _tabController;
  
  DoctorRecommendationsResponse? _recommendations;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDoctorRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _errorMessage = 'Please login to see doctor recommendations';
          _isLoading = false;
        });
        return;
      }

      final response = await DoctorRecommendationService.getDoctorRecommendations(userId);
      
      setState(() {
        _recommendations = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load doctors: ${e.toString()}';
        _isLoading = false;
      });
      print('❌ Error loading doctor recommendations: $e');
    }
  }

  List<DoctorRecommendation> get _currentDoctors {
    if (_recommendations == null) return [];
    
    switch (_selectedTab) {
      case 0: // Recommended
        return _recommendations!.recommendedDoctors;
      case 1: // Other Doctors
        return _recommendations!.otherRelevantDoctors;
      case 2: // All Doctors
        // Flatten all doctors from all specialties
        final allDoctors = <DoctorRecommendation>[];
        _recommendations!.allDoctorsBySpecialty.forEach((specialty, doctors) {
          allDoctors.addAll(doctors);
        });
        return allDoctors;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.blueGrey[900]!;
    final subTextColor = isDarkMode ? Colors.grey[400]! : Colors.blueGrey[700]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              color: bgColor,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 20, color: textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Search for Doctors',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: isDarkMode ? Colors.blue[300] : const Color(0xFF2196F3),
                      size: 20,
                    ),
                    onPressed: _loadDoctorRecommendations,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Divider(
                height: 1,
                thickness: 1,
                color: isDarkMode ? Colors.grey[800] : const Color(0xFFE0E3EA)),
            
            // Tab Bar
            Container(
              color: bgColor,
              child: TabBar(
                controller: _tabController,
                onTap: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                indicatorColor: const Color(0xFF2196F3),
                labelColor: const Color(0xFF2196F3),
                unselectedLabelColor: subTextColor,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Recommended'),
                  Tab(text: 'Other Doctors'),
                  Tab(text: 'All Doctors'),
                ],
              ),
            ),
            
            // Doctor List
            Expanded(
              child: _buildDoctorList(isDarkMode, cardColor, textColor, subTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorList(
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDarkMode ? Colors.red[300] : Colors.red[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to Load Doctors',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadDoctorRecommendations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final doctors = _currentDoctors;

                      if (doctors.isEmpty) {
                        return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: subTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedTab == 0
                  ? 'No recommended doctors found'
                  : _selectedTab == 1
                      ? 'No other relevant doctors found'
                      : 'No doctors found',
              style: TextStyle(
                color: subTextColor,
                fontSize: 16,
              ),
            ),
            if (_selectedTab == 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                  'Try checking for diseases first to get personalized recommendations',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
                          ),
                        );
                      }

                      return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: doctors.length,
                        itemBuilder: (context, i) {
                          final doctor = doctors[i];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.black.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile Picture
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.blue[50],
                                    ),
                                    child: (doctor.profileImage != null &&
                                            doctor.profileImage!.isNotEmpty)
                                        ? Image.network(
                                            doctor.profileImage!,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.account_circle,
                                                size: 64,
                                                color: isDarkMode
                                                    ? Colors.grey[600]
                                                    : Colors.blueGrey[200],
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.account_circle,
                                            size: 64,
                                            color: isDarkMode
                                                ? Colors.grey[600]
                                                : Colors.blueGrey[200],
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Doctor Info
                                Expanded(
                                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Doctor Name with "Dr." prefix
                                      Text(
                                        'Dr. ${doctor.name}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      // Specialization
                                      Text(
                                        doctor.specialization.isNotEmpty
                                            ? doctor.specialization
                                            : 'No specialization',
                                        style: TextStyle(
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                    // Location or Hospital
                    if (doctor.hospital != null && doctor.hospital!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.local_hospital,
                            size: 16,
                            color: subTextColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctor.hospital!,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      )
                    else if (doctor.address != null &&
                        doctor.address!.isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: subTextColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                              doctor.address!,
                                                style: TextStyle(
                                                  color: subTextColor,
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      const SizedBox(height: 8),
                                      // Rating and Reviews
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            color: Colors.amber,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            doctor.rating > 0
                              ? doctor.rating.toStringAsFixed(1)
                                                : '0.0',
                                            style: TextStyle(
                                              color: subTextColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '(${doctor.reviewCount} reviews)',
                                            style: TextStyle(
                                              color: subTextColor,
                                              fontSize: 13,
                                            ),
                                          ),
                        if (doctor.experienceYears > 0) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.work_outline,
                            size: 16,
                            color: subTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${doctor.experienceYears} years',
                                                        style: TextStyle(
                              color: subTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                                        ),
                                    ],
                                  ),
                                ),
                                // View Button
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                          builder: (context) => DoctorProfileScreen(
                                              doctorId: doctor.id,
                            symptomCheckId: widget.symptomCheckId,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                                        minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'View',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
    );
  }
}
