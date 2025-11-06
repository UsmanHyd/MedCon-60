import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcon30/patient/modules/chatbot/chatbot.dart';
import 'package:medcon30/patient/modules/communities/community_groups.dart';
import 'package:medcon30/patient/modules/disease/disease_detection.dart';
import 'package:medcon30/patient/modules/heart/heart_disease.dart';
import 'package:medcon30/patient/modules/nutrition/nutrition_fitness.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import '../modules/stress/stress_monitoring.dart';
import 'package:medcon30/patient/modules/vaccine/vaccination_reminders.dart';
import 'package:medcon30/patient/modules/SOS/sos_messaging.dart';
import 'package:medcon30/patient/modules/app_history/app_history_screen.dart';
import 'package:medcon30/providers/app_history_provider.dart';
import 'package:medcon30/models/app_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcon30/patient/profile/profile_display.dart';
import 'package:medcon30/patient/profile/edit_profile.dart';
import 'package:medcon30/services/auth_service.dart';
import 'package:medcon30/splash_screen.dart';
import 'package:medcon30/patient/modules/disease/doctor_profile.dart';
import 'package:medcon30/patient/modules/disease/doctor_request_history.dart';
import 'package:medcon30/patient/modules/notifications/notifications_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 1;
  bool _showChatbot = false;
  bool _isLoading = true;
  String? _profileName;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
    _fetchProfileInfo();
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

  Future<void> _fetchProfileInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        String? name = (data['name'] as String?)?.trim();
        String? imageUrl = (data['profilePic'] as String?)?.trim();
        setState(() {
          _profileName = (name != null && name.isNotEmpty) ? name : 'No Name';
          _profileImageUrl =
              (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null;
        });
      }
    } catch (e) {
      // ignore error, fallback to default UI
    }
  }

  Widget _getScreenForIndex(int index) {
    return _screens[index];
  }

  final List<Widget> _screens = [
    const CommunityGroupsScreen(showAppBar: false),
    const _DashboardContent(),
    const _DoctorsScreen(),
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
        // Show confirmation dialog
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
          title: const Text('Patient Dashboard'),
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          foregroundColor: const Color(0xFF0288D1),
          elevation: 0.5,
          centerTitle: true,
          surfaceTintColor: isDarkMode ? Colors.grey[850] : Colors.white,
          scrolledUnderElevation: 0,
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
                            builder: (_) => const NotificationsScreen(),
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
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileDisplayScreen(),
                      ),
                    );
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
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .snapshots(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data();
                        final name = (data != null
                                ? (data['name'] as String?)
                                : _profileName) ??
                            'Patient';
                        
                        // Check if profilePic field exists and is not null/empty
                        String? pic;
                        if (data != null) {
                          // Check if the field exists in the document
                          if (data.containsKey('profilePic')) {
                            final profilePicValue = data['profilePic'];
                            // If field exists but is null or empty, treat as deleted
                            if (profilePicValue == null || profilePicValue.toString().trim().isEmpty) {
                              pic = null;
                            } else {
                              pic = profilePicValue.toString().trim();
                            }
                          } else {
                            // Field doesn't exist (was deleted), treat as null
                            pic = null;
                          }
                        } else {
                          pic = _profileImageUrl?.trim();
                        }
                        
                        // Ensure empty strings are treated as null
                        final profilePic = (pic != null && pic.isNotEmpty) ? pic : null;
                        
                        // Debug print
                        print('🔍 Patient Dashboard - ProfilePic value: $profilePic, Data has profilePic: ${data?.containsKey('profilePic')}, Data keys: ${data?.keys.toList()}');

                        return Row(
                          children: [
                            // Use conditional widget to completely rebuild when picture is deleted
                            profilePic != null
                                ? CircleAvatar(
                                    key: ValueKey('patient_profile_$profilePic'),
                                    radius: 32,
                                    backgroundColor: isDarkMode
                                        ? Colors.grey[800]
                                        : const Color(0xFFE3F2FD),
                                    backgroundImage: NetworkImage(
                                      profilePic, 
                                      headers: {'Cache-Control': 'no-cache'}
                                    ),
                                  )
                                : CircleAvatar(
                                    key: ValueKey('patient_profile_no_pic'),
                                    radius: 32,
                                    backgroundColor: isDarkMode
                                        ? Colors.grey[800]
                                        : const Color(0xFFE3F2FD),
                                    child: Icon(
                                      Icons.account_circle,
                                      size: 48,
                                      color: isDarkMode
                                          ? Colors.white54
                                          : const Color(0xFF0288D1),
                                    ),
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
                                    'View Profile',
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
                // --- Settings Section ---
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
                    // Get current user profile data
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      try {
                        final doc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get();
                        if (doc.exists) {
                          final profileData = doc.data()!;
                          print(
                              'Patient Dashboard - Profile data being passed: $profileData');
                          print(
                              'Patient Dashboard - Name field: ${profileData['name']}');

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                profileData: profileData,
                              ),
                            ),
                          );

                          // If profile was updated, refresh the profile data
                          if (result == true) {
                            _fetchProfileInfo();
                          }
                        } else {
                          // If no profile exists, show error
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Profile not found. Please create a profile first.'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error loading profile: $e'),
                          ),
                        );
                      }
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
                              SettingsPage(isDarkMode: isDarkMode),
                        ),
                      );
                    },
                    child: const Text('View Complete Settings'),
                  ),
                ),
                const Divider(),
                // --- App History Section ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 0, 4),
                  child: Text('App History',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDarkMode ? Colors.white70 : Colors.black54)),
                ),
                // Recent App History Items (2-3 items)
                Consumer(
                  builder: (context, ref, child) {
                    final appHistoryState = ref.watch(appHistoryProvider);
                    return appHistoryState.when(
                      data: (activities) {
                        // Sort by timestamp descending (newest first) to ensure most recent
                        final sortedActivities = List<AppHistoryActivity>.from(activities)
                          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                        final recentActivities = sortedActivities.take(3).toList();
                        if (recentActivities.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              'No recent activities',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: recentActivities.map((activity) {
                            return _buildHistoryListTile(
                              context,
                              activity,
                              isDarkMode,
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, stack) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'Error loading history',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppHistoryScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
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
                        setDrawerState(() {}); // Redraw the drawer in new theme
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
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _getScreenForIndex(_currentIndex),
            ),
            if (_showChatbot)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 80, // Space above bottom navbar
                child: ChatbotScreen(
                  onClose: () {
                    setState(() {
                      _showChatbot = false;
                    });
                  },
                ),
              ),
          ],
        ),
        bottomNavigationBar: AnimatedCurveNavBar(
          onTabChanged: _handleTabChange,
          initialIndex: _currentIndex,
          items: const [
            NavBarItem(
              icon: Icons.group,
              label: "Groups",
              highlightColor: Color(0xFF0288D1),
            ),
            NavBarItem(
              icon: Icons.home,
              label: "Home",
              highlightColor: Color(0xFF0288D1),
            ),
            NavBarItem(
              icon: Icons.medical_services,
              label: "Doctors",
              highlightColor: Color(0xFF0288D1),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _showChatbot = true;
              });
            },
            backgroundColor: const Color(0xFF0288D1),
            tooltip: 'Open Chatbot',
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // Helper method to build history list tile
  Widget _buildHistoryListTile(
    BuildContext context,
    AppHistoryActivity activity,
    bool isDarkMode,
  ) {
    IconData icon;
    Color iconColor;

    switch (activity.type) {
      case ActivityType.diseaseDetection:
        icon = Icons.local_hospital;
        iconColor = const Color(0xFF4CAF50);
        break;
      case ActivityType.vaccineReminder:
        icon = Icons.vaccines;
        iconColor = Colors.teal;
        break;
      case ActivityType.stressMonitoring:
        icon = Icons.psychology;
        iconColor = Colors.deepPurple;
        break;
      case ActivityType.heartDiseaseDetection:
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case ActivityType.nutritionFitness:
        icon = Icons.fitness_center;
        iconColor = Colors.green;
        break;
      case ActivityType.sosMessage:
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.red;
        break;
      case ActivityType.consultationRequest:
        icon = Icons.medical_services;
        iconColor = const Color(0xFF0288D1);
        break;
      case ActivityType.profileUpdate:
        icon = Icons.person;
        iconColor = Colors.blue;
        break;
      case ActivityType.chatbotInteraction:
        icon = Icons.chat_bubble;
        iconColor = Colors.purple;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        activity.title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        activity.timeAgo,
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black54,
          fontSize: 12,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AppHistoryScreen(),
          ),
        );
      },
    );
  }
}

