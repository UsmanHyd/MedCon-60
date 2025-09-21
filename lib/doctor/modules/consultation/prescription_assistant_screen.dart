import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcon30/theme/theme_provider.dart';
import '/services/prescription_service.dart';
import '/providers/prescription_provider.dart';
import '/doctor/modules/consultation/prescription_draft_screen.dart';

class PrescriptionAssistantScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? patientData;
  const PrescriptionAssistantScreen({Key? key, this.patientData})
      : super(key: key);

  @override
  ConsumerState<PrescriptionAssistantScreen> createState() =>
      _PrescriptionAssistantScreenState();
}

class _PrescriptionAssistantScreenState
    extends ConsumerState<PrescriptionAssistantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // State variables
  List<String> detectedDiseases = [];
  Map<String, List<String>> diseaseDrugs = {};
  List<String> selectedFormulas = [];
  // recentlyPrescribed is now handled by Riverpod provider
  List<String> labTests = [];
  List<String> guidelines = [];
  TextEditingController searchController = TextEditingController();
  TextEditingController labTestController = TextEditingController();
  TextEditingController guidelineController = TextEditingController();
  bool isLoading = false;
  String? selectedDisease;
  Map<String, bool> diseaseLoadingStates = {}; // Track loading per disease

  // Search functionality
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
    _setupSearchListener();
  }

  void _setupSearchListener() {
    searchController.addListener(() {
      _searchTimer?.cancel();
      _searchTimer = Timer(const Duration(milliseconds: 500), () {
        _performSearch();
      });
    });
  }

  Future<void> _performSearch() async {
    final query = searchController.text.trim();

    if (query.length < 2) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final result = await PrescriptionService.searchFormulas(query, limit: 8);

      if (result['success'] == true) {
        setState(() {
          searchResults =
              List<Map<String, dynamic>>.from(result['formulas'] ?? []);
          isSearching = false;
        });
      } else {
        setState(() {
          searchResults = [];
          isSearching = false;
        });
      }
    } catch (e) {
      print('Error searching formulas: $e');
      setState(() {
        searchResults = [];
        isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    labTestController.dispose();
    guidelineController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);

    // Load detected diseases from patient data
    _loadDetectedDiseases();

    // Recently prescribed data is now loaded via Riverpod provider
    // No need to manually load it here

    setState(() => isLoading = false);
  }

  void _loadDetectedDiseases() {
    // Extract diseases from patient data
    if (widget.patientData != null) {
      // Debug: Print patient data structure
      print('Patient data keys: ${widget.patientData!.keys.toList()}');
      print('Prediction results: ${widget.patientData!['predictionResults']}');
      print(
          'Predicted diagnoses: ${widget.patientData!['predictedDiagnoses']}');

      List<String> diseases = [];

      // Check for AI-predicted diagnoses from Firebase (predictionResults field)
      if (widget.patientData!['predictionResults'] != null) {
        List<dynamic> predictionResults =
            widget.patientData!['predictionResults'];
        for (var prediction in predictionResults) {
          if (prediction is Map<String, dynamic>) {
            String diseaseName = prediction['disease']?.toString() ?? '';

            // Include all diseases regardless of confidence
            if (diseaseName.isNotEmpty) {
              diseases.add(diseaseName.toLowerCase().trim());
            }
          }
        }
      }

      // Also check for predictedDiagnoses field (fallback)
      if (widget.patientData!['predictedDiagnoses'] != null) {
        List<dynamic> predictedDiagnoses =
            widget.patientData!['predictedDiagnoses'];
        for (var diagnosis in predictedDiagnoses) {
          if (diagnosis is Map<String, dynamic>) {
            String diseaseName = diagnosis['disease']?.toString() ?? '';

            // Include all diseases regardless of probability
            if (diseaseName.isNotEmpty) {
              diseases.add(diseaseName.toLowerCase().trim());
            }
          }
        }
      }

      // Check for primary condition
      if (widget.patientData!['condition'] != null) {
        String condition =
            widget.patientData!['condition'].toString().toLowerCase().trim();
        if (condition.isNotEmpty && !diseases.contains(condition)) {
          diseases.add(condition);
        }
      }

      // Check for diagnosis field
      if (widget.patientData!['diagnosis'] != null) {
        String diagnosis =
            widget.patientData!['diagnosis'].toString().toLowerCase().trim();
        if (diagnosis.isNotEmpty && !diseases.contains(diagnosis)) {
          diseases.add(diagnosis);
        }
      }

      // Check for symptoms that might indicate diseases
      if (widget.patientData!['symptoms'] != null) {
        String symptoms = widget.patientData!['symptoms'].toString();
        if (symptoms.isNotEmpty) {
          // Parse symptoms and try to map to diseases
          List<String> symptomList =
              symptoms.split(',').map((s) => s.trim().toLowerCase()).toList();
          for (String symptom in symptomList) {
            if (symptom.isNotEmpty) {
              // You can add logic here to map specific symptoms to diseases
              // For now, we'll add common symptom-based conditions
              if (symptom.contains('headache') ||
                  symptom.contains('migraine')) {
                if (!diseases.contains('migraine')) diseases.add('migraine');
              }
              if (symptom.contains('shortness') || symptom.contains('breath')) {
                if (!diseases.contains('respiratory condition'))
                  diseases.add('respiratory condition');
              }
              if (symptom.contains('dizziness') ||
                  symptom.contains('vertigo')) {
                if (!diseases.contains('dizziness')) diseases.add('dizziness');
              }
            }
          }
        }
      }

      // Check for medical history
      if (widget.patientData!['medicalHistory'] != null) {
        String history = widget.patientData!['medicalHistory'].toString();
        if (history.isNotEmpty) {
          // Parse medical history for known conditions
          String lowerHistory = history.toLowerCase();
          if (lowerHistory.contains('hypertension') &&
              !diseases.contains('hypertension')) {
            diseases.add('hypertension');
          }
          if (lowerHistory.contains('diabetes') &&
              !diseases.contains('diabetes')) {
            diseases.add('diabetes');
          }
          if (lowerHistory.contains('asthma') && !diseases.contains('asthma')) {
            diseases.add('asthma');
          }
        }
      }

      // Check for consultation notes
      if (widget.patientData!['consultationNotes'] != null) {
        String notes = widget.patientData!['consultationNotes'].toString();
        if (notes.isNotEmpty) {
          // Parse consultation notes for disease mentions
          String lowerNotes = notes.toLowerCase();
          if (lowerNotes.contains('carbon monoxide') &&
              !diseases.contains('carbon monoxide poisoning')) {
            diseases.add('carbon monoxide poisoning');
          }
          if (lowerNotes.contains('panic') &&
              !diseases.contains('panic disorder')) {
            diseases.add('panic disorder');
          }
          if (lowerNotes.contains('hemorrhage') &&
              !diseases.contains('subdural hemorrhage')) {
            diseases.add('subdural hemorrhage');
          }
          if (lowerNotes.contains('heart block') &&
              !diseases.contains('heart block')) {
            diseases.add('heart block');
          }
        }
      }

      // Check for previous consultations and their conditions
      if (widget.patientData!['previousConsultations'] != null) {
        List<dynamic> previousConsultations =
            widget.patientData!['previousConsultations'];
        for (var consultation in previousConsultations) {
          if (consultation is Map<String, dynamic>) {
            String consultationType = consultation['type']?.toString() ?? '';
            if (consultationType.isNotEmpty) {
              String condition = consultationType.toLowerCase().trim();
              if (!diseases.contains(condition)) {
                diseases.add(condition);
              }
            }
          }
        }
      }

      // If still no diseases found, add some common ones for testing
      if (diseases.isEmpty) {
        diseases.addAll(['migraine', 'hypertension', 'diabetes', 'asthma']);
      }

      // Remove duplicates and empty strings
      detectedDiseases =
          diseases.where((disease) => disease.isNotEmpty).toSet().toList();
    } else {
      // Fallback if no patient data - add some sample diseases for testing
      detectedDiseases = ['migraine', 'hypertension', 'diabetes', 'asthma'];
    }
  }

  Future<void> _loadDrugsForDisease(String disease) async {
    setState(() {
      diseaseLoadingStates[disease] = true;
    });

    try {
      print('🚀 Fetching drugs for $disease (fast mode)');
      final result = await PrescriptionService.getDrugsForDisease(disease);

      if (result['success'] == true) {
        setState(() {
          diseaseDrugs[disease] = List<String>.from(result['drugs'] ?? []);
          diseaseLoadingStates[disease] = false;
        });
        print(
            '✅ Successfully loaded ${result['drugs']?.length ?? 0} drugs for $disease');
      } else {
        setState(() {
          diseaseDrugs[disease] = [];
          diseaseLoadingStates[disease] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'No drugs found')),
        );
      }
    } catch (e) {
      print('❌ Error loading drugs for $disease: $e');
      setState(() {
        diseaseDrugs[disease] = [];
        diseaseLoadingStates[disease] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading drugs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addSelectedFormula(String formula) {
    if (!selectedFormulas.contains(formula)) {
      setState(() {
        selectedFormulas.add(formula);
      });
    }
  }

  void _removeSelectedFormula(String formula) {
    setState(() {
      selectedFormulas.remove(formula);
    });
  }

  void _addManualFormula() {
    final formula = searchController.text.trim();
    if (formula.isNotEmpty) {
      _addSelectedFormula(formula);
      searchController.clear();
    }
  }

  void _addManualDisease() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController diseaseController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Disease'),
          content: TextField(
            controller: diseaseController,
            decoration: const InputDecoration(
              hintText: 'Enter disease name...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final disease = diseaseController.text.trim().toLowerCase();
                if (disease.isNotEmpty && !detectedDiseases.contains(disease)) {
                  setState(() {
                    detectedDiseases.add(disease);
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addLabTest() {
    final test = labTestController.text.trim();
    if (test.isNotEmpty && !labTests.contains(test)) {
      setState(() {
        labTests.add(test);
        labTestController.clear();
      });
    }
  }

  void _removeLabTest(String test) {
    setState(() {
      labTests.remove(test);
    });
  }

  void _addGuideline() {
    final guideline = guidelineController.text.trim();
    if (guideline.isNotEmpty && !guidelines.contains(guideline)) {
      setState(() {
        guidelines.add(guideline);
        guidelineController.clear();
      });
    }
  }

  void _removeGuideline(String guideline) {
    setState(() {
      guidelines.remove(guideline);
    });
  }

  String _getPatientName() {
    if (widget.patientData != null) {
      return widget.patientData!['patientName'] ?? 'Unknown Patient';
    }
    return 'Harper Reynolds'; // fallback
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
    return 'HR'; // fallback
  }

  ImageProvider? _getPatientProfileImage() {
    if (widget.patientData != null) {
      // Debug: Print available fields
      print('🔍 Patient data keys: ${widget.patientData!.keys.toList()}');

      // Use the same field names as patient details screen
      final String avatarUrl = (widget.patientData!['profilePic'] ??
              widget.patientData!['photoUrl'] ??
              widget.patientData!['avatarUrl'] ??
              widget.patientData!['patientAvatarUrl'] ??
              widget.patientData!['profileImageUrl'] ??
              widget.patientData!['profileImage'] ??
              widget.patientData!['imageUrl'] ??
              '')
          .toString();

      print('🖼️ Avatar URL found: $avatarUrl');

      if (avatarUrl.isNotEmpty) {
        return NetworkImage(avatarUrl);
      }

      // Check for profile image path
      final profileImagePath = widget.patientData!['profileImagePath'] ??
          widget.patientData!['imagePath'] ??
          widget.patientData!['photoPath'];

      if (profileImagePath != null && profileImagePath.toString().isNotEmpty) {
        return AssetImage(profileImagePath.toString());
      }

      // Check for base64 encoded image
      final base64Image = widget.patientData!['profileImageBase64'] ??
          widget.patientData!['imageBase64'];

      if (base64Image != null && base64Image.toString().isNotEmpty) {
        try {
          return MemoryImage(base64Decode(base64Image.toString()));
        } catch (e) {
          print('Error decoding base64 image: $e');
        }
      }
    }
    return null; // No profile image found, will show initials
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
    return '42 years • Female • Migraine'; // fallback
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = provider.Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Assistant'),
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
      body: Column(
        children: [
          // Patient header
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildPatientHeader(isDarkMode),
          ),

          // Tab Bar
          Container(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0288D1),
              unselectedLabelColor:
                  isDarkMode ? Colors.grey[400] : Colors.grey[600],
              indicatorColor: const Color(0xFF0288D1),
              tabs: const [
                Tab(
                  icon: Icon(Icons.medication),
                  text: 'Medicines',
                ),
                Tab(
                  icon: Icon(Icons.science),
                  text: 'Lab Tests',
                ),
                Tab(
                  icon: Icon(Icons.rule),
                  text: 'Guidelines',
                ),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Medicines Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recommended Formulas Section
                      _buildRecommendedFormulasSection(isDarkMode),
                      const SizedBox(height: 20),

                      // Search for Manual Addition
                      _buildSearchSection(isDarkMode),
                      const SizedBox(height: 20),

                      // Recently Prescribed Section
                      _buildRecentlyPrescribedSection(isDarkMode),
                      const SizedBox(height: 20),

                      // Selected Formulas Section
                      _buildSelectedFormulasSection(isDarkMode),
                    ],
                  ),
                ),

                // Lab Tests Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildLabTestsSection(isDarkMode),
                ),

                // Guidelines Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildGuidelinesSection(isDarkMode),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientHeader(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF0288D1),
            backgroundImage: _getPatientProfileImage(),
            child: _getPatientProfileImage() == null
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0288D1),
                    ),
                    child: Center(
                      child: Text(
                        _getPatientInitials(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPatientName(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getPatientDetails(),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrescriptionDraftScreen(
                    patientData: widget.patientData,
                    selectedFormulas: selectedFormulas,
                    labTests: labTests,
                    guidelines: guidelines,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('View Draft'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedFormulasSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Formulas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          detectedDiseases.isEmpty
              ? 'No diseases detected from patient data'
              : '${detectedDiseases.length} detected diseases',
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        if (detectedDiseases.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'No diseases detected from patient consultation data.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _addManualDisease,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Disease Manually'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...detectedDiseases
              .map((disease) => _buildDiseaseDropdown(disease, isDarkMode)),
      ],
    );
  }

  Widget _buildDiseaseDropdown(String disease, bool isDarkMode) {
    final drugs = diseaseDrugs[disease] ?? [];
    final probability = _getDiseaseProbability(disease);
    final isExpanded = selectedDisease == disease;
    final isDiseaseLoading = diseaseLoadingStates[disease] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Disease Header Box
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isExpanded
                  ? const Color(0xFF0288D1).withOpacity(0.1)
                  : (isDarkMode ? Colors.grey[800] : Colors.grey[50]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: isExpanded
                  ? Border.all(
                      color: const Color(0xFF0288D1).withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  print('🖱️ Tapped on disease: $disease');
                  print('🔄 Current selectedDisease: $selectedDisease');
                  print('📊 Is expanded: $isExpanded');

                  setState(() {
                    selectedDisease = isExpanded ? null : disease;
                  });

                  if (!isExpanded && drugs.isEmpty) {
                    print('📡 Loading drugs for $disease...');
                    _loadDrugsForDisease(disease);
                  }
                },
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                splashColor: const Color(0xFF0288D1).withOpacity(0.1),
                highlightColor: const Color(0xFF0288D1).withOpacity(0.05),
                child: Row(
                  children: [
                    // Disease Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0288D1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medical_services,
                        color: const Color(0xFF0288D1),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Disease Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disease.toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            probability > 0
                                ? 'AI Prediction: ${(probability * 100).toInt()}%'
                                : 'Disease detected from patient data',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to view recommended formulas',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.grey[500]
                                  : Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dropdown Arrow
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0288D1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF0288D1),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Dropdown Content
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Formulas:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isDiseaseLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (drugs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[600]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No formulas found for this disease in the database',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...drugs.map((drug) => _buildDrugItem(drug, isDarkMode)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  double _getDiseaseProbability(String disease) {
    if (widget.patientData != null) {
      // Check predictionResults first (Firebase data)
      if (widget.patientData!['predictionResults'] != null) {
        List<dynamic> predictionResults =
            widget.patientData!['predictionResults'];
        for (var prediction in predictionResults) {
          if (prediction is Map<String, dynamic>) {
            String diseaseName =
                prediction['disease']?.toString().toLowerCase().trim() ?? '';
            if (diseaseName == disease.toLowerCase().trim()) {
              int confidence = prediction['confidence']?.toInt() ?? 0;
              return confidence / 100.0; // Convert percentage to decimal
            }
          }
        }
      }

      // Fallback to predictedDiagnoses field
      if (widget.patientData!['predictedDiagnoses'] != null) {
        List<dynamic> predictedDiagnoses =
            widget.patientData!['predictedDiagnoses'];
        for (var diagnosis in predictedDiagnoses) {
          if (diagnosis is Map<String, dynamic>) {
            String diseaseName =
                diagnosis['disease']?.toString().toLowerCase().trim() ?? '';
            if (diseaseName == disease.toLowerCase().trim()) {
              return diagnosis['probability']?.toDouble() ?? 0.0;
            }
          }
        }
      }
    }
    return 0.0;
  }

  Widget _buildDrugItem(String drug, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.medication,
            color: const Color(0xFF0288D1),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              drug,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.add_circle_outline, color: Color(0xFF0288D1)),
            onPressed: () => _addSelectedFormula(drug),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Medication Manually',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Start typing to search available formulas from the database',
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),

        // Search input with results
        Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search medication (e.g., Paracetamol, Ibuprofen)...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[850] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Color(0xFF0288D1), width: 2),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                suffixIcon: isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                searchResults = [];
                              });
                            },
                          )
                        : null,
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),

            // Search results
            if (searchResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medication_rounded,
                            color: const Color(0xFF0288D1),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Available Formulas (${searchResults.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final formula = searchResults[index];
                          final name = formula['name'] ?? '';
                          final score = (formula['score'] ?? 0).toInt();

                          return _buildSearchResultItem(
                              name, score, isDarkMode);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Manual add button
            if (searchController.text.isNotEmpty &&
                searchResults.isEmpty &&
                !isSearching) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _addManualFormula,
                  icon: const Icon(Icons.add_rounded),
                  label: Text('Add "${searchController.text}"'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(String name, int score, bool isDarkMode) {
    return InkWell(
      onTap: () {
        searchController.text = name;
        _addSelectedFormula(name);
        setState(() {
          searchResults = [];
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0288D1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: Color(0xFF0288D1),
                size: 16,
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
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Match: ${score}%',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: const Color(0xFF0288D1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyPrescribedSection(bool isDarkMode) {
    // Get patient ID for the provider
    final patientId = widget.patientData?['patientId']?.toString() ?? '';

    if (patientId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recently Prescribed',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Text(
              'No patient ID available',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    // Use Riverpod provider to get recently prescribed medications
    final recentlyPrescribedMedications =
        ref.watch(recentlyPrescribedMedicationsProvider(patientId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Prescribed',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (recentlyPrescribedMedications.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Text(
              'No recent prescriptions found',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...recentlyPrescribedMedications
              .map((med) => _buildRecentMedItem(med, isDarkMode)),
      ],
    );
  }

  Widget _buildRecentMedItem(
      RecentlyPrescribedMedication medication, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: const Color(0xFF0288D1),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  medication.name,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: Color(0xFF0288D1)),
                onPressed: () => _addSelectedFormula(medication.name),
              ),
            ],
          ),
          if (medication.dose != null) ...[
            const SizedBox(height: 4),
            Text(
              'Dose: ${medication.dose}',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
          if (medication.description != null) ...[
            const SizedBox(height: 2),
            Text(
              medication.description!,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Prescribed by: ${medication.doctorName}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${medication.prescribedAt.day}/${medication.prescribedAt.month}/${medication.prescribedAt.year}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFormulasSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Formulas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (selectedFormulas.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Text(
              'No formulas selected yet',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...selectedFormulas
              .map((formula) => _buildSelectedFormulaItem(formula, isDarkMode)),
      ],
    );
  }

  Widget _buildSelectedFormulaItem(String formula, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0288D1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0288D1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFF0288D1),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              formula,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _removeSelectedFormula(formula),
          ),
        ],
      ),
    );
  }

  // Lab Tests Section
  Widget _buildLabTestsSection(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Colors.grey[850]!, Colors.grey[800]!]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0288D1).withOpacity(0.1),
                  const Color(0xFF0288D1).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: Color(0xFF0288D1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laboratory Tests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add recommended lab tests for patient',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${labTests.length}',
                    style: const TextStyle(
                      color: Color(0xFF0288D1),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Input section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: labTestController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText:
                        'Enter lab test name (e.g., Complete Blood Count, Lipid Profile)...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[700] : Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _addLabTest,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lab tests list
          if (labTests.isEmpty)
            _buildEmptyState(
              'No lab tests added yet',
              'Add laboratory tests to help diagnose and monitor the patient\'s condition',
              Icons.science_outlined,
              isDarkMode,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Added Tests (${labTests.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                ...labTests.asMap().entries.map((entry) {
                  final index = entry.key;
                  final test = entry.value;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _buildLabTestItem(test, isDarkMode, index),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  // Guidelines Section
  Widget _buildGuidelinesSection(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Colors.grey[850]!, Colors.grey[800]!]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.1),
                  const Color(0xFF4CAF50).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rule_rounded,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Guidelines',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add treatment guidelines and recommendations',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${guidelines.length}',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Input section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: guidelineController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Enter clinical guideline (e.g., Monitor blood pressure weekly, Follow up in 2 weeks)...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[700] : Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(
                      Icons.edit_note_rounded,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _addGuideline,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Guideline'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Guidelines list
          if (guidelines.isEmpty)
            _buildEmptyState(
              'No guidelines added yet',
              'Add clinical guidelines and recommendations for patient care',
              Icons.rule_outlined,
              isDarkMode,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Added Guidelines (${guidelines.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                ...guidelines.asMap().entries.map((entry) {
                  final index = entry.key;
                  final guideline = entry.value;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _buildGuidelineItem(guideline, isDarkMode, index),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState(
      String title, String subtitle, IconData icon, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Lab test item widget
  Widget _buildLabTestItem(String test, bool isDarkMode, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Colors.grey[800]!, Colors.grey[750]!]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0288D1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.bloodtype_rounded,
              color: Color(0xFF0288D1),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Laboratory Test',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeLabTest(test),
            icon: const Icon(
              Icons.remove_circle_rounded,
              color: Colors.red,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Guideline item widget
  Widget _buildGuidelineItem(String guideline, bool isDarkMode, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Colors.grey[800]!, Colors.grey[750]!]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guideline,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Clinical Guideline',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeGuideline(guideline),
            icon: const Icon(
              Icons.remove_circle_rounded,
              color: Colors.red,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
