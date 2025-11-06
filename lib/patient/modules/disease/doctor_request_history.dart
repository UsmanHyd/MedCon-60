import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/patient/modules/disease/doctor_request_detail.dart';

class DoctorRequestHistoryScreen extends StatelessWidget {
  final String doctorId;
  final String doctorName;

  const DoctorRequestHistoryScreen(
      {super.key, required this.doctorId, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final Color bgColor =
        isDarkMode ? const Color(0xFF181A20) : const Color(0xFFF5F6FA);
    final Color cardColor = isDarkMode ? const Color(0xFF23272F) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF0288D1),
        title: Text('Requests to $doctorName'),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('consultation_requests')
            .where('patientId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .where('doctorId', isEqualTo: doctorId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Fallback: try again without orderBy to avoid index requirement
            return _RequestsListFallback(
              doctorId: doctorId,
              doctorName: doctorName,
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No requests found',
                style: TextStyle(color: subTextColor),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final Timestamp? ts = data['createdAt'] as Timestamp?;
              final DateTime? createdAt = ts?.toDate();
              final String symptoms =
                  (data['symptoms'] ?? data['requestText'] ?? '').toString();
              final String status = (data['status'] ?? '').toString();

              return Card(
                color: cardColor,
                elevation: isDarkMode ? 0 : 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: _DateBadge(date: createdAt),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorRequestDetailScreen(
                          requestId: docs[index].id,
                          doctorName: doctorName,
                        ),
                      ),
                    );
                  },
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          createdAt != null
                              ? _formatDateTime(createdAt)
                              : 'Unknown date',
                          style: TextStyle(
                              color: textColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Builder(builder: (context) {
                      final String resp =
                          (data['doctorResponseText'] ?? '').toString();
                      final String text = resp.isNotEmpty ? resp : symptoms;
                      return Text(
                        text.isNotEmpty ? text : 'No message',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: subTextColor),
                      );
                    }),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _RequestsListFallback extends StatelessWidget {
  final String doctorId;
  final String doctorName;
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _RequestsListFallback({
    required this.doctorId,
    required this.doctorName,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('consultation_requests')
          .where('patientId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('doctorId', isEqualTo: doctorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Failed to load requests',
                  style: TextStyle(color: subTextColor)));
        }
        final docs = snapshot.data?.docs ?? [];
        // Sort locally desc
        docs.sort((a, b) {
          final ta = a.data()['createdAt'];
          final tb = b.data()['createdAt'];
          if (ta is Timestamp && tb is Timestamp) {
            return tb.compareTo(ta);
          }
          return 0;
        });

        if (docs.isEmpty) {
          return Center(
            child: Text('No requests found',
                style: TextStyle(color: subTextColor)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final Timestamp? ts = data['createdAt'] as Timestamp?;
            final DateTime? createdAt = ts?.toDate();
            final String symptoms =
                (data['symptoms'] ?? data['requestText'] ?? '').toString();
            final String status = (data['status'] ?? '').toString();

            return Card(
              color: cardColor,
              elevation: isDarkMode ? 0 : 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: _DateBadge(date: createdAt),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorRequestDetailScreen(
                        requestId: docs[index].id,
                        doctorName: doctorName,
                      ),
                    ),
                  );
                },
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        createdAt != null
                            ? _formatDateTime(createdAt)
                            : 'Unknown date',
                        style: TextStyle(
                            color: textColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                    _StatusChip(status: status),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    symptoms.isNotEmpty ? symptoms : 'No message',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subTextColor),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label = status.isEmpty ? 'Unknown' : status;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = const Color(0xFF4CAF50);
        break;
      case 'pending':
        color = const Color(0xFFFFC107);
        break;
      case 'rejected':
        color = const Color(0xFFF44336);
        break;
      default:
        color = Colors.blueGrey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime? date;
  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    final dt = date;
    final String month = dt != null
        ? [
            'JAN',
            'FEB',
            'MAR',
            'APR',
            'MAY',
            'JUN',
            'JUL',
            'AUG',
            'SEP',
            'OCT',
            'NOV',
            'DEC'
          ][dt.month - 1]
        : '--';
    final String day = dt != null ? dt.day.toString().padLeft(2, '0') : '--';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(month,
              style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white70 : const Color(0xFF0288D1),
                  fontWeight: FontWeight.w700)),
          Text(day,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF01579B),
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
