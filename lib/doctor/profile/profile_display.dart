import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/cloudinary_service.dart';

class DoctorProfileDisplayScreen extends StatefulWidget {
  const DoctorProfileDisplayScreen({super.key});

  @override
  State<DoctorProfileDisplayScreen> createState() =>
      _DoctorProfileDisplayScreenState();
}

class _DoctorProfileDisplayScreenState
    extends State<DoctorProfileDisplayScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final double _coverImageOffset = 0.0;
  final double _maxCoverDrag = 100.0; // max pixels to drag down
  bool _showFullscreenCover = false;
  double _dragStartY = 0.0;
  double _fullscreenDragStartY = 0.0;
  double _fullscreenDragDelta = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();
      setState(() {
        _profileData = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _profileData = null;
      });
    }
  }

  int? _calculateAge(String dob) {
    try {
      if (dob.isEmpty) return null;
      final parts = dob.split('/');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final birthDate = DateTime(year, month, day);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  String _calculateExperienceDuration(String start, String end) {
    if (start.isEmpty) return '';
    try {
      // Accepts formats like 'Jan 2020', '2020', '01/2020', etc.
      DateTime parseDate(String s) {
        final parts = s.split('/');
        if (parts.length == 2) {
          // MM/YYYY
          return DateTime(int.parse(parts[1]), int.parse(parts[0]));
        } else if (parts.length == 3) {
          // DD/MM/YYYY
          return DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else if (s.contains('-')) {
          // YYYY-MM
          final p = s.split('-');
          return DateTime(int.parse(p[0]), int.parse(p[1]));
        } else if (s.length == 4) {
          // YYYY
          return DateTime(int.parse(s));
        } else {
          // Try parsing directly
          return DateTime.parse(s);
        }
      }

      final startDate = parseDate(start);
      final endDate = (end.isEmpty) ? DateTime.now() : parseDate(end);
      int years = endDate.year - startDate.year;
      int months = endDate.month - startDate.month;
      if (months < 0) {
        years--;
        months += 12;
      }
      String y = years > 0 ? '$years year${years > 1 ? 's' : ''}' : '';
      String m = months > 0 ? '$months month${months > 1 ? 's' : ''}' : '';
      if (y.isNotEmpty && m.isNotEmpty) return '($y, $m)';
      if (y.isNotEmpty) return '($y)';
      if (m.isNotEmpty) return '($m)';
      return '';
    } catch (_) {
      return '';
    }
  }

  int _calculateTotalExperienceYears(List experiences) {
    int totalMonths = 0;
    for (final e in experiences) {
      final start = e['startDate'] ?? '';
      final end = e['endDate'] ?? '';
      if (start.isEmpty) continue;
      try {
        DateTime parseDate(String s) {
          final parts = s.split('/');
          if (parts.length == 2) {
            // MM/YYYY
            return DateTime(int.parse(parts[1]), int.parse(parts[0]));
          } else if (parts.length == 3) {
            // DD/MM/YYYY
            return DateTime(
                int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          } else if (s.contains('-')) {
            // YYYY-MM
            final p = s.split('-');
            return DateTime(int.parse(p[0]), int.parse(p[1]));
          } else if (s.length == 4) {
            // YYYY
            return DateTime(int.parse(s));
          } else {
            // Try parsing directly
            return DateTime.parse(s);
          }
        }

        final startDate = parseDate(start);
        final endDate = (end.isEmpty) ? DateTime.now() : parseDate(end);
        int months = (endDate.year - startDate.year) * 12 +
            (endDate.month - startDate.month);
        if (endDate.day < startDate.day) months--;
        if (months > 0) totalMonths += months;
      } catch (_) {}
    }
    return totalMonths;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0288D1),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style:
                TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _pickAndConfirmImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final tempImage = File(pickedFile.path);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Profile Picture'),
          content:
              Image.file(tempImage, width: 120, height: 120, fit: BoxFit.cover),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Save'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final url = await CloudinaryService.uploadImage(tempImage);
          if (url != null) {
            await FirebaseFirestore.instance
                .collection('doctors')
                .doc(user.uid)
                .update({'profilePic': url});
            setState(() {
              _profileImage = null;
              if (_profileData != null) {
                _profileData!['profilePic'] = url;
              }
            });
          }
        }
      }
    }
  }

  void _showProfilePictureOptions() {
    final profileImageUrl = _profileImage != null
        ? _profileImage!.path
        : (_profileData!['profilePic']);
    if (_profileImage == null &&
        (profileImageUrl == null || profileImageUrl.isEmpty)) {
      _pickAndConfirmImage();
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Profile Picture'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _profileImage != null
                              ? Image.file(_profileImage!)
                              : (profileImageUrl != null &&
                                      profileImageUrl.isNotEmpty)
                                  ? Image.network(profileImageUrl)
                                  : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Profile Picture',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  setState(() {
                    _profileImage = null;
                    if (_profileData != null) {
                      // Get old URL before removing for cache clearing
                      final oldUrl = _profileData!['profilePic']?.toString();
                      
                      // Remove the key entirely from local data
                      _profileData!.remove('profilePic');
                      
                      // Clear image cache to prevent showing old images
                      if (oldUrl != null && oldUrl.isNotEmpty) {
                        try {
                          final imageProvider = NetworkImage(oldUrl);
                          imageProvider.evict();
                        } catch (e) {
                          print('Error clearing image cache: $e');
                        }
                      }
                    }
                  });
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Delete the field from Firestore
                    await FirebaseFirestore.instance
                        .collection('doctors')
                        .doc(user.uid)
                        .update({'profilePic': FieldValue.delete()});
                    
                    // Reload profile data to reflect the deletion
                    await _loadProfileData();
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_a_photo),
                title: const Text('Add New Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndConfirmImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _showProfilePictureOptions,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardColor
              : const Color(0xFFE3F2FD),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]!
                : const Color(0xFF0288D1),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _profileImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.file(
                  _profileImage!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: Color(0xFF0288D1),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      color: Color(0xFF0288D1),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_profileData == null) {
      return const Center(child: Text('No profile data found'));
    }
    // Defensive: ensure education and experience are always lists
    if (_profileData!['education'] is! List) {
      _profileData!['education'] = <Map<String, dynamic>>[];
    }
    if (_profileData!['experience'] is! List) {
      _profileData!['experience'] = <Map<String, dynamic>>[];
    }
    final age = _calculateAge(_profileData!['dateOfBirth'] ?? '');
    final profileImageUrl = _profileImage != null
        ? _profileImage!.path
        : (_profileData!['profilePic']);
    final experienceList = _profileData!["experience"] as List;
    final totalExperienceMonths = experienceList.isNotEmpty
        ? _calculateTotalExperienceYears(experienceList)
        : null;
    final totalExperienceYearsDisplay =
        (totalExperienceMonths != null && totalExperienceMonths > 0)
            ? ((totalExperienceMonths ~/ 12) > 0
                ? '${totalExperienceMonths ~/ 12}+'
                : '1+')
            : (_profileData!["yearsExperience"]?.toString() ?? "-");

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GestureDetector(
                  onVerticalDragStart: (details) {
                    _dragStartY = details.localPosition.dy;
                  },
                  onVerticalDragUpdate: (details) {
                    final dragDistance = details.localPosition.dy - _dragStartY;
                    if (dragDistance > 80 && !_showFullscreenCover) {
                      setState(() {
                        _showFullscreenCover = true;
                      });
                    }
                  },
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    child: Container(
                      height: 260,
                      width: double.infinity,
                      color: Colors.blue[50],
                      child: (profileImageUrl != null &&
                              profileImageUrl.toString().isNotEmpty)
                          ? Image(
                              key: ValueKey('doctor_cover_${profileImageUrl}'),
                              image: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : NetworkImage(profileImageUrl.toString(), headers: {'Cache-Control': 'no-cache'})
                                      as ImageProvider,
                              fit: BoxFit.cover,
                              alignment: const Alignment(0, -0.3),
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.account_circle,
                                    size: 120,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white24
                                        : Colors.blue[100],
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.account_circle,
                                size: 120,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white24
                                    : Colors.blue[100],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  // Main info card (profile picture + name, specialization, rating, stats)
                  Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF23272F)
                        : Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _showProfilePictureOptions,
                                child: CircleAvatar(
                                  key: ValueKey('doctor_profile_card_${profileImageUrl ?? 'no_pic'}'),
                                  radius: 36,
                                  backgroundColor: Colors.white,
                                  backgroundImage: (profileImageUrl != null && profileImageUrl.toString().isNotEmpty)
                                      ? (_profileImage != null
                                              ? FileImage(_profileImage!)
                                              : NetworkImage(profileImageUrl.toString(), headers: {'Cache-Control': 'no-cache'}))
                                          as ImageProvider
                                      : null,
                                  child: (profileImageUrl == null || profileImageUrl.toString().isEmpty)
                                      ? const Icon(Icons.account_circle,
                                          size: 48, color: Color(0xFF0288D1))
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. ' +
                                          (_profileData!['name'] ??
                                              'Doctor Name'),
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.lightBlue[200]
                                              : const Color(0xFF2196F3)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _profileData!['specializations']
                                                  is List &&
                                              (_profileData!['specializations']
                                                      as List)
                                                  .isNotEmpty
                                          ? (_profileData!['specializations']
                                                  as List)
                                              .join(', ')
                                          : 'General Physician',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.lightBlue[100]
                                              : Colors.black54),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: Color(0xFFFFC107), size: 20),
                                        const SizedBox(width: 4),
                                        Text('4.8',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black)),
                                        const SizedBox(width: 4),
                                        Text('(10 reviews)',
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.lightBlue[100]
                                                    : Colors.black54)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatColumn(
                                  label: "Years Exp.",
                                  value: totalExperienceYearsDisplay),
                              const _StatColumn(
                                  label: "Patients", value: '10+'),
                              const _StatColumn(
                                  label: "Satisfaction", value: '98%'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Personal Information Card (new)
                  Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF23272F)
                        : Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Personal Information',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.lightBlue[200]
                                      : const Color(0xFF2196F3))),
                          const SizedBox(height: 10),
                          _InfoRow(
                              label: 'Email',
                              value: _profileData!['email'] ?? 'Not provided'),
                          _InfoRow(
                              label: 'Phone',
                              value: _profileData!['phoneNumber'] ??
                                  'Not provided'),
                          _InfoRow(
                              label: 'Date of Birth',
                              value: _profileData!['dateOfBirth'] ??
                                  'Not provided'),
                          if (age != null)
                            _InfoRow(label: 'Age', value: age.toString()),
                          _InfoRow(
                              label: 'Gender',
                              value: _profileData!['gender'] ?? 'Not provided'),
                          _InfoRow(
                              label: 'License Number',
                              value: _profileData!['licenseNumber'] ??
                                  'Not provided'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // About section
                  const _SectionTitle(title: "About"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF23272F)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _profileData!["description"] != null &&
                                  (_profileData!["description"] as String)
                                      .trim()
                                      .isNotEmpty
                              ? _profileData!["description"]
                              : "No description provided.",
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Qualifications section
                  const _SectionTitle(title: "Qualifications"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF23272F)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Education sub-box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF23272F)
                                    : Colors.blueGrey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Education",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.lightBlue[200]
                                              : const Color(0xFF2196F3))),
                                  ...(_profileData!["education"] as List)
                                          .isEmpty
                                      ? [const Text("No education provided.")]
                                      : (_profileData!["education"] as List)
                                          .map<Widget>((e) {
                                          final degree = e['degree'] ?? '';
                                          final institute =
                                              e['institute'] ?? '';
                                          final start = e['startDate'] ?? '';
                                          final end = e['endDate'] ?? '';
                                          final tenure = (start.isNotEmpty &&
                                                  end.isNotEmpty)
                                              ? '$start - $end'
                                              : '';
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    degree.isNotEmpty
                                                        ? degree
                                                        : 'Degree',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.white
                                                            : Colors.black)),
                                                if (institute.isNotEmpty)
                                                  Text(institute,
                                                      style: TextStyle(
                                                          fontSize: 15,
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white70
                                                              : Colors
                                                                  .black87)),
                                                if (tenure.isNotEmpty)
                                                  Text(tenure,
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors
                                                                  .lightBlue[100]
                                                              : Colors.grey)),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Experience sub-box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF23272F)
                                    : Colors.blueGrey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Experiences",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.lightBlue[200]
                                              : const Color(0xFF2196F3))),
                                  ...(_profileData!["experience"] as List)
                                          .isEmpty
                                      ? [const Text("No experience provided.")]
                                      : (_profileData!["experience"] as List)
                                          .map<Widget>((e) {
                                          final role = e['role'] ?? '';
                                          final location = e['location'] ?? '';
                                          final start = e['startDate'] ?? '';
                                          final end = e['endDate'] ?? '';
                                          final tenure = (start.isNotEmpty &&
                                                  end.isNotEmpty)
                                              ? '$start - $end'
                                              : (start.isNotEmpty
                                                  ? '$start - Present'
                                                  : '');
                                          final duration =
                                              _calculateExperienceDuration(
                                                  start, end);
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    role.isNotEmpty
                                                        ? role
                                                        : 'Role',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.white
                                                            : Colors.black)),
                                                if (location.isNotEmpty)
                                                  Text(location,
                                                      style: TextStyle(
                                                          fontSize: 15,
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white70
                                                              : Colors
                                                                  .black87)),
                                                if (tenure.isNotEmpty)
                                                  Text(
                                                      '$tenure ${duration.isNotEmpty ? duration : ''}',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors
                                                                  .lightBlue[100]
                                                              : Colors.grey)),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ],
          ),
          // Fullscreen cover image overlay
          if (_showFullscreenCover && profileImageUrl != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onVerticalDragStart: (details) {
                  _fullscreenDragStartY = details.localPosition.dy;
                  _fullscreenDragDelta = 0.0;
                },
                onVerticalDragUpdate: (details) {
                  _fullscreenDragDelta =
                      details.localPosition.dy - _fullscreenDragStartY;
                },
                onVerticalDragEnd: (_) {
                  if (_fullscreenDragDelta < -60) {
                    // Dragged up
                    setState(() {
                      _showFullscreenCover = false;
                    });
                  }
                },
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    children: [
                      InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4,
                        child: Center(
                          child: Image(
                            image: _profileImage != null
                                ? FileImage(_profileImage!)
                                : NetworkImage(profileImageUrl)
                                    as ImageProvider,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 24,
                        right: 24,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _showFullscreenCover = false),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.lightBlue[200] : const Color(0xFF2196F3),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.lightBlue[100] : Colors.black87;
    final valueColor = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label:',
              style: TextStyle(fontWeight: FontWeight.w600, color: labelColor)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: valueColor))),
        ],
      ),
    );
  }
}
