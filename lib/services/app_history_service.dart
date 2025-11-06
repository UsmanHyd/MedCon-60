import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_history.dart';

class AppHistoryService {
  static final AppHistoryService _instance = AppHistoryService._internal();
  factory AppHistoryService() => _instance;
  AppHistoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Track disease detection activity
  Future<void> trackDiseaseDetection({
    required List<String> symptoms,
    required List<Map<String, dynamic>> predictions,
  }) async {
    if (currentUserId == null) return;

    final activity = AppHistoryActivity.create(
      userId: currentUserId!,
      type: ActivityType.diseaseDetection,
      title: 'Disease Detection Check',
      description: 'Checked symptoms: ${symptoms.join(', ')}',
      resultSummary: 'Found ${predictions.length} possible conditions',
      metadata: {
        'symptoms': symptoms,
        'predictions_count': predictions.length,
        'top_prediction':
            predictions.isNotEmpty ? predictions.first['disease'] : null,
      },
    );

    await _saveActivity(activity);
  }

  // Track vaccine reminder creation
  Future<void> trackVaccineReminder({
    required String vaccineName,
    required List<String> dates,
    String? notes,
  }) async {
    if (currentUserId == null) return;

    final activity = AppHistoryActivity.create(
      userId: currentUserId!,
      type: ActivityType.vaccineReminder,
      title: 'Vaccine Reminder Created',
      description: 'Set reminder for $vaccineName',
      resultSummary: 'Reminder set for ${dates.length} date(s)',
      metadata: {
        'vaccine_name': vaccineName,
        'dates': dates,
        'notes': notes,
      },
    );

    await _saveActivity(activity);
  }

  // Track stress monitoring activity
  Future<void> trackStressMonitoring({
    required int score,
    required List<String> symptoms,
    String? notes,
  }) async {
    if (currentUserId == null) return;

    final activity = AppHistoryActivity.create(
      userId: currentUserId!,
      type: ActivityType.stressMonitoring,
      title: 'Stress Level Recorded',
      description: 'Stress score: $score/10',
      resultSummary: 'Stress level: ${_getStressLevelText(score)}',
      metadata: {
        'stress_score': score,
        'symptoms': symptoms,
        'notes': notes,
      },
    );

    await _saveActivity(activity);
  }

  // Track heart disease detection
  Future<void> trackHeartDiseaseDetection({
    required Map<String, dynamic> inputData,
    required String result,
    required double confidence,
  }) async {
    if (currentUserId == null) return;

    final activity = AppHistoryActivity.create(
      userId: currentUserId!,
      type: ActivityType.heartDiseaseDetection,
      title: 'Heart Disease Check',
      description: 'Heart health assessment completed',
      resultSummary:
          'Result: $result (${(confidence * 100).toStringAsFixed(1)}% confidence)',
      metadata: {
        'input_data': inputData,
        'result': result,
        'confidence': confidence,
      },
    );

    await _saveActivity(activity);
  }

  // Track nutrition/fitness activity
  Future<void> trackNutritionFitness({
    required String activityType,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    if (currentUserId == null) return;

    final activity = AppHistoryActivity.create(
      userId: currentUserId!,
      type: ActivityType.nutritionFitness,
      title: 'Nutrition & Fitness',
      description: description,
      resultSummary: 'Activity: $activityType',
      metadata: {
        'activity_type': activityType,
        'details': details,
      },
    );

    await _saveActivity(activity);
  }

  // Track SOS message
  Future<void> trackSosMessage({
    required String message,
    required String recipient,
  }) async {
    if (currentUserId == null) return;

    final activity = AppHistoryActivity.create(
      userId: currentUserId!,
      type: ActivityType.sosMessage,
      title: 'SOS Message Sent',
      description: 'Emergency message sent to $recipient',
      resultSummary: 'SOS message delivered',
      metadata: {
        'message': message,
        'recipient': recipient,
      },
    );

    await _saveActivity(activity);
  }

  // Track consultation request
  Future<void> trackConsultationRequest({
    required String doctorName,
    required String reason,
    String? symptoms,
  }) async {
    if (currentUserId == null) return;

    final activity = AppHistoryActivity.create(
      userId: currentUserId!,
      type: ActivityType.consultationRequest,
      title: 'Consultation Requested',
      description: 'Requested consultation with $doctorName',
      resultSummary: 'Consultation request submitted',
      metadata: {
        'doctor_name': doctorName,
        'reason': reason,
        'symptoms': symptoms,
      },
    );

    await _saveActivity(activity);
  }

  // Track profile update
  Future<void> trackProfileUpdate({
    required List<String> updatedFields,
  }) async {
    if (currentUserId == null) return;

    final activity = AppHistoryActivity.create(
      userId: currentUserId!,
      type: ActivityType.profileUpdate,
      title: 'Profile Updated',
      description: 'Updated profile information',
      resultSummary: 'Updated: ${updatedFields.join(', ')}',
      metadata: {
        'updated_fields': updatedFields,
      },
    );

    await _saveActivity(activity);
  }

  // Track chatbot interaction
  Future<void> trackChatbotInteraction({
    required String message,
    required String response,
    required int messageCount,
  }) async {
    if (currentUserId == null) return;

    final activity = AppHistoryActivity.create(
      userId: currentUserId!,
      type: ActivityType.chatbotInteraction,
      title: 'Chatbot Conversation',
      description: 'Chatbot interaction completed',
      resultSummary: 'Exchanged $messageCount messages',
      metadata: {
        'user_message': message,
        'bot_response': response,
        'message_count': messageCount,
      },
    );

    await _saveActivity(activity);
  }

  // Save activity to Firestore
  Future<void> _saveActivity(AppHistoryActivity activity) async {
    try {
      await _firestore.collection('app_history').add(activity.toFirestore());
      print('Activity tracked: ${activity.title}');
    } catch (e) {
      print('Error tracking activity in Firestore: $e');
      // Don't throw error, just log it
      // This allows the app to continue working even if tracking fails
    }
  }

  // Helper method to get stress level text
  String _getStressLevelText(int score) {
    if (score <= 3) return 'Low';
    if (score <= 6) return 'Moderate';
    if (score <= 8) return 'High';
    return 'Very High';
  }
}
