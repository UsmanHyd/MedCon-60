import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';

class ProfileDisplayScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  final bool useWhiteBackground;

  const ProfileDisplayScreen(
      {Key? key, this.showAppBar = true, this.useWhiteBackground = false})
      : super(key: key);

  @override
  ConsumerState<ProfileDisplayScreen> createState() =>
      _ProfileDisplayScreenState();
}

class _ProfileDisplayScreenState extends ConsumerState<ProfileDisplayScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  File? _profileImage;
  bool _showFullscreenCover = false;
  double _fullscreenDragStartY = 0.0;
  double _fullscreenDragDelta = 0.0;

  static const Color _primaryCream = Color(0xFFF8F6F0);
  static const Color _darkCharcoal = Color(0xFF2C2C2C);
  static const Color _warmGray = Color(0xFF6B6B6B);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _mediumGray = Color(0xFFE5E5E5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfileData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final doc = await FirebaseFirestore.instance
          .collection('users')
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

  Future<void> _pickAndConfirmImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final tempImage = File(pickedFile.path);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _primaryCream,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Confirm Profile Picture',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: _darkCharcoal,
            ),
          ),
          content: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(tempImage,
                  width: 120, height: 120, fit: BoxFit.cover),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: _warmGray,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                .collection('users')
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
      backgroundColor: _primaryCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _mediumGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _BottomSheetOption(
                  icon: Icons.visibility_outlined,
                  title: 'View Profile Picture',
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
                _BottomSheetOption(
                  icon: Icons.delete_outline,
                  title: 'Delete Profile Picture',
                  isDestructive: true,
                  onTap: () async {
                    // Get old URL before removing for cache clearing
                    String? oldUrl;
                    if (_profileData != null && _profileData!['profilePic'] != null) {
                      oldUrl = _profileData!['profilePic']?.toString();
                    }
                    
                    setState(() {
                      _profileImage = null;
                      if (_profileData != null) {
                        _profileData!.remove('profilePic'); // Remove the key entirely
                      }
                    });
                    
                    // Clear image cache to prevent showing old images
                    if (oldUrl != null && oldUrl.isNotEmpty) {
                      try {
                        // Clear the image from cache
                        final imageProvider = NetworkImage(oldUrl);
                        imageProvider.evict();
                      } catch (e) {
                        print('Error clearing image cache: $e');
                      }
                    }
                    
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // Delete the field from Firestore
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({'profilePic': FieldValue.delete()});
                      
                      // Reload profile data to reflect the deletion
                      await _loadProfileData();
                    }
                    Navigator.pop(context);
                  },
                ),
                _BottomSheetOption(
                  icon: Icons.add_a_photo_outlined,
                  title: 'Add New Picture',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndConfirmImage();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _primaryCream,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_accentGreen),
            strokeWidth: 3,
          ),
        ),
      );
    }
    if (_profileData == null) {
      return Scaffold(
        backgroundColor: _primaryCream,
        body: Center(
          child: Text(
            'No profile data found',
            style: TextStyle(
              fontSize: 18,
              color: _warmGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    final age = _calculateAge(_profileData!['dateOfBirth'] ?? '');
    final profileImageUrl = _profileImage != null
        ? _profileImage!.path
        : (_profileData!['profilePic']);

    return Scaffold(
      backgroundColor: _primaryCream,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                'Personal Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: _darkCharcoal,
                  letterSpacing: -0.5,
                ),
              ),
              backgroundColor: _primaryCream,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: _darkCharcoal),
            )
          : null,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  height: 320,
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _darkCharcoal,
                        _darkCharcoal.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      if (profileImageUrl != null && profileImageUrl.toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image(
                            key: ValueKey('patient_cover_${profileImageUrl}'),
                            image: _profileImage != null
                                ? FileImage(_profileImage!)
                                : NetworkImage(profileImageUrl.toString(), headers: {'Cache-Control': 'no-cache'})
                                    as ImageProvider,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.account_circle_outlined,
                                  size: 120,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              );
                            },
                          ),
                        ),
                      if (profileImageUrl == null || profileImageUrl.toString().isEmpty)
                        Center(
                          child: Icon(
                            Icons.account_circle_outlined,
                            size: 120,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profileData!['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profileData!['email'] ?? 'No Email',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 24,
                        right: 24,
                        child: GestureDetector(
                          onTap: _showProfilePictureOptions,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              key: ValueKey('patient_profile_card_${profileImageUrl ?? 'no_pic'}'),
                              radius: 37,
                              backgroundColor: Colors.white,
                              backgroundImage: (profileImageUrl != null && profileImageUrl.toString().isNotEmpty)
                                  ? (_profileImage != null
                                          ? FileImage(_profileImage!)
                                          : NetworkImage(profileImageUrl.toString(), headers: {'Cache-Control': 'no-cache'}))
                                      as ImageProvider
                                  : null,
                              child: (profileImageUrl == null || profileImageUrl.toString().isEmpty)
                                  ? Icon(Icons.add_a_photo_outlined,
                                      size: 32, color: _warmGray)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  _EnhancedInfoCard(
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                    children: [
                      _EnhancedInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value:
                              _profileData!['phoneNumber'] ?? 'Not provided'),
                      _EnhancedInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: _profileData!['address'] ?? 'Not provided'),
                      _EnhancedInfoRow(
                          icon: Icons.cake_outlined,
                          label: 'Date of Birth',
                          value:
                              _profileData!['dateOfBirth'] ?? 'Not provided'),
                      if (age != null)
                        _EnhancedInfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Age',
                            value: '$age years old'),
                      _EnhancedInfoRow(
                          icon: Icons.wc_outlined,
                          label: 'Gender',
                          value: _profileData!['gender'] ?? 'Not provided'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _EnhancedInfoCard(
                    title: 'Emergency Contacts',
                    icon: Icons.emergency_outlined,
                    children: [
                      _EmergencyContactsDisplay(profileData: _profileData),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _EnhancedInfoCard(
                    title: 'Medical Information',
                    icon: Icons.medical_services_outlined,
                    children: [
                      _EnhancedMedicalConditionsDisplay(
                          profileData: _profileData),
                    ],
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ],
          ),
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

class _EnhancedInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _EnhancedInfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        ProfileDisplayScreenState._accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: ProfileDisplayScreenState._accentGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: ProfileDisplayScreenState._darkCharcoal,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _EnhancedInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _EnhancedInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: ProfileDisplayScreenState._warmGray,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ProfileDisplayScreenState._warmGray,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ProfileDisplayScreenState._darkCharcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedMedicalConditionsDisplay extends StatelessWidget {
  final Map<String, dynamic>? profileData;

  const _EnhancedMedicalConditionsDisplay({required this.profileData});

  @override
  Widget build(BuildContext context) {
    final conditions =
        profileData?['medicalConditions'] as List<dynamic>? ?? [];
    final additionalConditions =
        profileData?['additionalConditions'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (conditions.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.local_hospital_outlined,
                size: 20,
                color: ProfileDisplayScreenState._warmGray,
              ),
              const SizedBox(width: 12),
              Text(
                'Selected Conditions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ProfileDisplayScreenState._warmGray,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: conditions.map((condition) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      ProfileDisplayScreenState._accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        ProfileDisplayScreenState._accentGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  condition.toString(),
                  style: const TextStyle(
                    color: ProfileDisplayScreenState._darkCharcoal,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (additionalConditions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.note_outlined,
                size: 20,
                color: ProfileDisplayScreenState._warmGray,
              ),
              const SizedBox(width: 12),
              Text(
                'Additional Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ProfileDisplayScreenState._warmGray,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProfileDisplayScreenState._lightGray,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ProfileDisplayScreenState._mediumGray,
                width: 1,
              ),
            ),
            child: Text(
              additionalConditions,
              style: const TextStyle(
                color: ProfileDisplayScreenState._darkCharcoal,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
        if (conditions.isEmpty && additionalConditions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ProfileDisplayScreenState._lightGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 48,
                  color: ProfileDisplayScreenState._warmGray.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No medical conditions recorded',
                  style: TextStyle(
                    color: ProfileDisplayScreenState._warmGray,
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
}

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _BottomSheetOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : ProfileDisplayScreenState._accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive
              ? Colors.red
              : ProfileDisplayScreenState._accentGreen,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? Colors.red
              : ProfileDisplayScreenState._darkCharcoal,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

class _EmergencyContactsDisplay extends StatelessWidget {
  final Map<String, dynamic>? profileData;

  const _EmergencyContactsDisplay({required this.profileData});

  @override
  Widget build(BuildContext context) {
    final emergencyContacts =
        profileData?['emergencyContacts'] as List<dynamic>? ?? [];

    if (emergencyContacts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ProfileDisplayScreenState._lightGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.contact_emergency_outlined,
              size: 48,
              color: ProfileDisplayScreenState._warmGray.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No emergency contacts added',
              style: TextStyle(
                color: ProfileDisplayScreenState._warmGray,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: emergencyContacts.map((contact) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: ProfileDisplayScreenState._darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact['relationship'] ?? 'No relationship specified',
                      style: TextStyle(
                        fontSize: 14,
                        color: ProfileDisplayScreenState._warmGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact['phone'] ?? 'No phone number',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: ProfileDisplayScreenState._darkCharcoal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // Add call functionality here
                },
                icon: Icon(
                  Icons.call_outlined,
                  color: ProfileDisplayScreenState._accentGreen,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

extension ProfileDisplayScreenState on _ProfileDisplayScreenState {
  static const Color _darkCharcoal = Color(0xFF2C2C2C);
  static const Color _warmGray = Color(0xFF6B6B6B);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _mediumGray = Color(0xFFE5E5E5);
}