class _DoctorsScreen extends StatelessWidget {
  const _DoctorsScreen();

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Doctors',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Doctors you have contacted and accepted your request',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic list of accepted doctors contacted by the patient
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('consultation_requests')
                    .where('patientId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .where('status', isEqualTo: 'Accepted')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load doctors',
                        style: TextStyle(
                            color:
                                isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  // Deduplicate by doctorId (keep latest)
                  final Map<String, Map<String, dynamic>> byDoctor = {};
                  for (final d in docs) {
                    final data = {'id': d.id, ...d.data()};
                    final String? doctorId = data['doctorId'] as String?;
                    if (doctorId == null || doctorId.isEmpty) continue;
                    byDoctor.putIfAbsent(doctorId, () => data);
                  }
                  final items = byDoctor.values.toList();
                  // Sort by createdAt desc locally to avoid composite index
                  items.sort((a, b) {
                    final ta = a['createdAt'];
                    final tb = b['createdAt'];
                    if (ta is Timestamp && tb is Timestamp) {
                      return tb.compareTo(ta);
                    }
                    return 0;
                  });
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No accepted doctors yet',
                        style: TextStyle(
                            color:
                                isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final String doctorName =
                          (item['doctorName'] ?? 'Doctor').toString();
                      final String specialization =
                          (item['doctorSpecialty'] ?? '').toString();
                      final String doctorId =
                          (item['doctorId'] ?? '').toString();

                      // Use StreamBuilder to get current doctor profile from doctors collection
                      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: doctorId.isNotEmpty
                            ? FirebaseFirestore.instance
                                .collection('doctors')
                                .doc(doctorId)
                                .snapshots()
                            : null,
                        builder: (context, doctorSnapshot) {
                          // Get current doctor data from doctors collection
                          final doctorData = doctorSnapshot.data?.data() ?? <String, dynamic>{};
                          
                          // Get profile picture from doctors collection (most up-to-date)
                          final String? currentImageUrl = (doctorData['profilePic'] ??
                                  doctorData['photoUrl'] ??
                                  doctorData['avatarUrl'])
                              ?.toString();
                          
                          // Only use imageUrl if it's not empty/null
                          final String? imageUrl = (currentImageUrl != null && 
                                  currentImageUrl.isNotEmpty)
                              ? currentImageUrl
                              : null;
                          
                          // Use current doctor name/specialization if available, otherwise fallback to cached
                          final String displayName = (doctorData['name'] ?? 
                                  doctorData['fullName'] ?? 
                                  doctorName)
                              .toString();
                          final String displaySpecialization = (doctorData['specialization'] ??
                                  doctorData['specialty'] ??
                                  specialization)
                              .toString();

                          return _DoctorCard(
                            name: displayName,
                            specialization: displaySpecialization.isNotEmpty
                                ? displaySpecialization
                                : 'Doctor',
                            imageUrl: imageUrl,
                            isDarkMode: isDarkMode,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DoctorProfileScreen(
                                    doctorId: doctorId,
                                  ),
                                ),
                              );
                            },
                            onChat: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Chat coming soon'),
                                ),
                              );
                            },
                            onHistory: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DoctorRequestHistoryScreen(
                                    doctorId: doctorId,
                                    doctorName: displayName,
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
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final String name;
  final String specialization;
  final String? imageUrl;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback onChat;
  final VoidCallback onHistory;

  const _DoctorCard({
    required this.name,
    required this.specialization,
    this.imageUrl,
    required this.isDarkMode,
    required this.onTap,
    required this.onChat,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor:
                  isDarkMode ? Colors.grey[800] : const Color(0xFFE6F3FF),
              backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? NetworkImage(imageUrl!)
                  : null,
              child: (imageUrl == null || imageUrl!.isEmpty)
                  ? Icon(
                      Icons.person,
                      color: isDarkMode ? Colors.white54 : const Color(0xFF0288D1),
                      size: 28,
                    )
                  : null,
            ),
            title: Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            subtitle: Text(
              specialization,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF0288D1).withOpacity(isDarkMode ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_ios,
                  color: Color(0xFF0288D1), size: 16),
            ),
            onTap: onTap,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
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
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

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
                    'Welcome back!',
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
                          'Your health is our priority',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _DashboardOption(
              title: 'Disease Detection',
              description: 'Get instant analysis of your symptoms',
              icon: Icons.local_hospital,
              iconColor: const Color(0xFF0288D1),
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DiseaseDetectionScreen(),
                  ),
                );
              },
            ),
            _DashboardOption(
              title: 'Stress Monitoring',
              description: 'Track and manage your stress levels',
              icon: Icons.accessibility_new,
              iconColor: const Color(0xFF0288D1),
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const StressMonitoringScreen()),
                );
              },
            ),
            _DashboardOption(
              title: 'Vaccination Reminders',
              description: 'Never miss an important vaccination',
              icon: Icons.notifications,
              iconColor: const Color(0xFF0288D1),
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VaccinationReminder(),
                  ),
                );
              },
            ),
            _DashboardOption(
              title: 'Emergency SOS',
              description: 'Access emergency help and features',
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.red,
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SosMessagingScreen(),
                  ),
                );
              },
            ),
            _DashboardOption(
              title: 'Heart Disease Detector',
              description: 'Monitor your heart health',
              icon: Icons.favorite,
              iconColor: const Color(0xFF0288D1),
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HeartDiseaseDetectionScreen(),
                  ),
                );
              },
            ),
            _DashboardOption(
              title: 'Fitness Screen',
              description: 'Get personalized diet and exercise plans',
              icon: Icons.fitness_center,
              iconColor: const Color(0xFF0288D1),
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NutritionFitnessScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(isDarkMode ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(isDarkMode ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.arrow_forward_ios, color: iconColor, size: 16),
        ),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tapped: $title'),
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                ),
              );
            },
      ),
    );
  }
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


