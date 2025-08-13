import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medcon30/theme/theme_provider.dart';
import 'consultation_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DoctorProfileScreen extends StatelessWidget {
  final String doctorId;
  final String? symptomCheckId;

  const DoctorProfileScreen(
      {super.key, required this.doctorId, this.symptomCheckId});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.blueGrey[900];
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.blueGrey[700];
    final iconBgColor = isDarkMode ? Colors.grey[800] : Colors.blue[50];
    final iconColor = isDarkMode ? Colors.grey[600] : Colors.blueGrey[200];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              color: bgColor,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 20, color: textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Doctor Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 18.0),
                    child: Icon(Icons.help_outline,
                        color: isDarkMode
                            ? Colors.blue[300]
                            : const Color(0xFF2196F3),
                        size: 20),
                  ),
                ],
              ),
            ),
            Divider(
                height: 1,
                thickness: 1,
                color: isDarkMode ? Colors.grey[800] : const Color(0xFFE0E3EA)),
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('doctors')
                    .doc(doctorId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(
                      child: Text('Doctor not found',
                          style: TextStyle(color: subTextColor)),
                    );
                  }
                  final data = snapshot.data!.data() ?? {};
                  final String name = (data['name'] ?? '').toString();
                  final String? avatarUrl =
                      (data['profilePic'] ?? data['avatar']) as String?;
                  final List<dynamic> specsDyn =
                      (data['specializations'] is List)
                          ? (data['specializations'] as List)
                          : const [];
                  final List<String> specializations =
                      specsDyn.map((e) => e.toString()).toList();
                  final String specialtyFallback =
                      (data['specialty'] ?? '').toString();
                  final String specialtyText = specializations.isNotEmpty
                      ? specializations.join(', ')
                      : (specialtyFallback.isNotEmpty ? specialtyFallback : '');
                  // role/verified no longer displayed

                  String _formatTimestamp(dynamic ts) {
                    try {
                      if (ts is Timestamp) {
                        final dt = ts.toDate();
                        return DateFormat('MMM d, y • h:mm a').format(dt);
                      }
                      return ts?.toString() ?? '';
                    } catch (_) {
                      return ts?.toString() ?? '';
                    }
                  }

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Profile card
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    color: iconBgColor,
                                    child: (avatarUrl != null &&
                                            avatarUrl.isNotEmpty)
                                        ? Image.network(
                                            avatarUrl,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(Icons.account_circle,
                                            size: 56, color: iconColor),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: textColor,
                                        ),
                                      ),
                                      if (specialtyText.isNotEmpty)
                                        Text(
                                          specialtyText,
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 15,
                                          ),
                                        ),
                                      // Role/Verified chips removed per request
                                      // Remove specialization chips per request
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Contact / Details
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Details',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: textColor)),
                            const SizedBox(height: 8),
                            // Role and Verified removed per request
                            if ((data['email'] ?? '').toString().isNotEmpty)
                              Row(children: [
                                Icon(Icons.email,
                                    size: 18,
                                    color: isDarkMode
                                        ? Colors.blue[300]
                                        : const Color(0xFF2196F3)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Email',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: subTextColor)),
                                      Text((data['email']).toString(),
                                          style: TextStyle(
                                              fontSize: 14, color: textColor)),
                                    ],
                                  ),
                                )
                              ]),
                            if ((data['phoneNumber'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(children: [
                                  Icon(Icons.phone,
                                      size: 18,
                                      color: isDarkMode
                                          ? Colors.blue[300]
                                          : const Color(0xFF2196F3)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Phone',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: subTextColor)),
                                        Text((data['phoneNumber']).toString(),
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: textColor)),
                                      ],
                                    ),
                                  )
                                ]),
                              ),
                            if ((data['licenseNumber'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(children: [
                                  Icon(Icons.badge,
                                      size: 18,
                                      color: isDarkMode
                                          ? Colors.blue[300]
                                          : const Color(0xFF2196F3)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('License',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: subTextColor)),
                                        Text((data['licenseNumber']).toString(),
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: textColor)),
                                      ],
                                    ),
                                  )
                                ]),
                              ),
                            if ((data['gender'] ?? '').toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(children: [
                                  Icon(Icons.person,
                                      size: 18,
                                      color: isDarkMode
                                          ? Colors.blue[300]
                                          : const Color(0xFF2196F3)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Gender',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: subTextColor)),
                                        Text((data['gender']).toString(),
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: textColor)),
                                      ],
                                    ),
                                  )
                                ]),
                              ),
                            if ((data['dateOfBirth'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(children: [
                                  Icon(Icons.cake,
                                      size: 18,
                                      color: isDarkMode
                                          ? Colors.blue[300]
                                          : const Color(0xFF2196F3)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Date of Birth',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: subTextColor)),
                                        Text((data['dateOfBirth']).toString(),
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: textColor)),
                                      ],
                                    ),
                                  )
                                ]),
                              ),
                            // Created At and Last Updated removed per request
                          ],
                        ),
                      ),

                      // About
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('About',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(
                              (data['description'] ?? 'No description')
                                  .toString(),
                              style: TextStyle(color: textColor, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      // Other Information (render remaining fields generically)
                      Builder(builder: (_) {
                        final Set<String> knownKeys = {
                          'name',
                          'profilePic',
                          'avatar',
                          'specializations',
                          'specialty',
                          'description',
                          'education',
                          'experience',
                          'address',
                          'email',
                          'phoneNumber',
                          'licenseNumber',
                          'gender',
                          'dateOfBirth',
                          'role',
                          'verified',
                          'createdAt',
                          'updatedAt',
                        };

                        String stringify(dynamic v) {
                          if (v == null) return '';
                          if (v is Timestamp) return _formatTimestamp(v);
                          if (v is List) {
                            return v.map((e) => stringify(e)).join(', ');
                          }
                          if (v is Map) {
                            return v.entries
                                .map((e) => '${e.key}: ${stringify(e.value)}')
                                .join(' | ');
                          }
                          return v.toString();
                        }

                        final other = data.entries
                            .where((e) => !knownKeys.contains(e.key))
                            .toList();
                        if (other.isEmpty) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Other Information',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: textColor)),
                              const SizedBox(height: 8),
                              ...other.map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(e.key,
                                              style: TextStyle(
                                                  color: subTextColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 5,
                                          child: Text(
                                            stringify(e.value),
                                            style: TextStyle(
                                                color: textColor, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        );
                      }),
                      // Education
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Education',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: textColor)),
                            const SizedBox(height: 8),
                            ...((data['education'] is List)
                                    ? (data['education'] as List)
                                    : const [])
                                .map((e) {
                                  if (e is Map<String, dynamic>) {
                                    final String degree =
                                        (e['degree'] ?? e['title'] ?? '')
                                            .toString();
                                    final String institute = (e['institute'] ??
                                            e['institution'] ??
                                            '')
                                        .toString();
                                    final String start = (e['startDate'] ??
                                            e['start'] ??
                                            e['from'] ??
                                            '')
                                        .toString();
                                    final String end = (e['endDate'] ??
                                            e['end'] ??
                                            e['to'] ??
                                            '')
                                        .toString();
                                    final String desc =
                                        (e['description'] ?? '').toString();

                                    Widget kv(String label, String value) {
                                      if (value.isEmpty)
                                        return const SizedBox.shrink();
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 110,
                                              child: Text(label,
                                                  style: TextStyle(
                                                      color: subTextColor,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(value,
                                                  style: TextStyle(
                                                      color: textColor,
                                                      fontSize: 14)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 10.0),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          kv('Degree', degree),
                                          kv('Institution', institute),
                                          kv('Start date', start),
                                          kv('End date', end),
                                          kv('Description', desc),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6.0),
                                      child: Row(children: [
                                        Icon(Icons.school,
                                            color: isDarkMode
                                                ? Colors.blue[300]
                                                : const Color(0xFF2196F3),
                                            size: 18),
                                        const SizedBox(width: 6),
                                        Expanded(
                                            child: Text(e.toString(),
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: textColor))),
                                      ]),
                                    );
                                  }
                                })
                                .cast<Widget>()
                                .toList(),
                          ],
                        ),
                      ),

                      // Experience
                      if (data['experience'] is List &&
                          (data['experience'] as List).isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Experience',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: textColor)),
                              const SizedBox(height: 8),
                              ...((data['experience'] as List)).map((e) {
                                if (e is Map<String, dynamic>) {
                                  final String role =
                                      (e['role'] ?? e['title'] ?? '')
                                          .toString();
                                  final String location = (e['location'] ??
                                          e['organization'] ??
                                          e['hospital'] ??
                                          '')
                                      .toString();
                                  final String desc =
                                      (e['description'] ?? '').toString();
                                  final String end =
                                      (e['endDate'] ?? e['to'] ?? '')
                                          .toString();
                                  final String start =
                                      (e['startDate'] ?? e['from'] ?? '')
                                          .toString();

                                  Widget kv(String label, String value) {
                                    if (value.isEmpty)
                                      return const SizedBox.shrink();
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 110,
                                            child: Text(label,
                                                style: TextStyle(
                                                    color: subTextColor,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(value,
                                                style: TextStyle(
                                                    color: textColor,
                                                    fontSize: 14)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10.0),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        kv('Role', role),
                                        kv('Location', location),
                                        kv('Description', desc),
                                        kv('End date', end),
                                        kv('Start date', start),
                                      ],
                                    ),
                                  );
                                } else {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Row(children: [
                                      Icon(Icons.work,
                                          color: isDarkMode
                                              ? Colors.blue[300]
                                              : const Color(0xFF2196F3),
                                          size: 18),
                                      const SizedBox(width: 6),
                                      Expanded(
                                          child: Text(e.toString(),
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: textColor))),
                                    ]),
                                  );
                                }
                              }).cast<Widget>()
                            ],
                          ),
                        ),
                      // Location (optional)
                      if ((data['address'] ?? '').toString().isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on,
                                  color: isDarkMode
                                      ? Colors.blue[300]
                                      : const Color(0xFF2196F3),
                                  size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text((data['address']).toString(),
                                    style: TextStyle(
                                        fontSize: 14, color: textColor)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ConsultationRequestScreen(
                                    doctorId: doctorId,
                                    doctorName: name.isEmpty ? 'Doctor' : name,
                                    doctorSpecialty: specialtyText,
                                    doctorAvatarUrl: avatarUrl,
                                    symptomCheckId: symptomCheckId,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Request Online Consultation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
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
