import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/doctor/modules/consultation/consultation_requests_screen.dart';

class DoctorNotificationsScreen extends StatelessWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF0288D1),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('❌ Error loading notifications: ${snapshot.error}');
            return Center(
              child: Text(
                'Error loading notifications',
                style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54),
              ),
            );
          }
          var docs = snapshot.data?.docs ?? [];
          print('📬 Doctor notifications query - UID: $uid, Found: ${docs.length}');
          for (var doc in docs) {
            print('   - Notification: ${doc.data()['message']}, userId: ${doc.data()['userId']}, read: ${doc.data()['read']}');
          }
          // Sort by createdAt desc client-side to avoid index
          docs.sort((a, b) {
            final ta = a.data()['createdAt'];
            final tb = b.data()['createdAt'];
            if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
            return 0;
          });
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No notifications',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'UID: ${uid ?? "null"}',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white54 : Colors.black38,
                        fontSize: 12),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final id = docs[i].id;
              final data = docs[i].data();
              final String message = (data['message'] ??
                      'New consultation request received')
                  .toString();
              final bool isUnread = !(data['read'] == true);
              final Timestamp? ts = data['createdAt'] as Timestamp?;
              final String when = ts != null
                  ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                  : '';

              return Material(
                color: isUnread
                    ? (isDarkMode ? Colors.grey[800] : const Color(0xFFE6F3FF))
                    : (isDarkMode ? Colors.grey[850] : Colors.white),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    // Mark as read and navigate to consultation requests page
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(id)
                        .update({'read': true});
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ConsultationRequestsScreen(),
                        ),
                      );
                    }
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Stack(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: isUnread
                              ? const Color(0xFF0288D1)
                              : (isDarkMode ? Colors.white70 : Colors.grey),
                        ),
                        if (isUnread)
                          Positioned(
                            right: 0,
                            top: 0,
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
                    ),
                    title: Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight:
                            isUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    subtitle: when.isNotEmpty ? Text(when) : null,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: isUnread
                          ? (isDarkMode ? Colors.white : const Color(0xFF0288D1))
                          : (isDarkMode ? Colors.white70 : Colors.grey),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

