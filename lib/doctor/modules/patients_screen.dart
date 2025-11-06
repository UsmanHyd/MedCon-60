import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcon30/doctor/modules/consultation/patient_request_history.dart';
import 'package:medcon30/doctor/modules/consultation/doctor_patient_profile_screen.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search patients...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0288D1)),
                filled: true,
                fillColor:
                    isDarkMode ? Colors.grey[900] : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // Patient List from accepted consultation requests
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('consultation_requests')
                  .where('doctorId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('status', isEqualTo: 'Accepted')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Failed to load patients',
                        style: TextStyle(
                            color:
                                isDarkMode ? Colors.white70 : Colors.black54)),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                final Map<String, Map<String, dynamic>> byPatient = {};
                for (final d in docs) {
                  final data = {'id': d.id, ...d.data()};
                  final String? pid = data['patientId'] as String?;
                  if (pid == null || pid.isEmpty) continue;
                  final existing = byPatient[pid];
                  if (existing == null) {
                    byPatient[pid] = data;
                  } else {
                    final ca = data['createdAt'];
                    final cb = existing['createdAt'];
                    if (ca is Timestamp && cb is Timestamp) {
                      if (ca.compareTo(cb) > 0) byPatient[pid] = data;
                    }
                  }
                }
                var items = byPatient.values.toList();
                items.sort((a, b) {
                  final ta = a['createdAt'];
                  final tb = b['createdAt'];
                  if (ta is Timestamp && tb is Timestamp)
                    return tb.compareTo(ta);
                  return 0;
                });
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  items = items.where((m) {
                    final name =
                        (m['patientName'] ?? '').toString().toLowerCase();
                    final text = (m['symptoms'] ?? m['requestText'] ?? '')
                        .toString()
                        .toLowerCase();
                    return name.contains(q) || text.contains(q);
                  }).toList();
                }
                if (items.isEmpty) {
                  return Center(
                    child: Text('No accepted patients yet',
                        style: TextStyle(
                            color:
                                isDarkMode ? Colors.white70 : Colors.black54)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final m = items[index];
                    final String patientId = (m['patientId'] ?? '').toString();
                    final String patientName =
                        (m['patientName'] ?? 'Patient').toString();
                    final String gender = (m['patientGender'] ?? '').toString();
                    final dynamic ts = m['createdAt'];
                    String lastVisit = '';
                    if (ts is Timestamp) {
                      final dt = ts.toDate();
                      lastVisit = '${dt.day}/${dt.month}/${dt.year}';
                    }
                    final String subtitle =
                        (m['symptoms'] ?? m['requestText'] ?? '').toString();

                    int _calcAge(dynamic dobOrAge) {
                      if (dobOrAge == null) return 0;
                      if (dobOrAge is num && dobOrAge > 0) return dobOrAge.toInt();
                      DateTime? dob;
                      if (dobOrAge is Timestamp) {
                        dob = dobOrAge.toDate();
                      } else if (dobOrAge is String) {
                        final s = dobOrAge.trim();
                        final asNum = int.tryParse(s);
                        if (asNum != null && asNum > 0) return asNum;
                        if (s.contains('/')) {
                          final parts = s.split('/');
                          if (parts.length == 3) {
                            try {
                              final day = int.parse(parts[0]);
                              final month = int.parse(parts[1]);
                              final year = int.parse(parts[2]);
                              dob = DateTime(year, month, day); // DD/MM/YYYY
                            } catch (_) {}
                          }
                        }
                        dob ??= DateTime.tryParse(s);
                      }
                      if (dob != null) {
                        final now = DateTime.now();
                        int years = now.year - dob.year;
                        if (now.month < dob.month ||
                            (now.month == dob.month && now.day < dob.day)) {
                          years -= 1;
                        }
                        if (years > 0 && years < 150) return years;
                      }
                      return 0;
                    }

                    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: patientId.isNotEmpty
                          ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(patientId)
                              .get()
                          : null,
                      builder: (context, userSnap) {
                        // Show loader while fetching profile picture
                        if (userSnap.connectionState == ConnectionState.waiting) {
                          final loaderIsDarkMode = provider_pkg.Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: loaderIsDarkMode ? Colors.grey[850] : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patientName,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: loaderIsDarkMode ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Loading...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: loaderIsDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        final userData = userSnap.data?.data() ?? <String, dynamic>{};
                        // Age priority: user profile DOB -> request DOB -> explicit ages
                        int age = 0;
                        age = _calcAge(userData['dateOfBirth'] ??
                            userData['dob'] ??
                            userData['DOB'] ??
                            userData['patientDateOfBirth'] ??
                            userData['patientDob']);
                        if (age == 0) {
                          age = _calcAge(m['patientDateOfBirth'] ??
                              m['dateOfBirth'] ??
                              m['patientDob'] ??
                              m['dob'] ??
                              m['DOB']);
                        }
                        if (age == 0) {
                          age = _calcAge(m['patientAge'] ?? m['age']);
                        }

                        // Get profile picture ONLY from users collection - don't use cached values
                        String? profilePicUrl;
                        if (userData.containsKey('profilePic')) {
                          final picValue = userData['profilePic'];
                          // Only use if it's not null and not empty
                          if (picValue != null && picValue.toString().trim().isNotEmpty) {
                            profilePicUrl = picValue.toString().trim();
                          }
                        }
                        // If profilePic field doesn't exist or is null/empty, set to null (no picture)
                        // DO NOT fallback to cached avatar - only use current data from Firestore
                        
                        // Debug: Log what we found
                        print('🔍 Patients Screen - Patient: $patientName, Has profilePic field: ${userData.containsKey('profilePic')}, Value: ${userData['profilePic']}, Using: $profilePicUrl');

                        return _PatientCard(
                          name: patientName,
                          age: age,
                          gender: gender.isNotEmpty
                              ? gender
                              : (userData['gender']?.toString() ?? '—'),
                          condition: subtitle,
                          lastVisit: lastVisit.isNotEmpty ? lastVisit : '—',
                          status: 'Accepted',
                          imageUrl: profilePicUrl,
                          onViewProfile: () {
                            if (patientId.isEmpty) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorPatientProfileScreen(
                                  patientId: patientId,
                                ),
                              ),
                            );
                          },
                          onChat: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chat coming soon')),
                            );
                          },
                          onHistory: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientRequestHistoryScreen(
                                  doctorId:
                                      FirebaseAuth.instance.currentUser?.uid ?? '',
                                  patientId: patientId,
                                  patientName: patientName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final String name;
  final int age;
  final String gender;
  final String condition;
  final String lastVisit;
  final String status;
  final VoidCallback onViewProfile;
  final VoidCallback onChat;
  final VoidCallback onHistory;
  final String? imageUrl;

  const _PatientCard({
    required this.name,
    required this.age,
    required this.gender,
    required this.condition,
    required this.lastVisit,
    required this.status,
    required this.onViewProfile,
    required this.onChat,
    required this.onHistory,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final initials = name.split(' ').map((e) => e[0]).join('');

    return InkWell(
      onTap: onViewProfile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Profile Picture/Initials - Use conditional rendering
                  (imageUrl != null && imageUrl!.trim().isNotEmpty)
                      ? CircleAvatar(
                          key: ValueKey('patient_card_${imageUrl}_${DateTime.now().millisecondsSinceEpoch}'),
                          radius: 30,
                          backgroundColor:
                              isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
                          backgroundImage: NetworkImage(
                            imageUrl!,
                            headers: {'Cache-Control': 'no-cache'},
                          ),
                          onBackgroundImageError: (exception, stackTrace) {
                            // If image fails to load, clear cache and rebuild
                            NetworkImage(imageUrl!).evict();
                          },
                        )
                      : CircleAvatar(
                          key: ValueKey('patient_card_no_pic_${DateTime.now().millisecondsSinceEpoch}'),
                          radius: 30,
                          backgroundColor:
                              isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Color(0xFF0288D1),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  const SizedBox(width: 16),
                  // Patient Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          age > 0 ? '$age years • $gender' : gender,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey[900]
                          : const Color(0xFFE6F3FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Color(0xFF0288D1),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onChat,
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Chat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onHistory,
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('History'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