// --- Full Settings Page Widget ---
class SettingsPage extends StatelessWidget {
  final bool isDarkMode;
  const SettingsPage({Key? key, required this.isDarkMode}) : super(key: key);

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
                  leading: const Icon(Icons.link, color: Colors.blue),
                  title: const Text('Manage Linked Accounts'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Linked Accounts'),
                        content:
                            const Text('Manage linked accounts coming soon!'),
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
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.blue),
                  title: const Text('Default Home Screen'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Default Home Screen'),
                        content: const Text(
                            'Set your default home screen coming soon!'),
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
                  leading: const Icon(Icons.lock_outline, color: Colors.blue),
                  title: const Text('App Lock'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('App Lock'),
                        content: const Text('App lock coming soon!'),
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
            child: Text('Emergency & Security', style: sectionHeaderStyle),
          ),
          Card(
            color: cardColor,
            elevation: isDarkMode ? 0 : 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.contact_phone, color: Colors.red),
                  title: const Text('Manage Emergency Contacts'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Emergency Contacts'),
                        content: const Text(
                            'Manage emergency contacts coming soon!'),
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
                  leading: const Icon(Icons.sos, color: Colors.red),
                  title: const Text('SOS Settings'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('SOS Settings'),
                        content: const Text('SOS settings coming soon!'),
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
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.group_add, color: Colors.pink),
                  title: const Text('Refer a Friend'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Refer a Friend'),
                        content: const Text('Invite your friends to MedCon!'),
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
