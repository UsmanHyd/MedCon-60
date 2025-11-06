import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/providers/stress_provider.dart';
import 'stress_module.dart';

class SurveyScreen extends ConsumerStatefulWidget {
  const SurveyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  final List<Map<String, dynamic>> _questions = [
    {
      'question':
          'How often do you feel unable to manage the demands placed on you (e.g., work, study, family)?',
      'value': 0,
    },
    {
      'question':
          'How frequently do you experience difficulty in relaxing or unwinding after your day?',
      'value': 0,
    },
    {
      'question':
          'How often do you notice physical symptoms such as headaches, muscle tension, or fatigue during periods of high workload?',
      'value': 0,
    },
    {
      'question':
          'How often do you find yourself feeling anxious, worried, or mentally preoccupied?',
      'value': 0,
    },
    {
      'question':
          'How frequently does stress affect your ability to concentrate or make decisions?',
      'value': 0,
    },
    {
      'question':
          'How often do you feel emotionally exhausted or mentally drained at the end of the day?',
      'value': 0,
    },
  ];

  final List<String> _responseOptions = [
    'Not at all',
    'Rarely',
    'Sometimes',
    'Often',
    'Very frequently',
  ];

  void _submitSurvey() {
    // Calculate total score
    int totalScore =
        _questions.fold(0, (sum, question) => sum + (question['value'] as int));

    // Get stress level
    String stressLevel = _getStressLevel(totalScore);
    bool isHighStress = stressLevel != 'Low Stress Level';

    // Convert score to 1-10 scale for the provider
    int providerScore = ((totalScore / 30) * 10).round().clamp(1, 10);
    
    // Get selected symptoms (questions with value > 0)
    List<String> selectedSymptoms = [];
    for (int i = 0; i < _questions.length; i++) {
      if (_questions[i]['value'] > 0) {
        selectedSymptoms.add(_questions[i]['question']);
      }
    }

    // Create and save stress entry using the provider
    final stressEntry = StressData.create(
      score: providerScore,
      symptoms: selectedSymptoms,
      notes: 'Survey score: $totalScore/30',
    );
    
    // Save to provider
    ref.read(stressProvider.notifier).addStressEntry(stressEntry);

    // Show results dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Survey Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Score: $totalScore',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              stressLevel,
              style: TextStyle(
                color: _getStressLevelColor(totalScore),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (isHighStress) ...[
              const SizedBox(height: 16),
              const Text(
                'Your stress level is elevated. We recommend trying some stress relief techniques to help manage your stress.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (isHighStress)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: const Text('Stress Modules'),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                        foregroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        surfaceTintColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                      ),
                      body: const StressModulesScreen(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Stress Relief Techniques'),
            ),
        ],
      ),
    );
  }

  String _getStressLevel(int score) {
    if (score <= 12) return 'Low Stress Level';
    if (score <= 18) return 'Moderate Stress Level';
    if (score <= 24) return 'High Stress Level';
    return 'Very High Stress Level';
  }

  Color _getStressLevelColor(int score) {
    if (score <= 12) return Colors.green;
    if (score <= 18) return Colors.orange;
    if (score <= 24) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFE3F2FD);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor =
        isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF757575);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stress Assessment Survey'),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: cardColor,
      ),
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDarkMode
                                ? Colors.lightBlue[200]
                                : const Color(0xFF1976D2),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Understanding Your Stress Level',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.lightBlue[200]
                                    : const Color(0xFF1976D2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your stress level is calculated based on your total score:',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildScoreRange(
                          'Low Stress Level', '0-12', Colors.green),
                      _buildScoreRange(
                          'Moderate Stress Level', '13-18', Colors.orange),
                      _buildScoreRange(
                          'High Stress Level', '19-24', Colors.deepOrange),
                      _buildScoreRange(
                          'Very High Stress Level', '25-30', Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        'Each question is scored from 1 to 5, with 5 indicating the highest level of stress.',
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Response Scale:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.lightBlue[200]
                              : const Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                        _responseOptions.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Text(
                                '${index + 1} = ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                _responseOptions[index],
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                _questions.length,
                (index) => Card(
                  color: cardColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.lightBlue[200]
                                : const Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _questions[index]['question'],
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: List.generate(
                            _responseOptions.length,
                            (optionIndex) => ChoiceChip(
                              label: Text('${optionIndex + 1}'),
                              selected:
                                  _questions[index]['value'] == optionIndex + 1,
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFF1976D2),
                              labelStyle: TextStyle(
                                color: _questions[index]['value'] ==
                                        optionIndex + 1
                                    ? Colors.white
                                    : const Color(0xFF1976D2),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _questions[index]['value'] =
                                      selected ? optionIndex + 1 : 0;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _submitSurvey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode ? Colors.grey[850] : const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Survey',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRange(String level, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              level,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($range)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
