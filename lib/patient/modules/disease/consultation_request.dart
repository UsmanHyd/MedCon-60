import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medcon30/theme/theme_provider.dart';
import 'request_confirmed.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConsultationRequestScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String? doctorSpecialty;
  final String? doctorAvatarUrl;
  final String? symptomCheckId;

  const ConsultationRequestScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    this.doctorSpecialty,
    this.doctorAvatarUrl,
    this.symptomCheckId,
  });

  @override
  State<ConsultationRequestScreen> createState() =>
      _ConsultationRequestScreenState();
}

class _ConsultationRequestScreenState extends State<ConsultationRequestScreen> {
  final TextEditingController _symptomController = TextEditingController();
  bool agreed = false;
  String? _symptomCheckIdFromArgs;

  bool get canSend => _symptomController.text.trim().isNotEmpty && agreed;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.blueGrey[900];
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.blueGrey[700];
    final iconBgColor = isDarkMode ? Colors.grey[800] : Colors.blue[50];
    final iconColor = isDarkMode ? Colors.grey[600] : Colors.blueGrey[200];
    final inputBgColor =
        isDarkMode ? Colors.grey[800] : const Color(0xFFF4F9FD);

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
                        'Online Consultation',
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
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Doctor card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: iconBgColor,
                            child: (widget.doctorAvatarUrl != null &&
                                    widget.doctorAvatarUrl!.isNotEmpty)
                                ? Image.network(
                                    widget.doctorAvatarUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        Icon(Icons.account_circle,
                                            size: 48, color: iconColor),
                                  )
                                : Icon(Icons.account_circle,
                                    size: 48, color: iconColor),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.doctorName,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor)),
                            if ((widget.doctorSpecialty ?? '').isNotEmpty)
                              Text(widget.doctorSpecialty!,
                                  style: TextStyle(
                                      color: subTextColor, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Symptom description
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Describe your symptoms',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textColor)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _symptomController,
                          maxLines: 3,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText:
                                'Please describe your symptoms in detail...',
                            hintStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.blueGrey[300]),
                            filled: true,
                            fillColor: inputBgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  // Terms checkbox
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: agreed,
                          onChanged: (v) => setState(() => agreed = v ?? false),
                          activeColor: const Color(0xFF2196F3),
                        ),
                        Expanded(
                          child: Text(
                            'I agree to the terms and conditions for online consultation',
                            style: TextStyle(fontSize: 14, color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Send Request button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canSend
                            ? () async {
                                try {
                                  final auth = FirebaseAuth.instance;
                                  final user = auth.currentUser;
                                  final String patientId = user?.uid ?? '';

                                  // Attempt to read patient info from users collection (optional)
                                  String? patientName;
                                  String? patientAvatarUrl;
                                  String? patientGender;
                                  String? patientDateOfBirth;
                                  try {
                                    if (patientId.isNotEmpty) {
                                      final doc = await FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(patientId)
                                          .get();
                                      final data = (doc.data() ?? {});
                                      patientName =
                                          (data['name'] ?? data['fullName'])
                                              ?.toString();
                                      patientAvatarUrl = (data['profilePic'] ??
                                              data['avatarUrl'])
                                          ?.toString();

                                      // Debug: Print what profile picture data was found
                                      print(
                                          'Patient profile data: ${data.keys.toList()}');
                                      print(
                                          'Found profilePic: ${data['profilePic']}');
                                      print(
                                          'Found avatarUrl: ${data['avatarUrl']}');
                                      print(
                                          'Final patientAvatarUrl: $patientAvatarUrl');
                                      patientGender =
                                          (data['gender'])?.toString();
                                      patientDateOfBirth =
                                          (data['dateOfBirth'])?.toString();
                                    }
                                  } catch (_) {}

                                  // If we have a symptom check id, load its symptoms and predictions to attach to request
                                  List<dynamic> symptomsFromCheck = [];
                                  dynamic predictionResultsFromCheck;
                                  try {
                                    final scId = widget.symptomCheckId;
                                    if (scId != null && scId.isNotEmpty) {
                                      final scDoc = await FirebaseFirestore
                                          .instance
                                          .collection('symptom_checks')
                                          .doc(scId)
                                          .get();
                                      if (scDoc.exists) {
                                        final data = scDoc.data()
                                            as Map<String, dynamic>;
                                        final dynSymptoms = data['symptoms'];
                                        if (dynSymptoms is List) {
                                          symptomsFromCheck =
                                              List<dynamic>.from(dynSymptoms);
                                        }
                                        // Support either 'predictions' or 'results'
                                        predictionResultsFromCheck =
                                            data['predictions'] ??
                                                data['results'];
                                      }
                                    }
                                  } catch (_) {}

                                  final requestDocRef = await FirebaseFirestore.instance
                                      .collection('consultation_requests')
                                      .add({
                                    'doctorId': widget.doctorId,
                                    'doctorName': widget.doctorName,
                                    'doctorSpecialty': widget.doctorSpecialty,
                                    'doctorAvatarUrl': widget.doctorAvatarUrl,
                                    'patientId': patientId,
                                    'patientName': patientName,
                                    'patientAvatarUrl': patientAvatarUrl,
                                    'patientGender': patientGender,
                                    'patientDateOfBirth': patientDateOfBirth,
                                    // Save the typed request text under two keys for clarity/compat
                                    'symptoms': _symptomController.text.trim(),
                                    'requestText':
                                        _symptomController.text.trim(),
                                    // Also include the detection context if available
                                    'symptomCheckId': widget.symptomCheckId,
                                    'symptomsArray': symptomsFromCheck,
                                    'predictionResults':
                                        predictionResultsFromCheck,
                                    'status': 'Pending',
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });

                                  // Create notification for the doctor
                                  try {
                                    print('🔔 Attempting to create notification...');
                                    print('   Doctor ID: ${widget.doctorId}');
                                    print('   Patient Name: $patientName');
                                    print('   Request ID: ${requestDocRef.id}');
                                    
                                    if (widget.doctorId.isEmpty) {
                                      print('❌ Doctor ID is empty, cannot create notification');
                                    } else {
                                      final notificationData = {
                                        'userId': widget.doctorId,
                                        'type': 'consultation_request',
                                        'requestId': requestDocRef.id,
                                        'message': 'New request from ${patientName ?? "a patient"} arrived',
                                        'createdAt': FieldValue.serverTimestamp(),
                                        'read': false,
                                      };
                                      print('   Notification data: $notificationData');
                                      
                                      final notificationRef = await FirebaseFirestore.instance
                                          .collection('notifications')
                                          .add(notificationData);
                                      print('✅ Notification created successfully! ID: ${notificationRef.id}');
                                      print('   Notification userId: ${notificationData['userId']}');
                                    }
                                  } catch (e, stackTrace) {
                                    print('❌ Error creating notification: $e');
                                    print('   Stack trace: $stackTrace');
                                    // Don't fail the whole request if notification fails
                                  }

                                  // Also merge this request into the most recent symptom_checks doc for this user
                                  try {
                                    String? latestId = widget.symptomCheckId ??
                                        _symptomCheckIdFromArgs;
                                    if (latestId == null) {
                                      final checksSnap = await FirebaseFirestore
                                          .instance
                                          .collection('symptom_checks')
                                          .where('userId', isEqualTo: patientId)
                                          .get();
                                      Timestamp? latest;
                                      for (final d in checksSnap.docs) {
                                        final ts =
                                            d.data()['createdAt'] as Timestamp?;
                                        if (latest == null ||
                                            (ts != null &&
                                                ts.compareTo(latest) > 0)) {
                                          latest = ts;
                                          latestId = d.id;
                                        }
                                      }
                                    }

                                    final mergeData = {
                                      'requestText':
                                          _symptomController.text.trim(),
                                      'doctorId': widget.doctorId,
                                      'doctorName': widget.doctorName,
                                      'doctorSpecialty': widget.doctorSpecialty,
                                      'doctorAvatarUrl': widget.doctorAvatarUrl,
                                      'requestCreatedAt':
                                          FieldValue.serverTimestamp(),
                                      'fromConsultation': true,
                                    };

                                    if (latestId != null) {
                                      await FirebaseFirestore.instance
                                          .collection('symptom_checks')
                                          .doc(latestId)
                                          .set(mergeData,
                                              SetOptions(merge: true));
                                    } else {
                                      await FirebaseFirestore.instance
                                          .collection('symptom_checks')
                                          .add({
                                        'userId': patientId,
                                        'symptoms': [],
                                        'results': [],
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                        ...mergeData,
                                      });
                                    }
                                  } catch (_) {}

                                  if (!context.mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RequestConfirmedScreen(),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Failed to send request: $e'),
                                    ),
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canSend
                              ? const Color(0xFF2196F3)
                              : isDarkMode
                                  ? Colors.grey[700]
                                  : const Color(0xFFB0BEC5),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Send Request',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
