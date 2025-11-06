import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'patient_details_screen.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ConsultationRequestsScreen extends ConsumerStatefulWidget {
  const ConsultationRequestsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsultationRequestsScreen> createState() =>
      _ConsultationRequestsScreenState();
}

class _ConsultationRequestsScreenState
    extends ConsumerState<ConsultationRequestsScreen> {
  String _selectedFilter = 'All';
  Set<String> _processingRequests = {}; // Track requests being processed

  String _formatTs(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    return DateFormat('MMM d, y • h:mm a').format(dt);
  }

  String _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return '';

    try {
      DateTime birthDate;
      if (dateOfBirth is Timestamp) {
        birthDate = dateOfBirth.toDate();
      } else if (dateOfBirth is String) {
        birthDate = DateTime.parse(dateOfBirth);
      } else {
        return '';
      }

      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      return '${age}y';
    } catch (e) {
      return '';
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter by Status',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _selectedFilter == 'All',
                      onTap: () {
                        setState(() => _selectedFilter = 'All');
                        Navigator.pop(context);
                      },
                    ),
                    _FilterChip(
                      label: 'Urgent',
                      color: const Color(0xFFFF6B6B),
                      selected: _selectedFilter == 'Urgent',
                      onTap: () {
                        setState(() => _selectedFilter = 'Urgent');
                        Navigator.pop(context);
                      },
                    ),
                    _FilterChip(
                      label: 'Medium',
                      color: const Color(0xFFFFD600),
                      selected: _selectedFilter == 'Medium',
                      onTap: () {
                        setState(() => _selectedFilter = 'Medium');
                        Navigator.pop(context);
                      },
                    ),
                    _FilterChip(
                      label: 'Regular',
                      color: const Color(0xFF4CAF50),
                      selected: _selectedFilter == 'Regular',
                      onTap: () {
                        setState(() => _selectedFilter = 'Regular');
                        Navigator.pop(context);
                      },
                    ),
                    _FilterChip(
                      label: 'Accepted',
                      color: const Color(0xFF4CAF50),
                      selected: _selectedFilter == 'Accepted',
                      onTap: () {
                        setState(() => _selectedFilter = 'Accepted');
                        Navigator.pop(context);
                      },
                    ),
                    _FilterChip(
                      label: 'Rejected',
                      color: const Color(0xFFFF6B6B),
                      selected: _selectedFilter == 'Rejected',
                      onTap: () {
                        setState(() => _selectedFilter = 'Rejected');
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Requests'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        foregroundColor: const Color(0xFF0288D1),
        elevation: 0.5,
        centerTitle: true,
        surfaceTintColor: isDarkMode ? Colors.grey[850] : Colors.white,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF0288D1)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF0288D1)),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
            return Center(child: Text('Failed to load requests'));
          }
          final docs = snapshot.data?.docs ?? [];
          List<Map<String, dynamic>> items =
              docs.map((d) => {'id': d.id, ...d.data()}).toList();
          // Sort locally by createdAt desc to avoid composite index requirement
          items.sort((a, b) {
            final ta = a['createdAt'];
            final tb = b['createdAt'];
            if (ta is Timestamp && tb is Timestamp) {
              return tb.compareTo(ta);
            }
            return 0;
          });
          final filtered = _selectedFilter == 'All'
              ? items
              : items
                  .where((m) => (m['status'] ?? '') == _selectedFilter)
                  .toList();
          if (filtered.isEmpty) {
            return Center(
              child: Text('No consultation requests',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final req = filtered[i];
              final String patientName =
                  (req['patientName'] ?? 'Patient').toString();
              final String symptoms = (req['symptoms'] ?? '').toString();
              final String status = (req['status'] ?? 'Pending').toString();
              final Timestamp? ts = req['createdAt'] as Timestamp?;
              final String timeStr = _formatTs(ts);

              // Debug: Print all available fields
              print('Consultation request fields: ${req.keys.toList()}');
              final String? patientAvatarUrl =
                  req['patientAvatarUrl']?.toString();
              print('Patient: $patientName, Avatar URL: $patientAvatarUrl');

              // Also check for other possible field names as fallback
              final String? fallbackAvatarUrl =
                  req['patientProfilePic']?.toString() ??
                      req['patientPhotoUrl']?.toString() ??
                      req['patientAvatar']?.toString();
              if (fallbackAvatarUrl != null && fallbackAvatarUrl.isNotEmpty) {
                print('Found fallback avatar URL: $fallbackAvatarUrl');
              }

              Color statusColor;
              switch (status) {
                case 'Urgent':
                  statusColor = const Color(0xFFFF6B6B);
                  break;
                case 'Medium':
                  statusColor = const Color(0xFFFFD600);
                  break;
                case 'Accepted':
                  statusColor = const Color(0xFF4CAF50);
                  break;
                case 'Rejected':
                  statusColor = const Color(0xFFFF6B6B);
                  break;
                default:
                  statusColor = const Color(0xFF4CAF50);
              }

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PatientDetailsScreen(request: req)),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PatientAvatar(
                        patientName: patientName,
                        avatarUrl: patientAvatarUrl ?? fallbackAvatarUrl,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(patientName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black)),
                                const SizedBox(width: 8),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(status,
                                      style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(symptoms,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: isDarkMode
                                              ? Colors.grey[200]
                                              : Colors.black)),
                                ),
                                // Show urgent indicator
                                if (req['priority'] == 'Urgent' ||
                                    status == 'Urgent') ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B6B)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(0xFFFF6B6B)
                                            .withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'URGENT',
                                      style: TextStyle(
                                        color: Color(0xFFFF6B6B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Patient info
                                if (req['patientGender'] != null ||
                                    req['patientDateOfBirth'] != null) ...[
                                  Expanded(
                                    child: Row(
                                      children: [
                                        if (req['patientGender'] != null) ...[
                                          Icon(
                                            req['patientGender'] == 'Male'
                                                ? Icons.male
                                                : Icons.female,
                                            size: 14,
                                            color: isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            req['patientGender'].toString(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                        if (req['patientDateOfBirth'] !=
                                            null) ...[
                                          if (req['patientGender'] != null)
                                            const SizedBox(width: 8),
                                          Icon(
                                            Icons.cake,
                                            size: 14,
                                            color: isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _calculateAge(
                                                req['patientDateOfBirth']),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                                // Consultation type indicator
                                if (req['fromConsultation'] == true) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0288D1)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(0xFF0288D1)
                                            .withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'CONSULTATION',
                                      style: TextStyle(
                                        color: Color(0xFF0288D1),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(timeStr,
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey,
                                      fontSize: 12)),
                            ),

                            // Show doctor response time for accepted/rejected requests
                            if ((status == 'Accepted' ||
                                    status == 'Rejected') &&
                                req['doctorResponseAt'] != null) ...[
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Responded: ${_formatTs(req['doctorResponseAt'])}',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],

                            // Add accept/reject buttons for pending requests
                            if (status == 'Pending') ...[
                              const SizedBox(height: 12),
                              // Debug print
                              Builder(
                                builder: (context) {
                                  print(
                                      'Building buttons for request: ${req['id']}, Processing: ${_processingRequests.contains(req['id'])}');
                                  return Container();
                                },
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[800]?.withOpacity(0.3)
                                      : Colors.grey[100]?.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: ElevatedButton(
                                          onPressed: _processingRequests
                                                  .contains(req['id'])
                                              ? null
                                              : () {
                                                  print(
                                                      'Accept button pressed for request: ${req['id']}');
                                                  print(
                                                      'Current processing requests: $_processingRequests');
                                                  print(
                                                      'Button should be enabled for request: ${req['id']}');
                                                  _showConfirmationDialog(
                                                    context,
                                                    req['id'],
                                                    req['symptomCheckId'],
                                                    'Accepted',
                                                    'Accept',
                                                    'Are you sure you want to accept this consultation request?',
                                                  );
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _processingRequests
                                                    .contains(req['id'])
                                                ? Colors.grey
                                                : const Color(0xFF4CAF50),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: _processingRequests
                                                    .contains(req['id'])
                                                ? 0
                                                : 2,
                                          ),
                                          child: _processingRequests
                                                  .contains(req['id'])
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                )
                                              : const Text(
                                                  'Accept',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: ElevatedButton(
                                          onPressed: _processingRequests
                                                  .contains(req['id'])
                                              ? null
                                              : () {
                                                  print(
                                                      'Reject button pressed for request: ${req['id']}');
                                                  print(
                                                      'Current processing requests: $_processingRequests');
                                                  _showConfirmationDialog(
                                                    context,
                                                    req['id'],
                                                    req['symptomCheckId'],
                                                    'Rejected',
                                                    'Reject',
                                                    'Are you sure you want to reject this consultation request?',
                                                  );
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _processingRequests
                                                    .contains(req['id'])
                                                ? Colors.grey
                                                : const Color(0xFFFF6B6B),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: _processingRequests
                                                    .contains(req['id'])
                                                ? 0
                                                : 2,
                                          ),
                                          child: _processingRequests
                                                  .contains(req['id'])
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                )
                                              : const Text(
                                                  'Reject',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleRequestAction(
    BuildContext context,
    String requestId,
    String? symptomCheckId,
    String newStatus,
  ) async {
    print(
        'Starting _handleRequestAction for request: $requestId, status: $newStatus');

    // Add request to processing set
    print('About to add to processing set: $requestId');
    setState(() {
      _processingRequests.add(requestId);
    });
    print('Added to processing set. Current processing: $_processingRequests');

    try {
      // Update consultation request status
      print('Updating consultation request...');
      await FirebaseFirestore.instance
          .collection('consultation_requests')
          .doc(requestId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'doctorResponseAt': FieldValue.serverTimestamp(),
      });
      print('Consultation request updated successfully');

      // Update symptom check status if available
      if (symptomCheckId != null && symptomCheckId.isNotEmpty) {
        try {
          print('Updating symptom check...');
          await FirebaseFirestore.instance
              .collection('symptom_checks')
              .doc(symptomCheckId)
              .update({
            'consultationStatus': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('Symptom check updated successfully');
        } catch (e) {
          // Log error but don't fail the entire operation
          print('Warning: Failed to update symptom check status: $e');
        }
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${newStatus.toLowerCase()} successfully'),
            backgroundColor: newStatus == 'Accepted'
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFF6B6B),
          ),
        );
      }

      // If accepted, navigate to patient profile
      if (newStatus == 'Accepted' && context.mounted) {
        print('Request accepted, navigating to patient profile...');

        // Get the updated request data to pass to PatientDetailsScreen
        final updatedRequest = await FirebaseFirestore.instance
            .collection('consultation_requests')
            .doc(requestId)
            .get();

        if (updatedRequest.exists && context.mounted) {
          final requestData = updatedRequest.data()!;
          requestData['id'] = requestId; // Ensure ID is included

          print(
              'Navigating to PatientDetailsScreen with data: ${requestData.keys.toList()}');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDetailsScreen(request: requestData),
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _handleRequestAction: $e');
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${newStatus.toLowerCase()} request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Remove request from processing set
      print('About to remove from processing set: $requestId');
      print('Current processing set before removal: $_processingRequests');
      // Use a more robust check for mounted state
      if (mounted && context.mounted) {
        setState(() {
          _processingRequests.remove(requestId);
        });
        print(
            'Removed from processing set. Current processing: $_processingRequests');
      } else {
        print('Widget not mounted, cannot update state');
      }
    }
  }

  void _showConfirmationDialog(
    BuildContext context,
    String requestId,
    String? symptomCheckId,
    String newStatus,
    String actionText,
    String confirmationMessage,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(actionText),
        content: Text(confirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              print('Confirmation dialog confirmed for $actionText');
              Navigator.of(context).pop(); // Close confirmation dialog
              _handleRequestAction(
                context,
                requestId,
                symptomCheckId,
                newStatus,
              );
            },
            child: Text(actionText),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
            color: selected ? Colors.white : (color ?? const Color(0xFF0288D1)),
            fontWeight: FontWeight.w600,
          )),
      selected: selected,
      selectedColor: color ?? const Color(0xFF0288D1),
      backgroundColor: (color ?? const Color(0xFF0288D1)).withOpacity(0.13),
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: selected ? 2 : 0,
      pressElevation: 2,
    );
  }
}

class _PatientAvatar extends StatefulWidget {
  final String patientName;
  final String? avatarUrl;
  final bool isDarkMode;

  const _PatientAvatar({
    required this.patientName,
    required this.avatarUrl,
    required this.isDarkMode,
  });

  @override
  State<_PatientAvatar> createState() => _PatientAvatarState();
}

class _PatientAvatarState extends State<_PatientAvatar> {
  bool _imageError = false;

  @override
  Widget build(BuildContext context) {
    // If no avatar URL or image failed to load, show initials
    if (widget.avatarUrl == null || widget.avatarUrl!.isEmpty || _imageError) {
      return _buildInitialsAvatar();
    }

    // Show profile picture
    return CircleAvatar(
      radius: 20,
      backgroundColor:
          widget.isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
      backgroundImage: NetworkImage(widget.avatarUrl!),
      onBackgroundImageError: (exception, stackTrace) {
        // If image fails to load, set error flag and rebuild
        setState(() {
          _imageError = true;
        });
      },
    );
  }

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor:
          widget.isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
      child: Text(
        (widget.patientName.isNotEmpty
            ? widget.patientName
                .trim()
                .split(' ')
                .map((w) => w.isNotEmpty ? w[0] : '')
                .take(2)
                .join()
            : 'P'),
        style: const TextStyle(
            color: Color(0xFF0288D1), fontWeight: FontWeight.bold),
      ),
    );
  }
}
