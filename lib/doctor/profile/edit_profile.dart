import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/cloudinary_service.dart';

class DoctorEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const DoctorEditProfileScreen({
    super.key,
    required this.profileData,
  });

  @override
  State<DoctorEditProfileScreen> createState() =>
      _DoctorEditProfileScreenState();
}

class _DoctorEditProfileScreenState extends State<DoctorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _specializationInputController =
      TextEditingController();

  String _selectedGender = 'Male';
  final List<String> _selectedSpecializations = [];

  // New: Lists for education and experience
  List<Map<String, dynamic>> _educationList = [];
  List<Map<String, dynamic>> _experienceList = [];

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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _profileImageUrl = widget.profileData['profilePic'] as String?;
  }

  void _initializeControllers() {
    _nameController.text = widget.profileData['name'] ?? '';
    _emailController.text = widget.profileData['email'] ?? '';
    _phoneController.text = widget.profileData['phoneNumber'] ?? '';
    _licenseController.text = widget.profileData['licenseNumber'] ?? '';
    _dobController.text = widget.profileData['dateOfBirth'] ?? '';
    _selectedGender = widget.profileData['gender'] ?? 'Male';
    _selectedSpecializations.addAll(
      (widget.profileData['specializations'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
    );
    // Load education and experience lists
    _educationList = (widget.profileData['education'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
    _experienceList = (widget.profileData['experience'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _dobController.dispose();
    _specializationInputController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      String? imageUrl = _profileImageUrl;
      if (_profileImage != null) {
        imageUrl = await CloudinaryService.uploadImage(_profileImage!);
        if (imageUrl == null) throw Exception('Image upload failed');
      }

      final profileData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
        'education': _educationList,
        'specializations': _selectedSpecializations,
        'dateOfBirth': _dobController.text.trim(),
        'gender': _selectedGender,
        'experience': _experienceList,
        'profilePic': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update the profile data
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

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
                decoration: const InputDecoration(labelText: 'Degree'),
              ),
              TextField(
                controller: instituteController,
                decoration:
                    const InputDecoration(labelText: 'Institute/University'),
              ),
              TextField(
                controller: startDateController,
                decoration:
                    const InputDecoration(labelText: 'Start Date (e.g. 2015)'),
              ),
              TextField(
                controller: endDateController,
                decoration: const InputDecoration(
                    labelText: 'End Date (e.g. 2020 or Present)'),
              ),
              TextField(
                controller: descController,
                decoration:
                    const InputDecoration(labelText: 'Description/Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
                decoration: const InputDecoration(labelText: 'Role/Position'),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                    labelText: 'Location/Hospital/Clinic'),
              ),
              TextField(
                controller: startDateController,
                decoration:
                    const InputDecoration(labelText: 'Start Date (e.g. 2018)'),
              ),
              TextField(
                controller: endDateController,
                decoration: const InputDecoration(
                    labelText: 'End Date (e.g. 2022 or Present)'),
              ),
              TextField(
                controller: descController,
                decoration:
                    const InputDecoration(labelText: 'Description/Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
              onPressed: () => _showEducationDialog(),
            ),
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
                    onPressed: () => _showEducationDialog(initial: e, index: i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _educationList.removeAt(i);
                      });
                    },
                  ),
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
              onPressed: () => _showExperienceDialog(),
            ),
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
                        _showExperienceDialog(initial: e, index: i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _experienceList.removeAt(i);
                      });
                    },
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: _profileImage != null
              ? FileImage(_profileImage!)
              : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                  ? NetworkImage(_profileImageUrl!) as ImageProvider
                  : const AssetImage('assets/default_avatar.png'),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, color: Color(0xFF0288D1)),
            ),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.white,
        elevation: 0,
      ),
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
                    'Updating Profile...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: _buildProfileImage(),
                    ),
                    const SizedBox(height: 24),
                    _buildFormField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                    ),
                    _buildFormField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildFormField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildFormField(
                      controller: _licenseController,
                      label: 'License Number',
                      icon: Icons.badge,
                    ),
                    _buildFormField(
                      controller: _dobController,
                      label: 'Date of Birth',
                      icon: Icons.calendar_today,
                      readOnly: true,
                      onTap: _pickDateOfBirth,
                    ),
                    _buildSpecializationSection(),
                    const SizedBox(height: 16),
                    _buildEducationList(),
                    const SizedBox(height: 16),
                    _buildExperienceList(),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
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
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Update Profile',
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
    );
  }
}
