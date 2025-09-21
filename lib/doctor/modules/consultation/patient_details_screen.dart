import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'prescription_assistant_screen.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDetailsScreen extends ConsumerWidget {
  final Map<String, dynamic> request;
  const PatientDetailsScreen({Key? key, required this.request})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        foregroundColor: const Color(0xFF0288D1),
        elevation: 0.5,
        centerTitle: true,
        surfaceTintColor: isDarkMode ? Colors.grey[850] : Colors.white,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF0288D1)),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PatientHeaderCard(isDarkMode: isDarkMode, request: request),
          const SizedBox(height: 10),
          // Remove call/message buttons for now
          const SizedBox(height: 18),
          _ConsultationRequestCard(isDarkMode: isDarkMode, request: request),
          const SizedBox(height: 18),
          _SymptomsAndResultsCard(isDarkMode: isDarkMode, request: request),
          const SizedBox(height: 18),
          // Remove dummy Medical History and Previous Consultations for now
          const SizedBox(height: 18),
          // Previous Consultations
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.12)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Previous Consultations',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 12),
                _ConsultationItem(
                    title: 'Migraine Follow-up',
                    doctor: 'Dr. Sarah Chen',
                    date: 'March 15, 2025'),
                _ConsultationItem(
                    title: 'Hypertension Check',
                    doctor: 'Dr. James Wilson',
                    date: 'February 2, 2025'),
                _ConsultationItem(
                    title: 'Annual Physical',
                    doctor: 'Dr. Emily Parker',
                    date: 'January 10, 2025'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PrescriptionAssistantScreen(
                              patientData: request)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Prescription Assistant'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0288D1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: Color(0xFF0288D1)),
                  ),
                  child: const Text('Schedule Appointment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatientHeaderCard extends StatelessWidget {
  final bool isDarkMode;
  final Map<String, dynamic> request;
  const _PatientHeaderCard({required this.isDarkMode, required this.request});

  @override
  Widget build(BuildContext context) {
    final String patientName = (request['patientName'] ?? 'Patient').toString();
    final String patientId = (request['patientId'] ?? '').toString();
    final String? cachedAvatar = (request['patientAvatarUrl'] as String?);
    final String? cachedGender = (request['patientGender'] as String?);
    final String? cachedDob = (request['patientDateOfBirth'] as String?);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: patientId.isNotEmpty
          ? FirebaseFirestore.instance.collection('users').doc(patientId).get()
          : null,
      builder: (context, snap) {
        final userData = (snap.data?.data()) ?? <String, dynamic>{};
        final String displayName =
            (userData['name'] ?? userData['fullName'] ?? patientName)
                .toString();
        // gender/sex normalization
        String gender =
            (userData['gender'] ?? userData['sex'] ?? cachedGender ?? '')
                .toString();
        // age resolution: prefer request.patientAge, then user.age, then compute from dateOfBirth
        String ageStr = '';
        final dynamic reqAgeDyn = request['patientAge'];
        if (reqAgeDyn is num && reqAgeDyn > 0) {
          ageStr = reqAgeDyn.toInt().toString();
        } else if (reqAgeDyn is String && reqAgeDyn.trim().isNotEmpty) {
          final parsed = int.tryParse(reqAgeDyn.trim());
          if (parsed != null && parsed > 0) ageStr = parsed.toString();
        }
        if (ageStr.isEmpty) {
          final dynamic userAge = userData['age'];
          if (userAge is num && userAge > 0) {
            ageStr = userAge.toInt().toString();
          } else if (userAge is String && userAge.trim().isNotEmpty) {
            final parsed = int.tryParse(userAge.trim());
            if (parsed != null && parsed > 0) ageStr = parsed.toString();
          }
        }
        final String dobStr =
            (userData['dateOfBirth'] ?? cachedDob ?? '').toString();
        if (dobStr.isNotEmpty) {
          // Try DD/MM/YYYY first, then ISO
          DateTime? dob;
          try {
            final parts = dobStr.contains('/') ? dobStr.split('/') : [];
            if (parts.length == 3) {
              final d = int.tryParse(parts[0]);
              final m = int.tryParse(parts[1]);
              final y = int.tryParse(parts[2]);
              if (d != null && m != null && y != null) {
                dob = DateTime(y, m, d);
              }
            }
          } catch (_) {}
          dob ??= DateTime.tryParse(dobStr);
          if (dob != null) {
            final now = DateTime.now();
            int years = now.year - dob.year;
            if (now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day)) {
              years -= 1;
            }
            if (years >= 0 && years < 150) {
              ageStr = years.toString();
            }
          }
        }
        final String avatarUrl = (userData['profilePic'] ??
                userData['photoUrl'] ??
                userData['avatarUrl'] ??
                cachedAvatar ??
                '')
            .toString();

        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.12)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName
                                .trim()
                                .split(' ')
                                .map((w) => w.isNotEmpty ? w[0] : '')
                                .take(2)
                                .join()
                            : 'P',
                        style: const TextStyle(
                            fontSize: 22,
                            color: Color(0xFF0288D1),
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDarkMode ? Colors.white : Colors.black)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (ageStr.isNotEmpty) '$ageStr years',
                        if (gender.isNotEmpty) gender,
                      ].join(' • '),
                      style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConsultationRequestCard extends StatelessWidget {
  final bool isDarkMode;
  final Map<String, dynamic> request;
  const _ConsultationRequestCard(
      {required this.isDarkMode, required this.request});

  @override
  Widget build(BuildContext context) {
    final String requestText =
        (request['requestText'] ?? request['symptoms'] ?? '').toString();
    final String requestDate = request['createdAt'] != null
        ? _formatDate(request['createdAt'])
        : 'N/A';
    final String status = (request['status'] ?? 'Pending').toString();
    final bool isUrgent = (request['isUrgent'] ?? false) == true;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.12)
                : Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Consultation Request',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status, isDarkMode),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                'Requested on: $requestDate',
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (isUrgent) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.priority_high,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  'Urgent',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (requestText.isNotEmpty) ...[
            Text('Patient request:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey[800]?.withOpacity(0.3)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Text(
                requestText,
                style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[200] : Colors.black87),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return 'N/A';
      }
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String status, bool isDarkMode) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFFF6B6B);
      case 'pending':
        return const Color(0xFFFF9800);
      default:
        return isDarkMode ? Colors.grey[700]! : Colors.grey[600]!;
    }
  }
}

