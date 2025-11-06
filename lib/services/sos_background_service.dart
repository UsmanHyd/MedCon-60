import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Initialize and configure the background service for SOS countdown
Future<void> initializeSOSBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart:
          false, // Don't auto-start, we'll start it manually when SOS is sent
      isForegroundMode: true,
      notificationChannelId: 'sos_background_service',
      initialNotificationTitle: 'MedCon SOS',
      initialNotificationContent: 'Monitoring emergency alerts...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Initialize Firebase in background isolate
  try {
    // Check if Firebase is already initialized
    try {
      Firebase.app();
      print('✅ Firebase already initialized in background service');
    } catch (e) {
      // Firebase not initialized, initialize it
      print('🔄 Initializing Firebase in background service...');
      await Firebase.initializeApp();
      print('✅ Firebase initialized in background service');
    }
  } catch (e) {
    print('❌ Error initializing Firebase in background service: $e');
    // Continue anyway - Firestore calls might still work if initialized in main isolate
  }

  // Only for Android
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Listen for SOS countdown requests
  service.on('startSOSCountdown').listen((event) async {
    if (event == null) return;

    final sosId = event['sosId'] as String?;
    final contactIndex = event['contactIndex'] as int?;
    final phone = event['phone'] as String?;
    final contactName = event['contactName'] as String?;

    if (sosId == null || contactIndex == null || phone == null) {
      print('❌ Invalid SOS countdown data');
      return;
    }

    print(
        '⏱️ Background Service: Starting 1-minute countdown for $contactName ($phone)');

    // Update notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'MedCon SOS',
        content: 'Waiting for $contactName to confirm... (1 min)',
      );
    }

    // Live-listen for confirmation to immediately reflect "link viewed" state
    bool confirmedEarly = false;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sub;
    try {
      sub = FirebaseFirestore.instance
          .collection('sosAlerts')
          .doc(sosId)
          .snapshots()
          .listen((snap) {
        final data = snap.data();
        final contacts = data?['contacts'] as Map<String, dynamic>?;
        final contactData =
            contacts?[contactIndex.toString()] as Map<String, dynamic>?;
        final statusNow = contactData?['status'] as String?;
        if (statusNow == 'confirmed' && !confirmedEarly) {
          confirmedEarly = true;
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'MedCon SOS',
              content: '✅ Link viewed by $contactName - No call needed',
            );
          }
        }
      });
    } catch (_) {}

    // Wait 1 minute
    await Future.delayed(const Duration(minutes: 1));

    print('⏱️ Background Service: 1 minute elapsed, checking confirmation...');

    try {
      // Check Firestore for confirmation
      final sosDoc = await FirebaseFirestore.instance
          .collection('sosAlerts')
          .doc(sosId)
          .get();

      if (!sosDoc.exists) {
        print('❌ SOS alert $sosId not found, making call anyway');
        await _makeCall(
            service, phone, contactName ?? 'Unknown', sosId, contactIndex);
        return;
      }

      final data = sosDoc.data();
      final contacts = data?['contacts'] as Map<String, dynamic>?;
      final contactData =
          contacts?[contactIndex.toString()] as Map<String, dynamic>?;
      final status = contactData?['status'] as String?;

      if (status == 'confirmed' || confirmedEarly) {
        print('✅ $contactName confirmed the message - no call needed');

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'MedCon SOS',
            content: '✅ Link viewed by $contactName - No call needed',
          );
        }

        // Wait a bit then stop this specific task
        await Future.delayed(const Duration(seconds: 5));
        await sub?.cancel();
        return;
      }

      // Not confirmed - make the call
      print('❌ $contactName did not confirm within 1 minute - making call now');
      await _makeCall(
          service, phone, contactName ?? 'Unknown', sosId, contactIndex);
    } catch (e) {
      print('❌ Error in background SOS check: $e');
      // Still try to call on error
      await _makeCall(
          service, phone, contactName ?? 'Unknown', sosId, contactIndex);
    }
    await sub?.cancel();
  });

  // Also listen for callPending status from server
  service.on('checkCallPending').listen((event) async {
    if (event == null) return;

    final sosId = event['sosId'] as String?;
    final contactIndex = event['contactIndex'] as int?;
    final phone = event['phone'] as String?;
    final contactName = event['contactName'] as String?;

    if (sosId == null || contactIndex == null || phone == null) return;

    try {
      final sosDoc = await FirebaseFirestore.instance
          .collection('sosAlerts')
          .doc(sosId)
          .get();

      if (!sosDoc.exists) return;

      final data = sosDoc.data();
      final contacts = data?['contacts'] as Map<String, dynamic>?;
      final contactData =
          contacts?[contactIndex.toString()] as Map<String, dynamic>?;
      final status = contactData?['status'] as String?;

      // If server marked as callPending, make the call
      if (status == 'callPending') {
        print(
            '📞 Background Service: Server marked as callPending - making call');
        await _makeCall(
            service, phone, contactName ?? 'Unknown', sosId, contactIndex);
      }
    } catch (e) {
      print('❌ Error checking callPending: $e');
    }
  });
}

/// Make emergency call from background service
Future<void> _makeCall(
  ServiceInstance service,
  String phone,
  String contactName,
  String sosId,
  int contactIndex,
) async {
  try {
    // Update notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'MedCon SOS - Action Required',
        content: 'Tap notification or return to app to call $contactName',
      );
    }

    // Update Firestore to mark as 'callPending'
    try {
      await FirebaseFirestore.instance
          .collection('sosAlerts')
          .doc(sosId)
          .update({
        'contacts.$contactIndex.status': 'callPending',
        'contacts.$contactIndex.callPendingAt': FieldValue.serverTimestamp(),
      });
      print(
          '✅ Background Service: Marked $contactName as callPending in Firestore');
    } catch (e) {
      print('❌ Background Service: Error updating callPending status: $e');
    }

    // Update foreground notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: '🚨 MedCon SOS - Call Required',
        content: 'Notification sent - tap it to call $contactName',
      );
    }

    // IMPORTANT: We can't call Android methods directly from background isolate,
    // but we can store the data and the main app will show the notification.
    // The notification will appear in the status bar even when you're in WhatsApp!
    try {
      await FirebaseFirestore.instance
          .collection('sosAlerts')
          .doc(sosId)
          .update({
        'contacts.$contactIndex.callNotification': {
          'phone': phone,
          'contactName': contactName,
          'showAt': FieldValue.serverTimestamp(),
        },
      });
      print(
          '✅ Background Service: Stored call notification data - main app will show it');
    } catch (e) {
      print('⚠️ Could not store notification data: $e');
    }
  } catch (e) {
    print('❌ Error in background service _makeCall: $e');
  }
}
