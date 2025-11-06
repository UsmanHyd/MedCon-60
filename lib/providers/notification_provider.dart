import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Notification types
enum NotificationType {
  consultation,
  reminder,
  sos,
  general,
  prescription,
}

// Notification priority
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

// Notification data model
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final String? userId;
  final String? targetUserId;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    this.userId,
    this.targetUserId,
    this.data,
    required this.createdAt,
    this.readAt,
    required this.isRead,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => NotificationType.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == data['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      userId: data['userId'],
      targetUserId: data['targetUserId'],
      data: data['data'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'userId': userId,
      'targetUserId': targetUserId,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'isRead': isRead,
    };
  }
}

// SOS message model
class SOSMessage {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String? patientLocation;
  final String? emergencyType;
  final String? description;
  final DateTime sentAt;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  SOSMessage({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    this.patientLocation,
    this.emergencyType,
    this.description,
    required this.sentAt,
    required this.isResolved,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory SOSMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SOSMessage(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      patientPhone: data['patientPhone'] ?? '',
      patientLocation: data['patientLocation'],
      emergencyType: data['emergencyType'],
      description: data['description'],
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      isResolved: data['isResolved'] ?? false,
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      resolvedBy: data['resolvedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'patientLocation': patientLocation,
      'emergencyType': emergencyType,
      'description': description,
      'sentAt': Timestamp.fromDate(sentAt),
      'isResolved': isResolved,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
    };
  }
}

// Notification state notifier
class NotificationNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final String? _userId;

  NotificationNotifier({String? userId})
      : _userId = userId,
        super(const AsyncValue.loading()) {
    _loadNotifications();
    _setupMessaging();
  }

  Future<void> _setupMessaging() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        final token = await _messaging.getToken();
        if (token != null && _userId != null) {
          await _firestore
              .collection('users')
              .doc(_userId)
              .update({'fcmToken': token});
        }

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      }
    } catch (e) {
      // Handle permission errors
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Create local notification or update state
    _createNotificationFromMessage(message);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    // Handle when app is opened from background
    _createNotificationFromMessage(message);
  }

  Future<void> _createNotificationFromMessage(RemoteMessage message) async {
    try {
      final notification = AppNotification(
        id: message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        type: _getNotificationTypeFromData(message.data),
        priority: _getPriorityFromData(message.data),
        userId: _userId,
        data: message.data,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      await _loadNotifications();
    } catch (e) {
      // Handle error
    }
  }

  NotificationType _getNotificationTypeFromData(Map<String, dynamic> data) {
    final type = data['type'];
    switch (type) {
      case 'consultation':
        return NotificationType.consultation;
      case 'reminder':
        return NotificationType.reminder;
      case 'sos':
        return NotificationType.sos;
      case 'prescription':
        return NotificationType.prescription;
      default:
        return NotificationType.general;
    }
  }

  NotificationPriority _getPriorityFromData(Map<String, dynamic> data) {
    final priority = data['priority'];
    switch (priority) {
      case 'urgent':
        return NotificationPriority.urgent;
      case 'high':
        return NotificationPriority.high;
      case 'low':
        return NotificationPriority.low;
      default:
        return NotificationPriority.normal;
    }
  }

  Future<void> _loadNotifications() async {
    try {
      state = const AsyncValue.loading();

      if (_userId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();

      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    required NotificationType type,
    required NotificationPriority priority,
    required String targetUserId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        priority: priority,
        targetUserId: targetUserId,
        data: data,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      // Send FCM notification if target user has token
      await _sendFCMNotification(targetUserId, title, body, data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _sendFCMNotification(
    String targetUserId,
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    try {
      // Get target user's FCM token
      final userDoc =
          await _firestore.collection('users').doc(targetUserId).get();

      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken != null) {
        // In a real app, you'd send this to your backend/FCM server
        // For now, we'll just store it locally
        if (kDebugMode) {
          print('Would send FCM to token: $fcmToken');
        }
      }
    } catch (e) {
      // Handle FCM error
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.fromDate(DateTime.now()),
      });

      await _loadNotifications();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      if (_userId == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
      await _loadNotifications();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      await _loadNotifications();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }
}

// SOS state notifier
class SOSNotifier extends StateNotifier<AsyncValue<List<SOSMessage>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SOSNotifier() : super(const AsyncValue.loading()) {
    _loadSOSMessages();
  }

  Future<void> _loadSOSMessages() async {
    try {
      state = const AsyncValue.loading();

      final snapshot = await _firestore
          .collection('sos_messages')
          .where('isResolved', isEqualTo: false)
          .orderBy('sentAt', descending: true)
          .get();

      final messages =
          snapshot.docs.map((doc) => SOSMessage.fromFirestore(doc)).toList();

      state = AsyncValue.data(messages);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> sendSOSMessage({
    required String patientId,
    required String patientName,
    required String patientPhone,
    String? patientLocation,
    String? emergencyType,
    String? description,
  }) async {
    try {
      final sosMessage = SOSMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: patientId,
        patientName: patientName,
        patientPhone: patientPhone,
        patientLocation: patientLocation,
        emergencyType: emergencyType,
        description: description,
        sentAt: DateTime.now(),
        isResolved: false,
      );

      await _firestore
          .collection('sos_messages')
          .doc(sosMessage.id)
          .set(sosMessage.toFirestore());

      // Send notifications to nearby doctors
      await _notifyNearbyDoctors(sosMessage);

      await _loadSOSMessages();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _notifyNearbyDoctors(SOSMessage sosMessage) async {
    try {
      // In a real app, you'd implement location-based doctor search
      // For now, we'll notify all doctors
      final doctorsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      for (final doc in doctorsSnapshot.docs) {
        await _firestore.collection('notifications').add({
          'title': 'SOS Alert!',
          'body': '${sosMessage.patientName} needs immediate assistance',
          'type': 'sos',
          'priority': 'urgent',
          'userId': doc.id,
          'data': {
            'sosId': sosMessage.id,
            'patientId': sosMessage.patientId,
            'emergencyType': sosMessage.emergencyType,
          },
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'isRead': false,
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> resolveSOSMessage(String sosId, String resolvedBy) async {
    try {
      await _firestore.collection('sos_messages').doc(sosId).update({
        'isResolved': true,
        'resolvedAt': Timestamp.fromDate(DateTime.now()),
        'resolvedBy': resolvedBy,
      });

      await _loadSOSMessages();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshSOSMessages() async {
    await _loadSOSMessages();
  }
}

// Providers
final notificationProvider = StateNotifierProvider.family<NotificationNotifier,
    AsyncValue<List<AppNotification>>, String?>(
  (ref, userId) => NotificationNotifier(userId: userId),
);

final sosProvider =
    StateNotifierProvider<SOSNotifier, AsyncValue<List<SOSMessage>>>(
  (ref) => SOSNotifier(),
);

// Convenience providers
final unreadNotificationsProvider =
    Provider.family<int, String?>((ref, userId) {
  final notifications = ref.watch(notificationProvider(userId));
  return notifications.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final urgentNotificationsProvider =
    Provider.family<List<AppNotification>, String?>((ref, userId) {
  final notifications = ref.watch(notificationProvider(userId));
  return notifications.when(
    data: (notifications) => notifications
        .where((n) => n.priority == NotificationPriority.urgent && !n.isRead)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final activeSOSMessagesProvider = Provider<List<SOSMessage>>((ref) {
  final sosMessages = ref.watch(sosProvider);
  return sosMessages.when(
    data: (messages) => messages.where((m) => !m.isResolved).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
