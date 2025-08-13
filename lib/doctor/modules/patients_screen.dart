import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Dummy data for demonstration
  final List<Map<String, dynamic>> _patients = [
    {
      'name': 'Jennifer Wilson',
      'age': 34,
      'gender': 'Female',
      'condition': 'Migraine',
      'lastVisit': 'May 15, 2024',
      'status': 'Under Treatment',
      'imageUrl': null, // Will use placeholder
    },
    {
      'name': 'Robert Johnson',
      'age': 56,
      'gender': 'Male',
      'condition': "Parkinson's",
      'lastVisit': 'May 18, 2024',
      'status': 'Under Treatment',
      'imageUrl': null,
    },
    {
      'name': 'Sophia Martinez',
      'age': 28,
      'gender': 'Female',
      'condition': 'Epilepsy',
      'lastVisit': 'May 20, 2024',
      'status': 'Under Treatment',
      'imageUrl': null,
    },
    {
      'name': 'Michael Rodriguez',
      'age': 45,
      'gender': 'Male',
      'condition': 'Multiple Sclerosis',
      'lastVisit': 'May 10, 2024',
      'status': 'Under Treatment',
      'imageUrl': null,
    },
    {
      'name': 'Emma Thompson',
      'age': 32,
      'gender': 'Female',
      'condition': 'Chronic Headache',
      'lastVisit': 'May 12, 2024',
      'status': 'Under Treatment',
      'imageUrl': null,
    },
  ];

  List<Map<String, dynamic>> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    return _patients.where((patient) {
      final name = patient['name'].toString().toLowerCase();
      final condition = patient['condition'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || condition.contains(query);
    }).toList();
  }

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
          // Patient List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = _filteredPatients[index];
                return _PatientCard(
                  name: patient['name'],
                  age: patient['age'],
                  gender: patient['gender'],
                  condition: patient['condition'],
                  lastVisit: patient['lastVisit'],
                  status: patient['status'],
                  onViewProfile: () {
                    // TODO: Navigate to patient profile
                  },
                  onChat: () {
                    // TODO: Navigate to chat
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

  const _PatientCard({
    required this.name,
    required this.age,
    required this.gender,
    required this.condition,
    required this.lastVisit,
    required this.status,
    required this.onViewProfile,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final initials = name.split(' ').map((e) => e[0]).join('');

    return Container(
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
                // Profile Picture/Initials
                CircleAvatar(
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
                        '$age years • $gender',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[900]
                              : const Color(0xFFE6F3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          condition,
                          style: const TextStyle(
                            color: Color(0xFF0288D1),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Additional Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Visit',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      lastVisit,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
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
                  child: ElevatedButton.icon(
                    onPressed: onViewProfile,
                    icon: const Icon(Icons.person_outline, size: 20),
                    label: const Text('View Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_outlined, size: 20),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDarkMode ? Colors.grey[850] : Colors.white,
                      foregroundColor: const Color(0xFF0288D1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF0288D1)),
                      ),
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
