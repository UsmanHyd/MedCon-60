import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../modules/doctor_dashboard.dart';
import 'edit_profile.dart';

class DoctorProfileCreationScreen extends StatefulWidget {
  const DoctorProfileCreationScreen({super.key});

  @override
  State<DoctorProfileCreationScreen> createState() =>
      _DoctorProfileCreationScreenState();
}

class _DoctorProfileCreationScreenState
    extends State<DoctorProfileCreationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isProfileCreated = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _profileData;

  // Controllers
  final TextEditingController _specializationInputController =
      TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedGender = 'Male';
  final List<String> _selectedSpecializations = [];

  // Predefined specializations
  final List<String> _commonSpecializations = [
    'Cardiology',
    'Dermatology',
    'Endocrinology',
    'Gastroenterology',
    'Neurology',
    'Obstetrics & Gynecology',
    'Ophthalmology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Pulmonology',
    'Rheumatology',
    'Urology',
  ];

  // Add lists for education and experience
  final List<Map<String, dynamic>> _educationList = [];
  final List<Map<String, dynamic>> _experienceList = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _specializationInputController.dispose();
    _dobController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _pickDateOfBirth() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      final formatted =
          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
      setState(() {
        _dobController.text = formatted;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      final profileData = {
        'name': userData['name'] ?? '',
        'email': userData['email'] ?? '',
        'phoneNumber': userData['phoneNumber'] ?? '',
        'licenseNumber': userData['licenseNumber'] ?? '',
        'description': _descriptionController.text.trim(),
        'education': _educationList,
        'specializations': _selectedSpecializations,
        'dateOfBirth': _dobController.text,
        'gender': _selectedGender,
        'experience': _experienceList,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update the profile data
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      // Add a delay to show the loading state
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _profileData = profileData;
          _isLoading = false;
          _isProfileCreated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating profile: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _profileData = {
            'name': userData['name'] ?? '',
            'email': userData['email'] ?? '',
            'phoneNumber': userData['phoneNumber'] ?? '',
            'licenseNumber': userData['licenseNumber'] ?? '',
            'description': userData['description'] ?? '',
            'education': (userData['education'] as List<dynamic>?)
                    ?.map((e) => Map<String, dynamic>.from(e))
                    .toList() ??
                [],
            'specializations': userData['specializations'] ?? [],
            'dateOfBirth': userData['dateOfBirth'] ?? '',
            'gender': userData['gender'] ?? '',
            'experience': (userData['experience'] as List<dynamic>?)
                    ?.map((e) => Map<String, dynamic>.from(e))
                    .toList() ??
                [],
          };
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
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

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardColor
              : Colors.white,
          border: Border.all(
            color: Theme.of(context).iconTheme.color!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.2),
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isMultiline = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: isMultiline ? 3 : 1,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).iconTheme.color),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardColor
              : Colors.white,
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
    );
  }

  Widget _buildSpecializationSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specializations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0288D1),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonSpecializations.map((specialization) {
              final isSelected =
                  _selectedSpecializations.contains(specialization);
              return FilterChip(
                label: Text(specialization),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSpecializations.add(specialization);
                    } else {
                      _selectedSpecializations.remove(specialization);
                    }
                  });
                },
                backgroundColor: Colors.grey[200],
                selectedColor: const Color(0xFF0288D1).withOpacity(0.2),
                checkmarkColor: const Color(0xFF0288D1),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF0288D1) : Colors.black87,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _specializationInputController,
                  decoration: const InputDecoration(
                    labelText: 'Add custom specialization',
                    prefixIcon: Icon(Icons.add),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final text = _specializationInputController.text.trim();
                  if (text.isNotEmpty &&
                      !_selectedSpecializations.contains(text)) {
                    setState(() {
                      _selectedSpecializations.add(text);
                      _specializationInputController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedSpecializations.isNotEmpty)
            Wrap(
              spacing: 8,
              children: _selectedSpecializations
                  .map((spec) => Chip(
                        label: Text(spec),
                        onDeleted: () {
                          setState(() {
                            _selectedSpecializations.remove(spec);
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        labelStyle: const TextStyle(color: Color(0xFF0288D1)),
                        deleteIconColor: Colors.red,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileDisplay() {
    final age = _calculateAge(_profileData!['dateOfBirth'] ?? '');
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileImage(),
          const SizedBox(height: 24),
          Text(
            _profileData!['name'] ?? 'No Name',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _profileData!['email'] ?? 'No Email',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).cardColor
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _buildInfoRow(
                  icon: Icons.phone,
                  label: 'Phone Number',
                  value: _profileData!['phoneNumber'] ?? 'Not provided',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Date of Birth',
                  value: _profileData!['dateOfBirth'] ?? 'Not provided',
                ),
                if (age != null) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.cake,
                    label: 'Age',
                    value: age.toString(),
                  ),
                ],
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Gender',
                  value: _profileData!['gender'] ?? 'Not provided',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).cardColor
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Professional Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _buildInfoRow(
                  icon: Icons.badge,
                  label: 'License Number',
                  value: _profileData!['licenseNumber'] ?? 'Not provided',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.school,
                  label: 'Education',
                  value: (_profileData!['education'] is List
                      ? (_profileData!['education'] as List)
                          .map((e) =>
                              '${e['degree'] ?? ''} at ${e['institute'] ?? ''}')
                          .toList()
                          .join(', ')
                      : 'Not provided'),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.work,
                  label: 'Experience',
                  value: (_profileData!['experience'] is List
                      ? (_profileData!['experience'] as List)
                          .map((e) =>
                              '${e['role'] ?? ''} at ${e['location'] ?? ''}')
                          .toList()
                          .join(', ')
                      : 'Not provided'),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.medical_services,
                  label: 'Specializations',
                  value: (_profileData!['specializations'] as List<dynamic>?)
                          ?.join(', ') ??
                      'Not provided',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'About Yourself (detailed description)',
              prefixIcon: const Icon(Icons.info_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).cardColor
                  : Colors.white,
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter a description about yourself'
                : null,
          ),
          const SizedBox(height: 16),
          _buildEducationList(),
          const SizedBox(height: 16),
          _buildExperienceList(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorEditProfileScreen(
                    profileData: {
                      'fullName': _profileData!['name'],
                      'email': _profileData!['email'],
                      'phoneNumber': _profileData!['phoneNumber'],
                      'licenseNumber': _profileData!['licenseNumber'],
                      'education': _profileData!['education'],
                      'specializations': _profileData!['specializations'],
                      'dateOfBirth': _profileData!['dateOfBirth'],
                      'gender': _profileData!['gender'],
                      'experience': _profileData!['experience'],
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0288D1), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Add methods for showing education and experience dialogs
  void _showEducationDialog({Map<String, dynamic>? initial, int? index}) {
    final degreeController =
        TextEditingController(text: initial?['degree'] ?? '');
    final instituteController =
        TextEditingController(text: initial?['institute'] ?? '');
    final startDateController =
        TextEditingController(text: initial?['startDate'] ?? '');
    final endDateController =
        TextEditingController(text: initial?['endDate'] ?? '');
    final descController =
        TextEditingController(text: initial?['description'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Add Education' : 'Edit Education'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: degreeController,
                  decoration: const InputDecoration(labelText: 'Degree')),
              TextField(
                  controller: instituteController,
                  decoration:
                      const InputDecoration(labelText: 'Institute/University')),
              TextField(
                  controller: startDateController,
                  decoration: const InputDecoration(
                      labelText: 'Start Date (e.g. 2015)')),
              TextField(
                  controller: endDateController,
                  decoration: const InputDecoration(
                      labelText: 'End Date (e.g. 2020 or Present)')),
              TextField(
                  controller: descController,
                  decoration:
                      const InputDecoration(labelText: 'Description/Notes')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final record = {
                'degree': degreeController.text,
                'institute': instituteController.text,
                'startDate': startDateController.text,
                'endDate': endDateController.text,
                'description': descController.text,
              };
              setState(() {
                if (index == null) {
                  _educationList.add(record);
                } else {
                  _educationList[index] = record;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExperienceDialog({Map<String, dynamic>? initial, int? index}) {
    final roleController = TextEditingController(text: initial?['role'] ?? '');
    final locationController =
        TextEditingController(text: initial?['location'] ?? '');
    final startDateController =
        TextEditingController(text: initial?['startDate'] ?? '');
    final endDateController =
        TextEditingController(text: initial?['endDate'] ?? '');
    final descController =
        TextEditingController(text: initial?['description'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Add Experience' : 'Edit Experience'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: roleController,
                  decoration:
                      const InputDecoration(labelText: 'Role/Position')),
              TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                      labelText: 'Location/Hospital/Clinic')),
              TextField(
                  controller: startDateController,
                  decoration: const InputDecoration(
                      labelText: 'Start Date (e.g. 2018)')),
              TextField(
                  controller: endDateController,
                  decoration: const InputDecoration(
                      labelText: 'End Date (e.g. 2022 or Present)')),
              TextField(
                  controller: descController,
                  decoration:
                      const InputDecoration(labelText: 'Description/Notes')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final record = {
                'role': roleController.text,
                'location': locationController.text,
                'startDate': startDateController.text,
                'endDate': endDateController.text,
                'description': descController.text,
              };
              setState(() {
                if (index == null) {
                  _experienceList.add(record);
                } else {
                  _experienceList[index] = record;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Add methods to build the education and experience lists in the UI
  Widget _buildEducationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Education',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showEducationDialog()),
          ],
        ),
        ..._educationList.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(e['degree'] ?? ''),
              subtitle: Text(
                  '${e['institute'] ?? ''}\n${e['startDate'] ?? ''} - ${e['endDate'] ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showEducationDialog(initial: e, index: i)),
                  IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _educationList.removeAt(i);
                        });
                      }),
                ],
              ),
              isThreeLine: true,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExperienceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Experience',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showExperienceDialog()),
          ],
        ),
        ..._experienceList.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(e['role'] ?? ''),
              subtitle: Text(
                  '${e['location'] ?? ''}\n${e['startDate'] ?? ''} - ${e['endDate'] ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showExperienceDialog(initial: e, index: i)),
                  IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _experienceList.removeAt(i);
                        });
                      }),
                ],
              ),
              isThreeLine: true,
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isProfileCreated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DoctorDashboard()),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).scaffoldBackgroundColor
            : const Color(0xFFE3F2FD),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Creating Profile...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              )
            : _isProfileCreated
                ? _buildProfileDisplay()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            Center(
                              child: _buildProfileImage(),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText:
                                    'About Yourself (detailed description)',
                                prefixIcon: const Icon(Icons.info_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context).cardColor
                                    : Colors.white,
                              ),
                              validator: (value) => value == null ||
                                      value.trim().isEmpty
                                  ? 'Please enter a description about yourself'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildEducationList(),
                            const SizedBox(height: 16),
                            _buildExperienceList(),
                            _buildSpecializationSection(),
                            _buildFormField(
                              controller: _dobController,
                              label: 'Date of Birth',
                              icon: Icons.calendar_today,
                              readOnly: true,
                              onTap: _pickDateOfBirth,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context).cardColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).shadowColor,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gender',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0288D1),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: const Text('Male'),
                                          value: 'Male',
                                          groupValue: _selectedGender,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedGender = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: const Text('Female'),
                                          value: 'Female',
                                          groupValue: _selectedGender,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedGender = value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Create Profile',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