class _SymptomsAndResultsCard extends StatelessWidget {
  final bool isDarkMode;
  final Map<String, dynamic> request;
  const _SymptomsAndResultsCard(
      {required this.isDarkMode, required this.request});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> symptomsArray = (request['symptomsArray'] is List)
        ? (request['symptomsArray'] as List)
        : const [];
    final dynamic predictionResults = request['predictionResults'];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.12)
                : Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Symptoms & Diagnosis Results',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
          if (symptomsArray.isNotEmpty) ...[
            Text('Symptoms:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: symptomsArray
                  .map((s) => Chip(
                        label: Text(s.toString()),
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black),
                        backgroundColor:
                            isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (predictionResults is List && predictionResults.isNotEmpty) ...[
            Text('Predicted results:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            ...predictionResults.map((r) {
              final Map rr = r as Map;
              final name = (rr['disease'] ?? rr['name'] ?? '').toString();
              final conf = (rr['confidence'] ?? rr['percent'] ?? '').toString();
              final status = (rr['status'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black)),
                    ),
                    Text('$conf%',
                        style: TextStyle(
                            color:
                                isDarkMode ? Colors.white70 : Colors.black54)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(status,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                              fontSize: 12)),
                    ),
                  ],
                ),
              );
            }).cast<Widget>()
          ],
        ],
      ),
    );
  }
}

// Removed unused _HistoryItem widget

class _ConsultationItem extends StatelessWidget {
  final String title;
  final String doctor;
  final String date;
  const _ConsultationItem(
      {required this.title, required this.doctor, required this.date});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('$doctor • $date',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0288D1),
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 30),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}
