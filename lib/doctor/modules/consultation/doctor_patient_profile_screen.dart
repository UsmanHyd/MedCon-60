import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Shared styling constants to mirror patient ProfileDisplayScreen
const Color kPrimaryCream = Color(0xFFF8F6F0);
const Color kDarkCharcoal = Color(0xFF2C2C2C);
const Color kWarmGray = Color(0xFF6B6B6B);
const Color kAccentGreen = Color(0xFF10B981);
const Color kMediumGray = Color(0xFFE5E5E5);

class DoctorPatientProfileScreen extends StatefulWidget {
  final String patientId;
  const DoctorPatientProfileScreen({Key? key, required this.patientId})
      : super(key: key);

  @override
  State<DoctorPatientProfileScreen> createState() =>
      _DoctorPatientProfileScreenState();
}

class _DoctorPatientProfileScreenState
    extends State<DoctorPatientProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _showFullscreenCover = false;
  double _fullscreenDragStartY = 0.0;
  double _fullscreenDragDelta = 0.0;

  static const Color _primaryCream = kPrimaryCream;
  static const Color _darkCharcoal = kDarkCharcoal;
  static const Color _warmGray = kWarmGray;
  static const Color _accentGreen = kAccentGreen;
  // keep styling constants aligned (reserved for future use)

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .get();
      setState(() {
        _profileData = snap.data();
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _profileData = null;
      });
    }
  }

  int? _calculateAge(dynamic dobDyn) {
    try {
      DateTime? dob;
      if (dobDyn is Timestamp) {
        dob = dobDyn.toDate();
      } else if (dobDyn is String && dobDyn.trim().isNotEmpty) {
        final s = dobDyn.trim();
        DateTime? parsed;
        try {
          if (s.contains('/')) {
            final parts = s.split('/');
            if (parts.length == 3) {
              final a = int.tryParse(parts[0]);
              final b = int.tryParse(parts[1]);
              final c = int.tryParse(parts[2]);
              if (a != null && b != null && c != null) {
                parsed = DateTime(c, b, a);
                if (a <= 12 && b > 12) parsed = DateTime(c, a, b);
              }
            }
          }
        } catch (_) {}
        parsed ??= DateTime.tryParse(s);
        if (parsed == null && s.contains('/')) {
          final p = s.split('/');
          if (p.length == 3) {
            final y = int.tryParse(p[0]);
            final m = int.tryParse(p[1]);
            final d = int.tryParse(p[2]);
            if (y != null && m != null && d != null) parsed = DateTime(y, m, d);
          }
        }
        dob = parsed;
      }
      if (dob == null) return null;
      final now = DateTime.now();
      int years = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        years -= 1;
      }
      if (years >= 0 && years < 150) return years;
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _primaryCream,
        appBar: AppBar(
          title: const Text('Patient Profile'),
          backgroundColor: _primaryCream,
          elevation: 0,
          centerTitle: true,
        ),
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
        appBar: AppBar(
          title: const Text('Patient Profile'),
          backgroundColor: _primaryCream,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'Failed to load profile',
            style: TextStyle(
              fontSize: 18,
              color: _warmGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final profileImageUrl = _profileData!['profilePic'] as String?;
    final age = _calculateAge(_profileData!['dateOfBirth']);

    return Scaffold(
      backgroundColor: _primaryCream,
      appBar: AppBar(
        title: const Text('Personal Profile'),
        backgroundColor: _primaryCream,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _darkCharcoal),
      ),
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
                      if (profileImageUrl != null && profileImageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image(
                            image: NetworkImage(profileImageUrl),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      else
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
                              (_profileData!['name'] ?? 'No Name').toString(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (_profileData!['email'] ?? 'No Email').toString(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                              (_profileData!['phoneNumber'] ?? 'Not provided')
                                  .toString()),
                      _EnhancedInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: (_profileData!['address'] ?? 'Not provided')
                              .toString()),
                      _EnhancedInfoRow(
                          icon: Icons.cake_outlined,
                          label: 'Date of Birth',
                          value:
                              (_profileData!['dateOfBirth'] ?? 'Not provided')
                                  .toString()),
                      if (age != null)
                        _EnhancedInfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Age',
                            value: '$age years old'),
                      _EnhancedInfoRow(
                          icon: Icons.wc_outlined,
                          label: 'Gender',
                          value: (_profileData!['gender'] ?? 'Not provided')
                              .toString()),
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
                            image: NetworkImage(profileImageUrl),
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
                    color: kAccentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: kAccentGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: kDarkCharcoal,
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
            color: kWarmGray,
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
                    color: kWarmGray,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kDarkCharcoal,
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
                color: kWarmGray,
              ),
              const SizedBox(width: 12),
              Text(
                'Selected Conditions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kWarmGray,
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
                  color: kAccentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: kAccentGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  condition.toString(),
                  style: const TextStyle(
                    color: kDarkCharcoal,
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
                color: kWarmGray,
              ),
              const SizedBox(width: 12),
              Text(
                'Additional Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kWarmGray,
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
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kMediumGray,
                width: 1,
              ),
            ),
            child: Text(
              additionalConditions,
              style: const TextStyle(
                color: kDarkCharcoal,
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
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 48,
                  color: kWarmGray.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No medical conditions recorded',
                  style: TextStyle(
                    color: kWarmGray,
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
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.contact_emergency_outlined,
              size: 48,
              color: kWarmGray.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No emergency contacts added',
              style: TextStyle(
                color: kWarmGray,
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
                child: const Icon(
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
                      (contact['name'] ?? 'Unknown').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: kDarkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (contact['relationship'] ?? 'No relationship specified')
                          .toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: kWarmGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (contact['phone'] ?? 'No phone number').toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: kDarkCharcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
