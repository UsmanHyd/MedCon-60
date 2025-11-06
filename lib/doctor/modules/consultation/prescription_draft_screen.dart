import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcon30/theme/theme_provider.dart';
import '/doctor/modules/doctor_dashboard.dart';
import '/providers/auth_provider.dart';

class PrescriptionDraftScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? patientData;
  final List<String> selectedFormulas;
  final List<String> labTests;
  final List<String> guidelines;

  const PrescriptionDraftScreen({
    Key? key,
    this.patientData,
    required this.selectedFormulas,
    required this.labTests,
    required this.guidelines,
  }) : super(key: key);

  @override
  ConsumerState<PrescriptionDraftScreen> createState() =>
      _PrescriptionDraftScreenState();
}

class _PrescriptionDraftScreenState
    extends ConsumerState<PrescriptionDraftScreen> {
  bool _isSaving = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getPatientName() {
    if (widget.patientData != null) {
      return widget.patientData!['patientName'] ?? 'Unknown Patient';
    }
    return 'Unknown Patient';
  }

  String _getPatientInitials() {
    if (widget.patientData != null) {
      final name = widget.patientData!['patientName'] ?? '';
      if (name.isNotEmpty) {
        final nameParts = name.split(' ');
        if (nameParts.length >= 2) {
          return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
        } else if (nameParts.length == 1) {
          return nameParts[0][0].toUpperCase();
        }
      }
    }
    return 'UP';
  }

  String _getPatientDetails() {
    if (widget.patientData != null) {
      // Calculate age from date of birth
      String ageStr = '';
      final dobStr =
          widget.patientData!['patientDateOfBirth']?.toString() ?? '';
      if (dobStr.isNotEmpty) {
        try {
          DateTime? dob;
          if (dobStr.contains('/')) {
            final parts = dobStr.split('/');
            if (parts.length == 3) {
              final d = int.tryParse(parts[0]);
              final m = int.tryParse(parts[1]);
              final y = int.tryParse(parts[2]);
              if (d != null && m != null && y != null) {
                dob = DateTime(y, m, d);
              }
            }
          } else {
            dob = DateTime.tryParse(dobStr);
          }

          if (dob != null) {
            final now = DateTime.now();
            int years = now.year - dob.year;
            if (now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day)) {
              years--;
            }
            if (years >= 0 && years < 150) {
              ageStr = years.toString();
            }
          }
        } catch (e) {
          print('Error calculating age: $e');
        }
      }

      final gender = widget.patientData!['patientGender']?.toString() ?? '';
      final condition = widget.patientData!['condition']?.toString() ?? '';

      List<String> details = [];
      if (ageStr.isNotEmpty) details.add('$ageStr years');
      if (gender.isNotEmpty) details.add(gender);
      if (condition.isNotEmpty) details.add(condition);

      return details.join(' • ');
    }
    return 'Unknown';
  }

  String? _getPatientProfilePicture() {
    if (widget.patientData != null) {
      return widget.patientData!['patientAvatarUrl']?.toString();
    }
    return null;
  }

  // Get doctor data from Firestore
  Future<Map<String, dynamic>?> _getDoctorData() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return null;

      final doctorDoc =
          await _firestore.collection('doctors').doc(user.uid).get();

      if (doctorDoc.exists) {
        return doctorDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting doctor data: $e');
      return null;
    }
  }

  Future<void> _savePrescriptionToDatabase() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final doctorData = await _getDoctorData();
      final user = ref.read(userProvider);

      final prescriptionData = {
        'patientId': widget.patientData?['patientId'] ?? '',
        'patientName': _getPatientName(),
        'doctorId': user?.uid ?? '',
        'doctorName': doctorData?['name'] ?? user?.name ?? 'Unknown Doctor',
        'doctorSpecialization':
            doctorData?['specializations']?.isNotEmpty == true
                ? (doctorData!['specializations'] as List).first.toString()
                : 'General Medicine',
        'doctorLicense': doctorData?['licenseNumber'] ?? 'Not specified',
        'medicines': widget.selectedFormulas,
        'labTests': widget.labTests,
        'guidelines': widget.guidelines,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'draft', // draft, sent, completed
        'prescriptionId': _firestore.collection('prescriptions').doc().id,
      };

      await _firestore.collection('prescriptions').add(prescriptionData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription draft saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving prescription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving prescription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = provider.Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Draft'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        foregroundColor: const Color(0xFF0288D1),
        surfaceTintColor: isDarkMode ? Colors.grey[850] : Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _savePrescriptionToDatabase,
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Patient header
          Container(
            width: double.infinity,
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
                  backgroundImage: _getPatientProfilePicture() != null &&
                          _getPatientProfilePicture()!.isNotEmpty
                      ? NetworkImage(_getPatientProfilePicture()!)
                      : null,
                  child: _getPatientProfilePicture() == null ||
                          _getPatientProfilePicture()!.isEmpty
                      ? Text(_getPatientInitials(),
                          style: const TextStyle(
                              fontSize: 22,
                              color: Color(0xFF0288D1),
                              fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getPatientName(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(_getPatientDetails(),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Medications
          if (widget.selectedFormulas.isNotEmpty) ...[
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Medications (${widget.selectedFormulas.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...widget.selectedFormulas.map((med) => _DraftMedItem(
                        name: med,
                        dose: 'As prescribed',
                        desc: 'Follow doctor\'s instructions',
                        qty: '',
                        refills: '',
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Lab Tests
          if (widget.labTests.isNotEmpty) ...[
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lab Tests (${widget.labTests.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...widget.labTests.map((test) => _DraftLabItem(
                        name: test,
                        desc: 'As recommended by doctor',
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Guidelines
          if (widget.guidelines.isNotEmpty) ...[
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clinical Guidelines (${widget.guidelines.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...widget.guidelines.map((guideline) => _DraftGuidelineItem(
                        guideline: guideline,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Empty state if no data
          if (widget.selectedFormulas.isEmpty &&
              widget.labTests.isEmpty &&
              widget.guidelines.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    size: 64,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No prescription data available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please add medications, lab tests, or guidelines in the prescription assistant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrescriptionSummaryScreen(
                          patientData: widget.patientData,
                          selectedFormulas: widget.selectedFormulas,
                          labTests: widget.labTests,
                          guidelines: widget.guidelines,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Finalize Prescription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0288D1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: Color(0xFF0288D1)),
                  ),
                  child: const Text('Back to Assistant'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DraftMedItem extends StatelessWidget {
  final String name;
  final String dose;
  final String desc;
  final String qty;
  final String refills;
  const _DraftMedItem(
      {required this.name,
      required this.dose,
      required this.desc,
      required this.qty,
      required this.refills});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(dose,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 2),
                if (qty.isNotEmpty || refills.isNotEmpty)
                  Text('Quantity: $qty   Refills: $refills',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftLabItem extends StatelessWidget {
  final String name;
  final String desc;
  const _DraftLabItem({required this.name, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(desc,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftGuidelineItem extends StatelessWidget {
  final String guideline;
  const _DraftGuidelineItem({required this.guideline});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(guideline, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class PrescriptionSentSuccessScreen extends StatelessWidget {
  const PrescriptionSentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.microtask(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DoctorDashboard()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFE6F3FF),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF0288D1), size: 64),
              SizedBox(height: 12),
              Text('Prescription sent successfully!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('Redirecting to dashboard...',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class PrescriptionSummaryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? patientData;
  final List<String> selectedFormulas;
  final List<String> labTests;
  final List<String> guidelines;

  const PrescriptionSummaryScreen({
    Key? key,
    this.patientData,
    required this.selectedFormulas,
    required this.labTests,
    required this.guidelines,
  }) : super(key: key);

  @override
  ConsumerState<PrescriptionSummaryScreen> createState() =>
      _PrescriptionSummaryScreenState();
}

class _PrescriptionSummaryScreenState
    extends ConsumerState<PrescriptionSummaryScreen> {
  Map<String, dynamic>? _doctorData;
  bool _isLoadingDoctorData = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    try {
      final appUser = ref.read(userProvider);
      final authUser = FirebaseAuth.instance.currentUser;
      final uid = appUser?.uid ?? authUser?.uid;
      final email = authUser?.email;
      print(
          '🔍 Loading doctor data. appUser uid: ${appUser?.uid}, auth uid: ${authUser?.uid}, email: $email');

      if (uid == null) {
        print('❌ No UID available from provider or auth');
        setState(() {
          _isLoadingDoctorData = false;
        });
        return;
      }

      final doctorDoc = await _firestore.collection('doctors').doc(uid).get();

      if (doctorDoc.exists) {
        final data = doctorDoc.data();
        print('✅ Doctor data found: $data');
        print('🔍 Doctor name field: ${data?['name']}');
        setState(() {
          _doctorData = data;
          _isLoadingDoctorData = false;
        });
      } else {
        print('❌ Doctor document does not exist for uid: $uid');
        // Fallback 1: query doctors by email if available
        if (email != null && email.isNotEmpty) {
          final byEmail = await _firestore
              .collection('doctors')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (byEmail.docs.isNotEmpty) {
            final data = byEmail.docs.first.data();
            print('✅ Doctor data found by email: $data');
            setState(() {
              _doctorData = data;
              _isLoadingDoctorData = false;
            });
            return;
          }
        }

        // Fallback 2: users collection by uid
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          print('✅ User data found: $userData');
          print('🔍 User name field: ${userData?['name']}');
          setState(() {
            _doctorData = userData;
            _isLoadingDoctorData = false;
          });
        } else {
          print('❌ User document also does not exist');
          setState(() {
            _isLoadingDoctorData = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading doctor data: $e');
      setState(() {
        _isLoadingDoctorData = false;
      });
    }
  }

  String _getPatientName() {
    if (widget.patientData != null) {
      return widget.patientData!['patientName'] ?? 'Unknown Patient';
    }
    return 'Unknown Patient';
  }

  String _getPatientDOB() {
    if (widget.patientData != null) {
      return widget.patientData!['patientDateOfBirth'] ?? 'Not specified';
    }
    return 'Not specified';
  }

  String _getPatientDiagnosis() {
    if (widget.patientData != null) {
      return widget.patientData!['condition'] ?? 'Not specified';
    }
    return 'Not specified';
  }

  String _getDoctorName() {
    print('🔍 Getting doctor name - _doctorData: $_doctorData');

    // 1) Doctor collection - prioritize this
    if (_doctorData != null && _doctorData!['name'] != null) {
      final name = _doctorData!['name'].toString().trim();
      print('✅ Found name in doctor data: $name');
      if (name.isNotEmpty) {
        return name.startsWith('Dr.') ? name : 'Dr. $name';
      }
    }

    // 2) App user provider
    final user = ref.read(userProvider);
    print('🔍 User provider data: ${user?.name}');
    if (user?.name != null) {
      final name = user!.name!.trim();
      if (name.isNotEmpty) {
        return name.startsWith('Dr.') ? name : 'Dr. $name';
      }
    }

    // 3) Firebase Auth displayName
    final authUser = FirebaseAuth.instance.currentUser;
    final displayName = authUser?.displayName?.trim() ?? '';
    print('🔍 Firebase Auth displayName: $displayName');
    if (displayName.isNotEmpty) {
      return displayName.startsWith('Dr.') ? displayName : 'Dr. $displayName';
    }

    // 4) Derive from email as last resort
    final email = authUser?.email ?? '';
    print('🔍 Firebase Auth email: $email');
    if (email.contains('@')) {
      final raw = email
          .split('@')
          .first
          .replaceAll('.', ' ')
          .replaceAll('_', ' ')
          .trim();
      if (raw.isNotEmpty) {
        final derived = raw
            .split(' ')
            .map((w) => w.isEmpty
                ? w
                : (w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '')))
            .join(' ');
        if (derived.isNotEmpty) {
          print('🔍 Derived from email: $derived');
          return 'Dr. $derived';
        }
      }
    }

    // Final fallback
    print('❌ No name found, using fallback');
    return 'Dr. Unknown';
  }

  String _getDoctorSpecialization() {
    if (_doctorData != null && _doctorData!['specializations'] != null) {
      final specializations = _doctorData!['specializations'] as List?;
      if (specializations != null && specializations.isNotEmpty) {
        return specializations.first.toString();
      }
    }
    return 'General Medicine';
  }

  String _getDoctorLicense() {
    if (_doctorData != null) {
      return _doctorData!['licenseNumber'] ?? 'Not specified';
    }
    return 'Not specified';
  }

  String _getDoctorDegree() {
    if (_doctorData != null) {
      // Try direct field
      final direct = (_doctorData!['degree'] ?? '').toString().trim();
      if (direct.isNotEmpty) return _normalizeDegree(direct);

      // Try list field 'degrees'
      final degrees = _doctorData!['degrees'];
      if (degrees is List && degrees.isNotEmpty) {
        final first = degrees.first?.toString().trim() ?? '';
        if (first.isNotEmpty) return _normalizeDegree(first);
      }

      // Try education list with maps having 'degree'
      final education = _doctorData!['education'];
      if (education is List && education.isNotEmpty) {
        // Prefer the last (assume most recent) with non-empty degree
        for (final item in education.reversed) {
          if (item is Map && item['degree'] != null) {
            final deg = item['degree'].toString().trim();
            if (deg.isNotEmpty) return _normalizeDegree(deg);
          }
        }
      }
    }
    return '';
  }

  String _normalizeDegree(String degree) {
    final normalized = degree.toLowerCase().trim();

    // Common degree mappings
    switch (normalized) {
      case 'mmbs':
        return 'MBBS';
      case 'md':
        return 'MD';
      case 'fcps':
        return 'FCPS';
      case 'mrcp':
        return 'MRCP';
      case 'frcp':
        return 'FRCP';
      case 'ms':
        return 'MS';
      case 'mch':
        return 'MCh';
      case 'dm':
        return 'DM';
      default:
        // If it's already in proper format, just uppercase it
        return degree.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = provider.Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Summary'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        foregroundColor: const Color(0xFF0288D1),
        surfaceTintColor: isDarkMode ? Colors.grey[850] : Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0.5,
        centerTitle: true,
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('MedCon',
                          style: TextStyle(
                              fontFamily: 'Pacifico',
                              color: Color(0xFF0288D1),
                              fontSize: 26)),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_isLoadingDoctorData)
                            const Column(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(height: 4),
                                Text('Loading...',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            )
                          else ...[
                            Text(_getDoctorName(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(_getDoctorSpecialization(),
                                style: const TextStyle(fontSize: 13)),
                            Text('License #: ${_getDoctorLicense()}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 28, color: Color(0xFFE6F3FF)),
                  Row(
                    children: [
                      Expanded(
                          child: Text('Patient:\n${_getPatientName()}',
                              style: const TextStyle(fontSize: 14))),
                      Expanded(
                          child: Text(
                              'Date:\n${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                          child: Text('DOB:\n${_getPatientDOB()}',
                              style: const TextStyle(fontSize: 14))),
                      Expanded(
                          child: Text('Diagnosis:\n${_getPatientDiagnosis()}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                  const Divider(height: 28, color: Color(0xFFE6F3FF)),

                  // Medications
                  if (widget.selectedFormulas.isNotEmpty) ...[
                    const Text('Rx',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...List.generate(widget.selectedFormulas.length, (i) {
                      final med = widget.selectedFormulas[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${i + 1}. $med',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const Text('Sig: As prescribed by doctor',
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],

                  // Lab Tests
                  if (widget.labTests.isNotEmpty) ...[
                    const Text('Laboratory Tests',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    ...widget.labTests.map((test) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Row(
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 16)),
                              Text(test, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 10),
                  ],

                  // Guidelines
                  if (widget.guidelines.isNotEmpty) ...[
                    const Text('Special Instructions',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    ...widget.guidelines.map((guideline) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Row(
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(guideline,
                                    style: const TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 18),
                  ],

                  const Text('Electronically signed by',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(
                    children: [
                      Text(() {
                        final degree = _getDoctorDegree();
                        final suffix = degree.isNotEmpty ? ', ' + degree : '';
                        return _getDoctorName() + suffix;
                      }(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      Image.asset('assets/signature.png',
                          height: 32,
                          width: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_isSending) return;
                    setState(() { _isSending = true; });
                    try {
                      final user = ref.read(userProvider);
                      final doctorId = user?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
                      final requestId = (widget.patientData ?? const {})['id']?.toString() ?? '';

                      // Prepare a concise response text for history lists
                      final String responseText = [
                        if (widget.selectedFormulas.isNotEmpty)
                          'Medicines: ${widget.selectedFormulas.join(', ')}',
                        if (widget.labTests.isNotEmpty)
                          'Lab tests: ${widget.labTests.join(', ')}',
                        if (widget.guidelines.isNotEmpty)
                          'Advice: ${widget.guidelines.join(', ')}',
                      ].join(' \u2022 ');

                      // Update the consultation request with doctor's response and structured prescription
                      if (requestId.isNotEmpty) {
                        await _firestore
                            .collection('consultation_requests')
                            .doc(requestId)
                            .update({
                          'doctorResponseText': responseText,
                          'prescriptionMedicines': widget.selectedFormulas,
                          'prescriptionLabTests': widget.labTests,
                          'prescriptionGuidelines': widget.guidelines,
                          'respondedAt': FieldValue.serverTimestamp(),
                          'status': 'Completed',
                          'respondedBy': doctorId,
                        });
                      }

                      // Optional: also save a copy in prescriptions collection
                      await _firestore.collection('prescriptions').add({
                        'requestId': requestId,
                        'patientId': widget.patientData?['patientId'] ?? '',
                        'patientName': _getPatientName(),
                        'doctorId': doctorId,
                        'medicines': widget.selectedFormulas,
                        'labTests': widget.labTests,
                        'guidelines': widget.guidelines,
                        'createdAt': FieldValue.serverTimestamp(),
                        'status': 'sent',
                      });

                      // Create in-app notification for the patient
                      final String patientId = (widget.patientData ?? const {})['patientId']?.toString() ?? '';
                      if (patientId.isNotEmpty) {
                        await _firestore.collection('notifications').add({
                          'userId': patientId,
                          'type': 'doctor_response',
                          'requestId': requestId,
                          'message': 'Doctor responded to your consultation request',
                          'createdAt': FieldValue.serverTimestamp(),
                          'read': false,
                        });
                      }

                      // Navigate to success screen which redirects to dashboard
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const PrescriptionSentSuccessScreen(),
                        ),
                        (route) => false,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send: $e')),
                      );
                    } finally {
                      if (mounted) setState(() { _isSending = false; });
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Send to Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0288D1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: Color(0xFF0288D1)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
