import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcon30/doctor/modules/consultation/consultation_requests_screen.dart';
import 'package:medcon30/doctor/modules/consultation/patient_request_history.dart';
import 'package:medcon30/doctor/modules/notifications/doctor_notifications_screen.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcon30/doctor/modules/patients_screen.dart';
import 'package:medcon30/doctor/modules/analytics_dashboard_screen.dart';
import 'package:medcon30/doctor/profile/profile_display.dart';
import 'package:medcon30/doctor/profile/profile_creation.dart';
import 'package:medcon30/doctor/profile/edit_profile.dart';
import 'package:medcon30/services/auth_service.dart';
import 'package:medcon30/splash_screen.dart';

class DoctorDashboard extends ConsumerStatefulWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> {
  int _currentIndex = 1;
  bool _isLoading = true;
  String? _doctorName;
  String? _specialization;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
    _fetchDoctorProfile();
  }

  Future<void> _checkUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDoctorProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();
      final data = doc.data();
      print(
          'Fetched doctor profile data: ${data != null ? data.toString() : 'null'}');
      if (data != null) {
        setState(() {
          _doctorName = (data['name'] as String?)?.trim();
          if (_doctorName == null || _doctorName!.isEmpty) {
            _doctorName = (data['fullName'] as String?)?.trim();
          }
          if (_doctorName == null || _doctorName!.isEmpty) {
            _doctorName = 'Doctor';
          }
          _specialization = (data['specializations'] is List &&
                  (data['specializations'] as List).isNotEmpty)
              ? (data['specializations'] as List).join(', ')
              : (data['specialization'] as String?) ?? 'Specialist';
          // Ensure empty strings are treated as null
          final picUrl = (data['profilePic'] as String?)?.trim();
          _profileImageUrl = (picUrl != null && picUrl.isNotEmpty) ? picUrl : null;
        });
      }
    } catch (e) {
      print('Error fetching doctor profile: $e');
      // ignore error, fallback to default UI
    }
  }

  Widget _getScreenForIndex(int index) {
    return _screens[index];
  }

  List<Widget> get _screens => [
    const _PatientsScreen(),
    _DashboardContent(onTabChange: _handleTabChange),
    const _ProfileScreen(),
  ];

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final themeProvider = provider_pkg.Provider.of<ThemeProvider>(context);
    final scaffoldKey = GlobalKey<ScaffoldState>();
    // Doctor profile info for sidebar (hardcoded for now, can fetch from Firestore)
    // final String doctorName = 'Dr. John Smith';
    // final String specialization = 'Cardiologist';
    // final String? profileImageUrl =
    //     null; // Replace with real image URL if available

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDarkMode ? Colors.grey[900] : const Color(0xFFF5F5F5),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        key: scaffoldKey,
        extendBody: true,
        backgroundColor:
            isDarkMode ? Colors.grey[900] : const Color(0xFFF5F5F5),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF0288D1)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text('Doctor Dashboard'),
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          surfaceTintColor: isDarkMode ? Colors.grey[850] : Colors.white,
          scrolledUnderElevation: 0,
          foregroundColor: const Color(0xFF0288D1),
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final all = snapshot.data?.docs ?? const [];
                final unread = all.where((d) => !(d.data()['read'] == true)).length;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications,
                          color: isDarkMode ? Colors.white : const Color(0xFF0288D1)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DoctorNotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: isDarkMode ? const Color(0xFF23272F) : Colors.white,
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Profile Card/Header
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 2;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 16),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode ? const Color(0xFF23272F) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.18)
                              : Colors.grey.withOpacity(0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseAuth.instance.currentUser == null
                          ? null
                          : FirebaseFirestore.instance
                              .collection('doctors')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .snapshots(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data();
                        final name = (data != null
                                ? (data['name'] ?? data['fullName'])
                                : _doctorName) ??
                            'Doctor';
                        final spec = (data != null
                                ? (data['specializations'] is List &&
                                        (data['specializations'] as List)
                                            .isNotEmpty
                                    ? (data['specializations'] as List)
                                        .join(', ')
                                    : (data['specialization'] ?? 'Specialist'))
                                : (_specialization ?? 'Specialist'))
                            .toString();
                        final pic = (data != null
                                ? (data['profilePic'] as String?)
                                : _profileImageUrl)
                            ?.trim();
                        
                        // Ensure empty strings are treated as null
                        final profilePic = (pic != null && pic.isNotEmpty) ? pic : null;

                        return Row(
                          children: [
                            CircleAvatar(
                              key: ValueKey('doctor_profile_${profilePic ?? 'no_pic'}'),
                              radius: 32,
                              backgroundColor: isDarkMode
                                  ? Colors.grey[800]
                                  : const Color(0xFFE3F2FD),
                              backgroundImage: profilePic != null
                                  ? NetworkImage(profilePic, headers: {'Cache-Control': 'no-cache'})
                                  : null,
                              child: profilePic == null
                                  ? Icon(
                                      Icons.account_circle,
                                      size: 48,
                                      color: isDarkMode
                                          ? Colors.white54
                                          : const Color(0xFF0288D1),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : const Color(0xFF0288D1),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    spec,
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.blue[200]
                                          : Colors.blueGrey[400],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.grey, size: 28),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                // --- Main Navigation ---
                ListTile(
                  leading: const Icon(Icons.home_rounded, color: Colors.blue),
                  title: const Text('Dashboard'),
                  onTap: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_outline, color: Colors.blue),
                  title: const Text('Patients'),
                  onTap: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                  title: const Text('Consultation Requests'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ConsultationRequestsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.bar_chart_outlined, color: Colors.blue),
                  title: const Text('Analytics'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AnalyticsDashboardScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: const Text('Schedule'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement schedule page
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Schedule'),
                        content: const Text('Schedule page coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                // --- Settings Section (short) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 0, 4),
                  child: Text('Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDarkMode ? Colors.white70 : Colors.black54)),
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit Profile'),
                  onTap: () async {
                    Navigator.pop(context);
                    // Load current profile data and navigate to edit screen
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final doc = await FirebaseFirestore.instance
                            .collection('doctors')
                            .doc(user.uid)
                            .get();

                        if (doc.exists) {
                          final data = doc.data()!;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorEditProfileScreen(
                                profileData: {
                                  'name': data['name'] ?? '',
                                  'email': data['email'] ?? '',
                                  'phoneNumber': data['phoneNumber'] ?? '',
                                  'licenseNumber': data['licenseNumber'] ?? '',
                                  'education': data['education'] ?? [],
                                  'specializations':
                                      data['specializations'] ?? [],
                                  'dateOfBirth': data['dateOfBirth'] ?? '',
                                  'gender': data['gender'] ?? 'Male',
                                  'experience': data['experience'] ?? [],
                                  'profilePic': data['profilePic'],
                                },
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Profile not found. Please create a profile first.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error loading profile: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.blue),
                  title: const Text('Change Password'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Change Password'),
                        content:
                            const Text('Password change screen coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? Colors.blueGrey[800]
                          : const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size.fromHeight(36),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              DoctorSettingsPage(isDarkMode: isDarkMode),
                        ),
                      );
                    },
                    child: const Text('View Complete Settings'),
                  ),
                ),
                const Divider(),
                // --- Theme Switch ---
                StatefulBuilder(
                  builder: (context, setDrawerState) {
                    return SwitchListTile(
                      secondary:
                          Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                      title: const Text('Dark Mode'),
                      value: isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                        setDrawerState(() {});
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title:
                      const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                    if (shouldLogout == true) {
                      try {
                        await AuthService().signOut();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const SplashScreen()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error logging out: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        body: _getScreenForIndex(_currentIndex),
        bottomNavigationBar: AnimatedCurveNavBar(
          onTabChanged: _handleTabChange,
          initialIndex: _currentIndex,
          items: const [
            NavBarItem(
              icon: Icons.people_outline,
              label: "Patients",
              highlightColor: Color(0xFF0288D1),
            ),
            NavBarItem(
              icon: Icons.home_rounded,
              label: "Home",
              highlightColor: Color(0xFF0288D1),
            ),
            NavBarItem(
              icon: Icons.person_outline,
              label: "Profile",
              highlightColor: Color(0xFF0288D1),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final Function(int) onTabChange;
  const _DashboardContent({required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0288D1), Color(0xFF01579B)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back, Doctor!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'How can we help you today?',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.medical_services, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Your patients are waiting',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('consultation_requests')
                  .where('doctorId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('status', isEqualTo: 'Pending')
                  .snapshots(),
              builder: (context, snapshot) {
                final pending = snapshot.data?.docs.length ?? 0;
                final desc = pending > 0
                    ? '$pending new request${pending == 1 ? '' : 's'} pending'
                    : 'No new requests';
                return _DashboardOption(
                  title: 'Consultation Requests',
                  description: desc,
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFF0288D1),
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ConsultationRequestsScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            _DashboardOption(
              title: 'Medical Analytics',
              description: 'View patient insights and trends',
              icon: Icons.bar_chart_outlined,
              iconColor: const Color(0xFF0288D1),
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsDashboardScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _RecentPatientsCard(onTabChange: onTabChange),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _PatientsScreen extends StatelessWidget {
  const _PatientsScreen();

  @override
  Widget build(BuildContext context) {
    return const PatientsScreen();
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    return const _DoctorProfileGateScreen();
  }
}

class _DoctorProfileGateScreen extends StatefulWidget {
  const _DoctorProfileGateScreen({Key? key}) : super(key: key);

  @override
  State<_DoctorProfileGateScreen> createState() =>
      _DoctorProfileGateScreenState();
}

class _DoctorProfileGateScreenState extends State<_DoctorProfileGateScreen> {
  bool _isLoading = true;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _hasProfile = false;
      });
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(user.uid)
        .get();
    final data = doc.data();
    bool hasProfile = false;
    if (doc.exists && data != null) {
      // Defensive: treat education and experience as lists
      final education = data['education'];
      final dob = data['dateOfBirth'] ?? '';
      final gender = data['gender'] ?? '';
      final hasEducation = education is List
          ? education.isNotEmpty
          : (education is String ? education.trim().isNotEmpty : false);
      if (hasEducation &&
          dob.toString().trim().isNotEmpty &&
          gender.toString().trim().isNotEmpty) {
        hasProfile = true;
      }
    }
    setState(() {
      _isLoading = false;
      _hasProfile = hasProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasProfile) {
      return const DoctorProfileDisplayScreen();
    } else {
      return const DoctorProfileCreationScreen();
    }
  }
}

class _DashboardOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isDarkMode;
  final VoidCallback? onTap;

  const _DashboardOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.isDarkMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Removed old schedule card and item widgets since the schedule section
// is no longer displayed on the dashboard.

class NavBarItem {
  final IconData icon;
  final String label;
  final Color highlightColor;

  const NavBarItem({
    required this.icon,
    required this.label,
    required this.highlightColor,
  });
}

class AnimatedCurveNavBar extends StatefulWidget {
  final Function(int) onTabChanged;
  final int initialIndex;
  final List<NavBarItem> items;

  const AnimatedCurveNavBar({
    super.key,
    required this.onTabChanged,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  State<AnimatedCurveNavBar> createState() => _AnimatedCurveNavBarState();
}

class _AnimatedCurveNavBarState extends State<AnimatedCurveNavBar>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _positionAnimation = Tween<double>(
      begin: _getPositionForIndex(_selectedIndex),
      end: _getPositionForIndex(_selectedIndex),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _getPositionForIndex(int index) {
    final count = widget.items.length;
    const width = 1.0;
    final itemWidth = width / count;
    return itemWidth * (index + 0.5);
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    _positionAnimation = Tween<double>(
      begin: _positionAnimation.value,
      end: _getPositionForIndex(index),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0.0);

    setState(() {
      _selectedIndex = index;
    });

    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _positionAnimation,
      builder: (context, _) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background with curve
              Positioned.fill(
                child: CustomPaint(
                  painter: CurveNavBarPainter(
                    position: _positionAnimation.value,
                    backgroundColor: const Color(0xFF0288D1),
                  ),
                ),
              ),

              // Tab items (with selected item hidden)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(widget.items.length, (index) {
                    final item = widget.items[index];
                    final isSelected = index == _selectedIndex;

                    return SizedBox(
                      width: 80,
                      child: !isSelected
                          ? GestureDetector(
                              onTap: () => _onTabTapped(index),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.icon,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(height: 24),
                    );
                  }),
                ),
              ),

              // Floating selected item button
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment(2 * _positionAnimation.value - 1, 0),
                  child: GestureDetector(
                    onTap: () => _onTabTapped(_selectedIndex),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.items[_selectedIndex].icon,
                        color: const Color(0xFF0288D1),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CurveNavBarPainter extends CustomPainter {
  final double position;
  final Color backgroundColor;

  CurveNavBarPainter({required this.position, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final centerX = size.width * position;
    const curveWidth = 70.0;
    const curveHeight = 20.0;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(centerX - curveWidth / 2, 0);
    path.quadraticBezierTo(centerX, curveHeight, centerX + curveWidth / 2, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CurveNavBarPainter oldDelegate) {
    return position != oldDelegate.position ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

class _RecentPatientsCard extends StatelessWidget {
  final Function(int) onTabChange;
  const _RecentPatientsCard({required this.onTabChange});
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Patients",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: () {
                  onTabChange(0); // Switch to Patients tab (index 0)
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF0288D1),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('consultation_requests')
                .where('doctorId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text(
                  'Failed to load recent patients',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              // Map to list and sort by createdAt desc (fallback safe)
              final List<Map<String, dynamic>> items =
                  docs.map((d) => {'id': d.id, ...d.data()}).toList();
              items.sort((a, b) {
                final ta = a['createdAt'];
                final tb = b['createdAt'];
                if (ta is Timestamp && tb is Timestamp) {
                  return tb.compareTo(ta);
                }
                return 0;
              });
              // Keep only the most recent request per distinct patient
              final Set<String> seenPatientIds = {};
              final List<Map<String, dynamic>> uniquePatients = [];
              for (final m in items) {
                final String pid = (m['patientId'] ?? '').toString();
                if (pid.isEmpty) continue;
                if (seenPatientIds.contains(pid)) continue;
                seenPatientIds.add(pid);
                uniquePatients.add(m);
                if (uniquePatients.length >= 3) break;
              }

              final top = uniquePatients;

              if (top.isEmpty) {
                return Text(
                  'No recent requests',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54),
                );
              }

              int _calcAge(dynamic dobOrAge) {
                if (dobOrAge == null) return 0;
                // If explicit age provided
                if (dobOrAge is num && dobOrAge > 0) {
                  return dobOrAge.toInt();
                }
                
                DateTime? dob;
                
                if (dobOrAge is Timestamp) {
                  dob = dobOrAge.toDate();
                } else if (dobOrAge is String) {
                  final trimmed = dobOrAge.trim();
                  final asNum = int.tryParse(trimmed);
                  if (asNum != null && asNum > 0) return asNum;
                  
                  // Try parsing date string - DD/MM/YYYY format (same as profile page)
                  if (trimmed.contains('/')) {
                    final parts = trimmed.split('/');
                    if (parts.length == 3) {
                      try {
                        final day = int.parse(parts[0]);
                        final month = int.parse(parts[1]);
                        final year = int.parse(parts[2]);
                        // Parse as DD/MM/YYYY (standard format used in the app)
                        dob = DateTime(year, month, day);
                      } catch (_) {
                        // If parsing fails, try alternative formats below
                      }
                    }
                  }
                  
                  // If still not parsed, try ISO format or other parseable formats
                  dob ??= DateTime.tryParse(trimmed);
                  
                  // Last resort: Try YYYY/MM/DD format
                  if (dob == null && trimmed.contains('/')) {
                    final p = trimmed.split('/');
                    if (p.length == 3) {
                      final y = int.tryParse(p[0]);
                      final mth = int.tryParse(p[1]);
                      final d = int.tryParse(p[2]);
                      if (y != null && mth != null && d != null) {
                        dob = DateTime(y, mth, d);
                      }
                    }
                  }
                }
                
                // Calculate age from DateTime
                if (dob != null) {
                  final now = DateTime.now();
                  int years = now.year - dob.year;
                  if (now.month < dob.month ||
                      (now.month == dob.month && now.day < dob.day)) {
                    years -= 1;
                  }
                  if (years > 0 && years < 150) {
                    return years;
                  }
                }
                
                return 0;
              }

              return Column(
                children: top.map((m) {
                  final name = (m['patientName'] ?? 'Patient').toString();
                  final patientId = (m['patientId'] ?? '').toString();
                  final String? cachedGender = (m['patientGender'] as String?);
                  // Calculate age - prefer user profile DOB first (most authoritative)
                  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: patientId.isNotEmpty
                        ? FirebaseFirestore.instance.collection('users').doc(patientId).get()
                        : null,
                    builder: (context, userSnapshot) {
                      // Show loader while fetching profile picture
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDarkMode 
                                        ? Colors.white54 
                                        : const Color(0xFF0288D1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: isDarkMode ? Colors.white : null,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Loading...',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDarkMode 
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
                      
                      final userData = userSnapshot.data?.data() ?? <String, dynamic>{};
                      
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
                      print('🔍 Recent Patients - Patient: $name, Has profilePic field: ${userData.containsKey('profilePic')}, Value: ${userData['profilePic']}, Using: $profilePicUrl');
                      
                      // Get gender
                      String gender = (userData['gender'] ?? 
                              userData['sex'] ?? 
                              cachedGender ?? 
                              '')
                          .toString();
                      if (gender.isNotEmpty) {
                        gender = gender.substring(0, 1).toUpperCase() + gender.substring(1).toLowerCase();
                      }
                      
                      // Calculate age: prioritize user profile DOB, then request DOB, then explicit age
                      int finalAge = 0;
                      // First try user profile DOB (most authoritative)
                      final dynamic userDob = userData['dateOfBirth'] ??
                          userData['dob'] ??
                          userData['DOB'] ??
                          userData['patientDateOfBirth'] ??
                          userData['patientDob'];
                      finalAge = _calcAge(userDob);
                      
                      // If no user profile DOB, try request DOB
                      if (finalAge == 0) {
                        final dynamic dobField =
                            m['patientDateOfBirth'] ??
                            m['dateOfBirth'] ??
                            m['patientDob'] ??
                            m['dob'] ??
                            m['DOB'];
                        finalAge = _calcAge(dobField);
                      }
                      
                      // Last resort: explicit age fields
                      if (finalAge == 0) {
                        finalAge = _calcAge(userData['age']);
                      }
                      if (finalAge == 0) {
                        finalAge = _calcAge(m['patientAge'] ?? m['age']);
                      }
                      
                      return _RecentPatientItem(
                        name: name,
                        age: finalAge,
                        gender: gender.isNotEmpty ? gender : '—',
                        profilePicUrl: profilePicUrl,
                        patientId: patientId,
                        patientName: name,
                        isDarkMode: isDarkMode,
                        onView: () {
                          if (patientId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientRequestHistoryScreen(
                                  doctorId: FirebaseAuth.instance.currentUser?.uid ?? '',
                                  patientId: patientId,
                                  patientName: name,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentPatientItem extends StatelessWidget {
  final String name;
  final int age;
  final String gender;
  final String? profilePicUrl;
  final String patientId;
  final String patientName;
  final bool isDarkMode;
  final VoidCallback onView;
  const _RecentPatientItem({
    required this.name,
    required this.age,
    required this.gender,
    this.profilePicUrl,
    required this.patientId,
    required this.patientName,
    required this.isDarkMode,
    required this.onView,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          // Use conditional rendering to ensure proper rebuild
          profilePicUrl != null && profilePicUrl!.trim().isNotEmpty
              ? CircleAvatar(
                  key: ValueKey('recent_patient_${profilePicUrl}_${DateTime.now().millisecondsSinceEpoch}'),
                  radius: 22,
                  backgroundColor:
                      isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
                  backgroundImage: NetworkImage(
                    profilePicUrl!,
                    headers: {'Cache-Control': 'no-cache'},
                  ),
                  onBackgroundImageError: (exception, stackTrace) {
                    // If image fails to load, clear cache and rebuild
                    NetworkImage(profilePicUrl!).evict();
                  },
                )
              : CircleAvatar(
                  key: ValueKey('recent_patient_no_pic_${DateTime.now().millisecondsSinceEpoch}'),
                  radius: 22,
                  backgroundColor:
                      isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
                  child: Icon(
                    Icons.person,
                    color: isDarkMode ? Colors.white : const Color(0xFF0288D1),
                    size: 28,
                  ),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDarkMode ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$age years • $gender',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onView,
            child: const Text(
              'View',
              style: TextStyle(
                color: Color(0xFF0288D1),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorSettingsPage extends StatelessWidget {
  final bool isDarkMode;
  const DoctorSettingsPage({Key? key, required this.isDarkMode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF23272F) : Colors.white;
    final sectionHeaderStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: isDarkMode ? Colors.white70 : Colors.black87,
      letterSpacing: 0.2,
    );
    final dividerColor = isDarkMode ? Colors.white12 : Colors.grey[200];
    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF181A20) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF23272F) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF0288D1),
        title: const Text('Settings'),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          // Profile Settings Section
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Profile Settings', style: sectionHeaderStyle),
          ),
          Card(
            color: cardColor,
            elevation: isDarkMode ? 0 : 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit Profile'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.blue),
                  title: const Text('Change Password'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Change Password'),
                        content:
                            const Text('Password change screen coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading:
                      const Icon(Icons.medical_services, color: Colors.blue),
                  title: const Text('Manage Specializations'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Specializations'),
                        content: const Text(
                            'Specialization management coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Account'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Account'),
                        content: const Text(
                            'Are you sure you want to delete your account? This action cannot be undone.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)))
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // App Settings Section
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('App Settings', style: sectionHeaderStyle),
          ),
          Card(
            color: cardColor,
            elevation: isDarkMode ? 0 : 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blue),
                  title: const Text('Language Selection'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Language Selection'),
                        content: const Text('Language selection coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.blue),
                  title: const Text('Notification Settings'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Notification Settings'),
                        content:
                            const Text('Notification settings coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.format_size, color: Colors.blue),
                  title: const Text('Theme & Font Size'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Theme & Font Size'),
                        content: const Text(
                            'Theme and font size options coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Colors.blue),
                  title: const Text('Privacy Settings'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Privacy Settings'),
                        content: const Text('Privacy settings coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.blue),
                  title: const Text('Data Export'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Data Export'),
                        content: const Text('Data export coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading:
                      const Icon(Icons.cleaning_services, color: Colors.blue),
                  title: const Text('Clear App Cache'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear App Cache'),
                        content: const Text('App cache cleared!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.accessibility, color: Colors.blue),
                  title: const Text('Accessibility Options'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Accessibility Options'),
                        content:
                            const Text('Accessibility options coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Emergency & Security Section
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Consultation & Security', style: sectionHeaderStyle),
          ),
          Card(
            color: cardColor,
            elevation: isDarkMode ? 0 : 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.schedule, color: Colors.red),
                  title: const Text('Consultation Preferences'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Consultation Preferences'),
                        content: const Text('Preferences coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.red),
                  title: const Text('Security Settings'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Security Settings'),
                        content: const Text('Security settings coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Support & Info Section
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Support & Info', style: sectionHeaderStyle),
          ),
          Card(
            color: cardColor,
            elevation: isDarkMode ? 0 : 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.support_agent, color: Colors.purple),
                  title: const Text('Help & Support'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Help & Support'),
                        content:
                            const Text('Contact support@medcon.com for help.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.orange),
                  title: const Text('App Version'),
                  subtitle: const Text('v1.0.0'),
                  onTap: () {},
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.article, color: Colors.orange),
                  title: const Text('Terms & Conditions'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Terms & Conditions'),
                        content:
                            const Text('Terms & Conditions content goes here.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Colors.orange),
                  title: const Text('Privacy Policy'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Privacy Policy'),
                        content:
                            const Text('Privacy Policy content goes here.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.orange),
                  title: const Text('About App'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('About App'),
                        content: const Text(
                            'MedCon v1.0.0\nDeveloped by Your Team.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.feedback, color: Colors.pink),
                  title: const Text('Send Feedback'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Send Feedback'),
                        content: const Text('Feedback form coming soon!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.star_rate, color: Colors.amber),
                  title: const Text('Rate Us'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Rate Us'),
                        content: const Text('Thank you for your feedback!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

