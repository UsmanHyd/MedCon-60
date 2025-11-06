import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Activity type enum for different app features
enum ActivityType {
  diseaseDetection,
  vaccineReminder,
  stressMonitoring,
  heartDiseaseDetection,
  nutritionFitness,
  sosMessage,
  consultationRequest,
  profileUpdate,
  chatbotInteraction,
}

// Activity status enum
enum ActivityStatus {
  completed,
  pending,
  cancelled,
  failed,
}

// App history activity model
class AppHistoryActivity {
  final String id;
  final String userId;
  final ActivityType type;
  final String title;
  final String description;
  final ActivityStatus status;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? resultSummary;
  final String? notes;

  AppHistoryActivity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.timestamp,
    this.metadata,
    this.resultSummary,
    this.notes,
  });

  factory AppHistoryActivity.create({
    required String userId,
    required ActivityType type,
    required String title,
    required String description,
    ActivityStatus status = ActivityStatus.completed,
    Map<String, dynamic>? metadata,
    String? resultSummary,
    String? notes,
  }) {
    return AppHistoryActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      title: title,
      description: description,
      status: status,
      timestamp: DateTime.now(),
      metadata: metadata,
      resultSummary: resultSummary,
      notes: notes,
    );
  }

  factory AppHistoryActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppHistoryActivity(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ActivityType.diseaseDetection,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: ActivityStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ActivityStatus.completed,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'],
      resultSummary: data['resultSummary'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'resultSummary': resultSummary,
      'notes': notes,
    };
  }

  AppHistoryActivity copyWith({
    String? id,
    String? userId,
    ActivityType? type,
    String? title,
    String? description,
    ActivityStatus? status,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    String? resultSummary,
    String? notes,
  }) {
    return AppHistoryActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      resultSummary: resultSummary ?? this.resultSummary,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  String get typeDisplayName {
    switch (type) {
      case ActivityType.diseaseDetection:
        return 'Disease Detection';
      case ActivityType.vaccineReminder:
        return 'Vaccine Reminder';
      case ActivityType.stressMonitoring:
        return 'Stress Monitoring';
      case ActivityType.heartDiseaseDetection:
        return 'Heart Disease Detection';
      case ActivityType.nutritionFitness:
        return 'Nutrition & Fitness';
      case ActivityType.sosMessage:
        return 'SOS Message';
      case ActivityType.consultationRequest:
        return 'Consultation Request';
      case ActivityType.profileUpdate:
        return 'Profile Update';
      case ActivityType.chatbotInteraction:
        return 'Chatbot Interaction';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ActivityStatus.completed:
        return 'Completed';
      case ActivityStatus.pending:
        return 'Pending';
      case ActivityStatus.cancelled:
        return 'Cancelled';
      case ActivityStatus.failed:
        return 'Failed';
    }
  }

  Color get statusColor {
    switch (status) {
      case ActivityStatus.completed:
        return Colors.green;
      case ActivityStatus.pending:
        return Colors.orange;
      case ActivityStatus.cancelled:
        return Colors.grey;
      case ActivityStatus.failed:
        return Colors.red;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

// App history summary model
class AppHistorySummary {
  final int totalActivities;
  final Map<ActivityType, int> activitiesByType;
  final DateTime lastActivity;
  final ActivityType mostUsedFeature;
  final int thisWeekActivities;
  final int thisMonthActivities;

  AppHistorySummary({
    required this.totalActivities,
    required this.activitiesByType,
    required this.lastActivity,
    required this.mostUsedFeature,
    required this.thisWeekActivities,
    required this.thisMonthActivities,
  });

  factory AppHistorySummary.fromActivities(List<AppHistoryActivity> activities) {
    if (activities.isEmpty) {
      return AppHistorySummary(
        totalActivities: 0,
        activitiesByType: {},
        lastActivity: DateTime.now(),
        mostUsedFeature: ActivityType.diseaseDetection,
        thisWeekActivities: 0,
        thisMonthActivities: 0,
      );
    }

    // Count activities by type
    final typeCount = <ActivityType, int>{};
    for (final activity in activities) {
      typeCount[activity.type] = (typeCount[activity.type] ?? 0) + 1;
    }

    // Find most used feature
    ActivityType mostUsed = ActivityType.diseaseDetection;
    int maxCount = 0;
    for (final entry in typeCount.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostUsed = entry.key;
      }
    }

    // Calculate time-based counts
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    final thisWeek = activities.where((a) => a.timestamp.isAfter(weekAgo)).length;
    final thisMonth = activities.where((a) => a.timestamp.isAfter(monthAgo)).length;

    return AppHistorySummary(
      totalActivities: activities.length,
      activitiesByType: typeCount,
      lastActivity: activities.map((a) => a.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
      mostUsedFeature: mostUsed,
      thisWeekActivities: thisWeek,
      thisMonthActivities: thisMonth,
    );
  }
}
