import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'search_doctor.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/providers/disease_provider.dart';

class DiagnosisScreen extends ConsumerWidget {
  final List<Map<String, dynamic>> diagnoses;
  final String? symptomCheckId;

  DiagnosisScreen(
      {super.key, List<Map<String, dynamic>>? predictions, this.symptomCheckId})
      : diagnoses = predictions ?? [];

  // Helper method to get threshold color based on confidence score
  Color _getThresholdColor(double confidence) {
    if (confidence >= 0.7) {
      return Colors.red;
    } else if (confidence >= 0.5) {
      return Colors.orange;
    } else if (confidence >= 0.3) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  // Helper method to get threshold text based on confidence score
  String _getThresholdText(double confidence) {
    if (confidence >= 0.7) {
      return 'High Risk - Emergency';
    } else if (confidence >= 0.5) {
      return 'Medium Risk - Urgent';
    } else if (confidence >= 0.3) {
      return 'Low Risk - Monitor';
    } else {
      return 'Very Low Risk';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 20,
                        color:
                            isDarkMode ? Colors.white : Colors.blueGrey[900]),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Potential Diagnoses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color:
                              isDarkMode ? Colors.white : Colors.blueGrey[900],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Based on your symptoms:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.blueGrey[900],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Display disease prediction state from provider
                  Consumer(
                    builder: (context, ref, child) {
                      final diseaseState = ref.watch(diseaseProvider);
                      
                      return diseaseState.when(
                        data: (predictions) {
                          if (predictions != null && predictions.predictions.isNotEmpty) {
                            return Column(
                              children: predictions.predictions.asMap().entries.map((entry) {
                                final index = entry.key;
                                final prediction = entry.value;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.blue[600],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.psychology,
                                            color: Colors.blue[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'AI Prediction',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.blue[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        prediction.disease,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getThresholdColor(prediction.confidence),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getThresholdText(prediction.confidence),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Matched Symptoms:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        prediction.symptoms.join(', '),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Recommendations:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...prediction.recommendations.map((rec) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '• ',
                                              style: TextStyle(
                                                color: Colors.blue[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                rec,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[850]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.orange[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Analyzing symptoms...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        error: (error, stack) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode ? Colors.grey[850] : Colors.red[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.red[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: isDarkMode
                                    ? Colors.red[300]
                                    : Colors.red[600],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Error: $error',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Removed old diagnoses display - now only showing blue boxes with symptoms and recommendations
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : const Color(0xFFB0BEC5),
                          width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: isDarkMode
                                ? Colors.blue[300]
                                : const Color(0xFF2196F3),
                            size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This is not a medical diagnosis. Please consult with a healthcare professional.',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.blueGrey[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchDoctorScreen(
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
                        'Search for Doctor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
