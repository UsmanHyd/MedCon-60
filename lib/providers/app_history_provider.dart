import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_history.dart';

// App history state notifier
class AppHistoryNotifier
    extends StateNotifier<AsyncValue<List<AppHistoryActivity>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  AppHistoryNotifier(this._userId) : super(const AsyncValue.loading()) {
    _loadAppHistory();
  }

  List<AppHistoryActivity> get activities => state.value ?? [];

  Future<void> _loadAppHistory() async {
    try {
      state = const AsyncValue.loading();

      // First try to load from app_history collection
      List<AppHistoryActivity> activities = [];

      try {
        final querySnapshot = await _firestore
            .collection('app_history')
            .where('userId', isEqualTo: _userId)
            .orderBy('timestamp', descending: true)
            .get();

        activities = querySnapshot.docs
            .map((doc) => AppHistoryActivity.fromFirestore(doc))
            .toList();
      } catch (e) {
        print('App history collection not accessible: $e');
      }

      // If no app history data, load from existing collections
      if (activities.isEmpty) {
        activities = await _loadFromExistingCollections();
      }

      state = AsyncValue.data(activities);
    } catch (e) {
      print('Error loading app history: $e');
      state = const AsyncValue.data([]);
    }
  }

  Future<List<AppHistoryActivity>> _loadFromExistingCollections() async {
    List<AppHistoryActivity> activities = [];

    try {
      // Load disease detection data
      final symptomChecks = await _firestore
          .collection('symptom_checks')
          .where('userId', isEqualTo: _userId)
          .get();

      for (final doc in symptomChecks.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final activity = AppHistoryActivity.create(
            userId: _userId,
            type: ActivityType.diseaseDetection,
            title: 'Disease Detection Check',
            description:
                'Checked symptoms: ${(data['symptoms'] as List<dynamic>).join(', ')}',
            resultSummary:
                'Found ${(data['predictions'] as List<dynamic>).length} possible conditions',
            metadata: {
              'symptoms': data['symptoms'],
              'predictions': data['predictions'],
              'source': 'existing_data',
            },
            notes: 'From existing symptom check',
          );

          // Set the original timestamp
          final originalTimestamp = (data['createdAt'] as Timestamp).toDate();
          final migratedActivity =
              activity.copyWith(timestamp: originalTimestamp);

          activities.add(migratedActivity);
        }
      }

      // Load vaccine reminder data
      final vaccineReminders = await _firestore
          .collection('vaccination_reminders')
          .where('userId', isEqualTo: _userId)
          .get();

      for (final doc in vaccineReminders.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final activity = AppHistoryActivity.create(
            userId: _userId,
            type: ActivityType.vaccineReminder,
            title: 'Vaccine Reminder Created',
            description: 'Set reminder for ${data['name']}',
            resultSummary:
                'Reminder set for ${(data['dates'] as List<dynamic>).length} date(s)',
            metadata: {
              'vaccine_name': data['name'],
              'dates': data['dates'],
              'status': data['status'],
              'source': 'existing_data',
            },
            notes: 'From existing vaccine reminder',
          );

          // Set the original timestamp
          final originalTimestamp = (data['createdAt'] as Timestamp).toDate();
          final migratedActivity =
              activity.copyWith(timestamp: originalTimestamp);

          activities.add(migratedActivity);
        }
      }

      // Load SOS alerts data
      final sosAlerts = await _firestore
          .collection('sosAlerts')
          .where('userId', isEqualTo: _userId)
          .get();

      for (final doc in sosAlerts.docs) {
        final data = doc.data();
        final ts = data['timestamp'];
        if (ts != null && ts is Timestamp) {
          final activity = AppHistoryActivity.create(
            userId: _userId,
            type: ActivityType.sosMessage,
            title: 'SOS Message Sent',
            description: 'Emergency SOS alert sent',
            resultSummary: 'Contacts: ${(data['contacts'] as Map<String, dynamic>?)?.length ?? 0}',
            metadata: {
              'sosId': data['sosId'],
              'location': data['location'],
              'status': data['status'],
              'source': 'existing_data',
            },
            notes: 'From existing sosAlerts',
          );

          final originalTimestamp = ts.toDate();
          final migratedActivity = activity.copyWith(timestamp: originalTimestamp);
          activities.add(migratedActivity);
        }
      }

      // Load weekly plan (fitness/nutrition) data
      final weeklyPlanDoc = await _firestore
          .collection('weekly_plans')
          .doc(_userId)
          .get();

      if (weeklyPlanDoc.exists) {
        final data = weeklyPlanDoc.data();
        if (data != null) {
          final ts = data['savedAt'];
          if (ts != null && ts is Timestamp) {
            final activity = AppHistoryActivity.create(
              userId: _userId,
              type: ActivityType.nutritionFitness,
              title: 'Weekly Plan Created',
              description: 'Created personalized nutrition and fitness plan',
              resultSummary: 'Plan saved',
              metadata: {
                'summary': data['summary'],
                'source': 'existing_data',
              },
              notes: 'From existing weekly plan',
            );

            final originalTimestamp = ts.toDate();
            final migratedActivity = activity.copyWith(timestamp: originalTimestamp);
            activities.add(migratedActivity);
          }
        }
      }

      // Sort by timestamp (newest first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('Loaded ${activities.length} activities from existing collections');
    } catch (e) {
      print('Error loading from existing collections: $e');
    }

    return activities;
  }

  Future<void> addActivity(AppHistoryActivity activity) async {
    try {
      // Add to Firestore
      await _firestore.collection('app_history').add(activity.toFirestore());

      // Update local state
      final currentActivities = List<AppHistoryActivity>.from(activities);
      currentActivities.insert(0, activity);
      state = AsyncValue.data(currentActivities);
    } catch (e) {
      print('Error adding activity to Firestore: $e');
      // Still update local state even if Firestore fails
      final currentActivities = List<AppHistoryActivity>.from(activities);
      currentActivities.insert(0, activity);
      state = AsyncValue.data(currentActivities);
    }
  }

  Future<void> addActivityFromExistingData({
    required ActivityType type,
    required String title,
    required String description,
    String? resultSummary,
    Map<String, dynamic>? metadata,
    String? notes,
  }) async {
    final activity = AppHistoryActivity.create(
      userId: _userId,
      type: type,
      title: title,
      description: description,
      resultSummary: resultSummary,
      metadata: metadata,
      notes: notes,
    );

    await addActivity(activity);
  }

  Future<void> refresh() async {
    await _loadAppHistory();
  }

  // Force reload from existing collections
  Future<void> reloadFromExistingCollections() async {
    final activities = await _loadFromExistingCollections();
    state = AsyncValue.data(activities);
  }

  // Get activities by type
  List<AppHistoryActivity> getActivitiesByType(ActivityType type) {
    return activities.where((activity) => activity.type == type).toList();
  }

  // Get recent activities
  List<AppHistoryActivity> getRecentActivities(int count) {
    return activities.take(count).toList();
  }

  // Get activities by date range
  List<AppHistoryActivity> getActivitiesByDateRange(
      DateTime start, DateTime end) {
    return activities
        .where((activity) =>
            activity.timestamp.isAfter(start) &&
            activity.timestamp.isBefore(end))
        .toList();
  }

  // Get summary statistics
  AppHistorySummary getSummary() {
    return AppHistorySummary.fromActivities(activities);
  }
}

// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

// Provider for app history notifier
final appHistoryProvider = StateNotifierProvider<AppHistoryNotifier,
    AsyncValue<List<AppHistoryActivity>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  return AppHistoryNotifier(userId);
});

// Provider for app history summary
final appHistorySummaryProvider = Provider<AppHistorySummary>((ref) {
  final activities = ref.watch(appHistoryProvider);
  return activities.when(
    data: (data) => AppHistorySummary.fromActivities(data),
    loading: () => AppHistorySummary.fromActivities([]),
    error: (_, __) => AppHistorySummary.fromActivities([]),
  );
});

// Provider for activities by type
final activitiesByTypeProvider =
    Provider.family<List<AppHistoryActivity>, ActivityType>((ref, type) {
  final activities = ref.watch(appHistoryProvider);
  return activities.when(
    data: (data) => data.where((activity) => activity.type == type).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for recent activities
final recentActivitiesProvider = Provider<List<AppHistoryActivity>>((ref) {
  final activities = ref.watch(appHistoryProvider);
  return activities.when(
    data: (data) => data.take(10).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
