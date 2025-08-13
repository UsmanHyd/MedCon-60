import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'doctor_profile.dart';
import 'package:medcon30/providers/doctor_provider.dart';

class SearchDoctorScreen extends ConsumerStatefulWidget {
  final String? symptomCheckId;
  const SearchDoctorScreen({super.key, this.symptomCheckId});

  @override
  ConsumerState<SearchDoctorScreen> createState() => _SearchDoctorScreenState();
}

class _SearchDoctorScreenState extends ConsumerState<SearchDoctorScreen> {
  final List<String> filters = [
    'All',
    'General Physician',
    'Pulmonologist',
    'Cardiologist',
    'Dermatologist',
    'ENT Specialist',
  ];
  int selectedFilter = 0;
  bool showFilterDialog = false;
  double minRating = 0.0;
  double maxDistance = 10.0;
  String selectedSortBy = 'Rating';

  // Get available specializations from provider
  List<String> get availableSpecializations {
    return ref.watch(availableSpecializationsProvider);
  }

  // Apply filters using the doctor provider
  void _applyFilters() {
    final doctorNotifier = ref.read(doctorProvider.notifier);
    final filterConfig = DoctorSearchFilters(
      specialization: selectedFilter > 0 ? this.filters[selectedFilter] : null,
      minRating: minRating > 0 ? minRating : null,
      maxDistance: maxDistance < 20 ? maxDistance : null,
      sortBy: selectedSortBy.toLowerCase(),
    );
    doctorNotifier.updateFilters(filterConfig);
    setState(() {
      showFilterDialog = false;
    });
  }

  // Reset filters
  void _resetFilters() {
    setState(() {
      minRating = 0.0;
      maxDistance = 10.0;
      selectedSortBy = 'Rating';
    });
    final doctorNotifier = ref.read(doctorProvider.notifier);
    doctorNotifier.updateFilters(DoctorSearchFilters());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.blueGrey[900];
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.blueGrey[700];

    final scaffold = Scaffold(
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
                    icon: Icon(Icons.filter_list,
                        color: isDarkMode
                            ? Colors.blue[300]
                            : const Color(0xFF2196F3),
                        size: 20),
                    onPressed: () {
                      setState(() {
                        showFilterDialog = true;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Icon(Icons.help_outline,
                        color: isDarkMode
                            ? Colors.blue[300]
                            : const Color(0xFF2196F3),
                        size: 20),
                  ),
                ],
              ),
            ),
            Divider(
                height: 1,
                thickness: 1,
                color: isDarkMode ? Colors.grey[800] : const Color(0xFFE0E3EA)),
            // Filters
            Container(
              color: bgColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(filters.length, (i) {
                    final selected = selectedFilter == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(filters[i]),
                        selected: selected,
                        onSelected: (_) => setState(() => selectedFilter = i),
                        selectedColor: const Color(0xFF2196F3),
                        backgroundColor:
                            isDarkMode ? Colors.grey[800] : Colors.white,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF2196F3)
                                : isDarkMode
                                    ? Colors.grey[700]!
                                    : const Color(0xFFE0E3EA),
                            width: 1.5,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            // Doctor cards using Riverpod provider
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final doctorsState = ref.watch(doctorProvider);

                  return doctorsState.when(
                    data: (doctors) {
                      if (doctors.isEmpty) {
                        return Center(
                          child: Text(
                            'No doctors found',
                            style: TextStyle(color: subTextColor),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
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
                                      color: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.blue[50],
                                    ),
                                    child: (doctor.profileImage != null &&
                                            doctor.profileImage!.isNotEmpty)
                                        ? Image.network(
                                            doctor.profileImage!,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          color: isDarkMode
                                              ? Colors.blue[300]
                                              : Colors.blue[600],
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      // Location
                                      if (doctor.location.isNotEmpty)
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
                                                doctor.location,
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
                                                ? doctor.rating
                                                    .toStringAsFixed(1)
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
                                        ],
                                      ),
                                      // Languages
                                      if (doctor.languages.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Wrap(
                                            spacing: 4,
                                            children: doctor.languages
                                                .take(3)
                                                .map((language) => Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: isDarkMode
                                                            ? Colors.grey[700]
                                                            : Colors.grey[200],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Text(
                                                        language,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDarkMode
                                                              ? Colors.grey[300]
                                                              : Colors
                                                                  .grey[700],
                                                        ),
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
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
                                            builder: (context) =>
                                                DoctorProfileScreen(
                                              doctorId: doctor.id,
                                              symptomCheckId:
                                                  widget.symptomCheckId,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF2196F3),
                                        minimumSize: const Size(80, 36),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color:
                                isDarkMode ? Colors.red[300] : Colors.red[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load doctors',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: $error',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(doctorProvider.notifier)
                                  .refreshDoctors();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      children: [
        scaffold,
        if (showFilterDialog) _buildFilterDialog(),
      ],
    );
  }

  Widget _buildFilterDialog() {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    return Dialog(
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Doctors',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.blueGrey[900],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      showFilterDialog = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Minimum Rating',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.blueGrey[900],
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: minRating,
              min: 0.0,
              max: 5.0,
              divisions: 10,
              activeColor: const Color(0xFF2196F3),
              onChanged: (value) {
                setState(() {
                  minRating = value;
                });
              },
            ),
            Text('${minRating.toStringAsFixed(1)} stars'),
            const SizedBox(height: 20),
            Text(
              'Maximum Distance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.blueGrey[900],
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: maxDistance,
              min: 1.0,
              max: 20.0,
              divisions: 19,
              activeColor: const Color(0xFF2196F3),
              onChanged: (value) {
                setState(() {
                  maxDistance = value;
                });
              },
            ),
            Text('${maxDistance.toStringAsFixed(1)} km'),
            const SizedBox(height: 20),
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.blueGrey[900],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedSortBy,
              isExpanded: true,
              dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.blueGrey[900],
              ),
              items:
                  ['Rating', 'Distance', 'Reviews', 'Name'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedSortBy = newValue!;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF2196F3)),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
