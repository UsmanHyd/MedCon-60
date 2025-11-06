import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcon30/patient/profile/patient_dashboard.dart';
import 'diagnosis.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcon30/providers/disease_provider.dart';
import 'package:medcon30/services/app_history_service.dart';

class DiseaseDetectionScreen extends ConsumerStatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  ConsumerState<DiseaseDetectionScreen> createState() =>
      _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState
    extends ConsumerState<DiseaseDetectionScreen> {
  final List<String> allSymptoms = [
    'Headache',
    'Fever',
    'Cough',
    'Sore Throat',
    'Fatigue',
    'Nausea',
    'Dizziness',
    'Shortness of Breath',
    'Chest Pain',
    'Back Pain',
    'Joint Pain',
    'Rash',
    'Abdominal Pain',
  ];
  List<String> filteredSymptoms = [];
  TextEditingController searchController = TextEditingController();
  String? _lastSymptomCheckId;

  // Getter for selected symptoms from provider
  List<String> get selectedSymptoms {
    return ref.watch(symptomsProvider);
  }

  @override
  void initState() {
    super.initState();
    filteredSymptoms = List.from(allSymptoms);
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      filteredSymptoms = allSymptoms
          .where((symptom) => symptom
              .toLowerCase()
              .contains(searchController.text.toLowerCase()))
          .toList();
    });
  }

  void _toggleSymptom(String symptom) {
    final symptomsNotifier = ref.read(symptomsProvider.notifier);
    symptomsNotifier.toggleSymptom(symptom);
  }

  void _removeSymptom(String symptom) {
    final symptomsNotifier = ref.read(symptomsProvider.notifier);
    if (selectedSymptoms.contains(symptom)) {
      symptomsNotifier.toggleSymptom(symptom);
    }
  }

  void _addCustomSymptom() {
    if (searchController.text.trim().isNotEmpty) {
      final symptomsNotifier = ref.read(symptomsProvider.notifier);
      symptomsNotifier.addCustomSymptom(searchController.text.trim());
      searchController.clear();
      // Reset filtered symptoms to show all
      filteredSymptoms = List.from(allSymptoms);
    }
  }

  void _clearAllSymptoms() {
    final symptomsNotifier = ref.read(symptomsProvider.notifier);
    symptomsNotifier.clearSymptoms();
  }

  Future<List<Map<String, dynamic>>> _predictDiseases() async {
    try {
      // Use the disease provider for prediction
      final diseaseNotifier = ref.read(diseaseProvider.notifier);
      await diseaseNotifier.predictDisease(selectedSymptoms);

      // Get the prediction from the provider
      final diseaseState = ref.read(diseaseProvider);
      final predictions = diseaseState.value;

      if (predictions != null && predictions.predictions.isNotEmpty) {
        // Save the symptom check to Firestore (per user)
        try {
          final auth = FirebaseAuth.instance;
          final uid = auth.currentUser?.uid;
          if (uid != null) {
            final docRef = await FirebaseFirestore.instance
                .collection('symptom_checks')
                .add({
              'userId': uid,
              'symptoms': selectedSymptoms,
              'predictions': predictions.predictions
                  .map((pred) => {
                        'disease': pred.disease,
                        'confidence': (pred.confidence * 100).toInt(),
                        'matched_symptoms': pred.symptoms,
                        'treatments': pred.recommendations,
                        'status': 'AI Diagnosis',
                        'status_color': '#4CAF50',
                      })
                  .toList(),
              'createdAt': FieldValue.serverTimestamp(),
            });
            _lastSymptomCheckId = docRef.id;

            // Track the activity in app history
            AppHistoryService().trackDiseaseDetection(
              symptoms: selectedSymptoms,
              predictions: predictions.predictions
                  .map((pred) => {
                        'disease': pred.disease,
                        'confidence': (pred.confidence * 100).toInt(),
                        'matched_symptoms': pred.symptoms,
                        'treatments': pred.recommendations,
                        'status': 'AI Diagnosis',
                        'status_color': '#4CAF50',
                      })
                  .toList(),
            );
          }
        } catch (_) {}

        // Return the predictions in the expected format
        return predictions.predictions
            .map((pred) => {
                  'name': pred.disease,
                  'dotColor': const Color(0xFF4CAF50),
                  'percent': (pred.confidence * 100).toDouble(),
                  'desc': pred.description,
                  'status': 'AI Diagnosis',
                  'statusColor': const Color(0xFF4CAF50),
                })
            .toList();
      } else {
        throw Exception('No prediction available');
      }
    } catch (e) {
      print('Error predicting diseases: $e');
      throw Exception('Failed to get prediction: $e');
    }
  }

  // Removed unused helper methods - now using provider predictions

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.blueGrey[900];
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.blueGrey[700];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        surfaceTintColor: cardColor,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Disease Detection',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18.0),
            child: Icon(Icons.help_outline,
                color: isDarkMode ? Colors.blue[300] : const Color(0xFF2196F3),
                size: 20),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How are you feeling today?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter your symptoms to get potential diagnoses',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Type or search symptoms:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          style: TextStyle(
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search,
                                color: isDarkMode
                                    ? Colors.blue[300]
                                    : const Color(0xFF2196F3)),
                            hintText: 'Type any symptom or search...',
                            hintStyle: TextStyle(color: subTextColor),
                            filled: true,
                            fillColor:
                                isDarkMode ? Colors.grey[850] : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.grey[700]!
                                      : const Color(0xFFE0E3EA)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.grey[700]!
                                      : const Color(0xFFE0E3EA)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 12),
                          ),
                          onSubmitted: (value) => _addCustomSymptom(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addCustomSymptom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          minimumSize: const Size(60, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Or select from common symptoms:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final selectedSymptoms = ref.watch(symptomsProvider);
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: filteredSymptoms.map((symptom) {
                          final isSelected = selectedSymptoms.contains(symptom);
                          return GestureDetector(
                            onTap: () => _toggleSymptom(symptom),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2196F3)
                                    : isDarkMode
                                        ? Colors.grey[800]
                                        : const Color(0xFFF4F4F4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2196F3)
                                      : isDarkMode
                                          ? Colors.grey[600]!
                                          : const Color(0xFFE0E3EA),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                symptom,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final selectedSymptoms = ref.watch(symptomsProvider);
                      if (selectedSymptoms.isEmpty)
                        return const SizedBox.shrink();

                      return Column(
                        children: [
                          const SizedBox(height: 22),
                          Text(
                            'Selected Symptoms:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: selectedSymptoms
                                .map((symptom) => Chip(
                                      label: Text(
                                        symptom,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF2196F3),
                                        ),
                                      ),
                                      deleteIcon: Icon(Icons.close,
                                          size: 18,
                                          color: isDarkMode
                                              ? Colors.blue[300]
                                              : const Color(0xFF2196F3)),
                                      onDeleted: () => _removeSymptom(symptom),
                                      backgroundColor: isDarkMode
                                          ? Colors.grey[850]
                                          : const Color(0xFFE3F2FD),
                                      labelStyle: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF2196F3),
                                          fontWeight: FontWeight.w600),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: _clearAllSymptoms,
                                icon: Icon(
                                  Icons.clear_all,
                                  color: isDarkMode
                                      ? Colors.red[300]
                                      : Colors.red[600],
                                  size: 18,
                                ),
                                label: Text(
                                  'Clear All',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.red[300]
                                        : Colors.red[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // Removed prediction display - predictions now only show on the diagnosis screen

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final selectedSymptoms = ref.watch(symptomsProvider);
                        return ElevatedButton(
                          onPressed: selectedSymptoms.isNotEmpty
                              ? () async {
                                  // Show loading indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const CircularProgressIndicator(),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Analyzing symptoms...',
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'This may take a few moments',
                                              style: TextStyle(
                                                color: subTextColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );

                                  try {
                                    final predictions =
                                        await _predictDiseases();
                                    if (mounted) {
                                      Navigator.pop(
                                          context); // Close loading dialog

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DiagnosisScreen(
                                            predictions: predictions,
                                            symptomCheckId: _lastSymptomCheckId,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      Navigator.pop(
                                          context); // Close loading dialog
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedSymptoms.isNotEmpty
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
                            'Check for Potential Diagnoses',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
