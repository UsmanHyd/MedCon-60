import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcon30/api_config.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'app_history_service.dart';

class SOSService {
  static final SOSService _instance = SOSService._internal();
  factory SOSService() => _instance;
  SOSService._internal();

  /// Get current GPS location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position with high accuracy
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get location with additional context
  Future<Map<String, dynamic>?> getLocationWithContext() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return null;

      return {
        'position': position,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': position.timestamp,
        'googleMapsUrl':
            "https://maps.google.com/?q=${position.latitude},${position.longitude}",
        'openStreetMapUrl':
            "https://www.openstreetmap.org/?mlat=${position.latitude}&mlon=${position.longitude}",
      };
    } catch (e) {
      print('Error getting location with context: $e');
      return null;
    }
  }

  /// Create SOS message with location
  Future<String> createSOSMessage() async {
    try {
      final locationData = await getLocationWithContext();
      if (locationData != null) {
        final position = locationData['position'] as Position;
        final googleMapsUrl = locationData['googleMapsUrl'] as String;
        final openStreetMapUrl = locationData['openStreetMapUrl'] as String;
        final coordinates =
            "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        final accuracy = "±${position.accuracy.toStringAsFixed(1)}m";
        final altitude = position.altitude > 0
            ? "~${position.altitude.toStringAsFixed(0)}m above sea level"
            : "Ground level";
        final speed = position.speed > 0
            ? "${(position.speed * 3.6).toStringAsFixed(1)} km/h"
            : "Stationary";
        final timestamp = DateTime.now().toLocal().toString().split('.')[0];

        return '''🚨 **SOS EMERGENCY ALERT** 🚨

🆘 I need immediate help and assistance!

📍 **Location Details:**
• Google Maps: $googleMapsUrl
• OpenStreetMap: $openStreetMapUrl
• Coordinates: $coordinates
• Accuracy: $accuracy
• Altitude: $altitude
• Movement: $speed
• Time: $timestamp

📱 **Sent via:** MedCon Emergency App
⚠️ **URGENT:** This is an automated emergency alert

🚨 **IMMEDIATE ACTION REQUIRED:**
• Please respond immediately
• Call emergency services if needed
• Share this location with authorities
• Use the map links to find me

🙏 Please help me as soon as possible!''';
      } else {
        return '''🚨 **SOS EMERGENCY ALERT** 🚨

🆘 I need immediate help and assistance!

📍 **Location:** Unable to get current location
📱 **Sent via:** MedCon Emergency App
⚠️ **URGENT:** This is an automated emergency alert

🚨 **IMMEDIATE ACTION REQUIRED:**
• Please respond immediately
• Call emergency services if needed
• Try to locate me through other means

🙏 Please help me as soon as possible!''';
      }
    } catch (e) {
      return '''🚨 **SOS EMERGENCY ALERT** 🚨

🆘 I need immediate help and assistance!

📍 **Location:** Error getting location
📱 **Sent via:** MedCon Emergency App
⚠️ **URGENT:** This is an automated emergency alert

🚨 **IMMEDIATE ACTION REQUIRED:**
• Please respond immediately
• Call emergency services if needed
• Try to locate me through other means

🙏 Please help me as soon as possible!''';
    }
  }

  /// Create a shorter WhatsApp-friendly SOS message with confirmation link
  Future<String> createWhatsAppSOSMessage({
    String? sosId,
    int? contactIndex,
  }) async {
    // Generate confirmation link if sosId and contactIndex are provided
    String confirmationLink = '';
    if (sosId != null && contactIndex != null) {
      final serverUrl = _getServerUrl();
      // Use PATH-based URL format (more reliable with WhatsApp)
      // Format: /sos/confirm/:sosId/:contactIndex (WhatsApp doesn't strip path params)
      // Keep legacy-encoding variables removed (query-form uses base64url below)
      
      // Encode to base64url and use query params (works reliably with current server)
      final base64SosId = base64UrlEncode(utf8.encode(sosId.trim()));
      final base64ContactIndex = base64UrlEncode(utf8.encode(contactIndex.toString().trim()))
          .replaceAll('%3D', '=');
      final fullUrl = '${serverUrl.trim()}/sos/confirm?id=$base64SosId&idx=$base64ContactIndex'.replaceAll(' ', '');
      
      // Format URL for WhatsApp - put it on its own line, no leading/trailing spaces
      // WhatsApp recognizes URLs that start with http:// or https:// on a new line
      confirmationLink = 
          '\n\n✅ *Click this link to confirm:*\n\n$fullUrl\n\n⚠️ If clicking doesn\'t work, copy the entire link and paste it in your browser.\n\n⚠️ If you don\'t confirm within 1 minute, we will call you automatically.';
      
      // Debug: Print confirmation link
      print('🔗 Generated confirmation link for contact $contactIndex:');
      print('   Full URL: $fullUrl');
      print('   Link length: ${fullUrl.length} characters');
      print('   URL components - Server: $serverUrl');
      print('   Encoded SOS ID (base64url): $base64SosId');
      print('   Encoded Contact Index (base64url): $base64ContactIndex');
    } else {
      print('⚠️ WARNING: No confirmation link generated - sosId or contactIndex is null!');
      print('   sosId: $sosId, contactIndex: $contactIndex');
    }
    
    try {
      final locationData = await getLocationWithContext();
      
      if (locationData != null) {
        final position = locationData['position'] as Position;
        final googleMapsUrl = locationData['googleMapsUrl'] as String;
        final coordinates =
            "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        final accuracy = "±${position.accuracy.toStringAsFixed(1)}m";
        final timestamp = DateTime.now().toLocal().toString().split('.')[0];

        return '''🚨 *MedCon Emergency Alert!*

I have triggered an SOS alert.

📍 Current location: $googleMapsUrl
📍 Coordinates: $coordinates
📍 Accuracy: $accuracy
⏰ Time: $timestamp
$confirmationLink

⏱️ Please check immediately — this is an emergency.

📱 Sent via MedCon Emergency App''';
      } else {
        return '''🚨 *MedCon Emergency Alert!*

I have triggered an SOS alert.

📍 Location: Unable to get current location
$confirmationLink

⏱️ Please check immediately — this is an emergency.

📱 Sent via MedCon Emergency App''';
      }
    } catch (e) {
      return '''🚨 *MedCon Emergency Alert!*

I have triggered an SOS alert.

📍 Location: Error getting location
$confirmationLink

⏱️ Please check immediately — this is an emergency.

📱 Sent via MedCon Emergency App''';
    }
  }
  
  /// Get server URL for confirmation links
  String _getServerUrl() {
    return ApiConfig.reminderServer;
  }

  /// Send SMS (Disabled - WhatsApp only)
  Future<bool> sendSMS(String phoneNumber, String message) async {
    // SMS functionality disabled - WhatsApp only
    return false;
  }

  /// Send WhatsApp message
  Future<bool> sendWhatsApp(String phoneNumber, String message) async {
    try {
      // Clean phone number - remove all non-digit characters
      String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      print('📞 Original phone number: $phoneNumber');
      print('📞 Cleaned phone number: $cleanedPhone');
      
      // Validate phone number length
      if (cleanedPhone.length < 10) {
        print('❌ Invalid phone number length: ${cleanedPhone.length} digits');
        return false;
      }
      
      // Format phone number for WhatsApp (must be international format)
      String formattedPhone;
      
      // Check if it already has a country code
      if (cleanedPhone.startsWith('92') && cleanedPhone.length >= 12) {
        // Pakistan number with country code
        formattedPhone = cleanedPhone;
      } else if (cleanedPhone.startsWith('1') && cleanedPhone.length >= 11) {
        // US/Canada number with country code
        formattedPhone = cleanedPhone;
      } else if (cleanedPhone.startsWith('44') && cleanedPhone.length >= 12) {
        // UK number with country code
        formattedPhone = cleanedPhone;
      } else {
        // Assume Pakistan number and add country code if missing
        // Remove leading 0 if present (common in Pakistan numbers like 03001234567)
        if (cleanedPhone.startsWith('0')) {
          cleanedPhone = cleanedPhone.substring(1);
        }
        formattedPhone = '92$cleanedPhone';
      }

      print('📞 Formatted phone number for WhatsApp: $formattedPhone');
      print('📱 Message length: ${message.length} characters');
      
      // Encode message properly for URL
      final encodedMessage = Uri.encodeComponent(message);
      print('Encoded message length: ${encodedMessage.length} characters');

      // WhatsApp has URI length limits, so we prioritize the most reliable methods
      // Method 1: wa.me (most reliable for pre-filling messages)
      try {
        final waMeUri = Uri.parse("https://wa.me/$formattedPhone?text=$encodedMessage");
        print('Trying wa.me method: https://wa.me/$formattedPhone?text=[MESSAGE]');
        if (await canLaunchUrl(waMeUri)) {
          await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
          print('✅ WhatsApp launched via wa.me - message should be pre-filled');
          return true;
        }
      } catch (e) {
        print('wa.me method failed: $e');
      }

      // Method 2: Standard whatsapp:// scheme (works on most Android devices)
      try {
        final whatsappUri = Uri.parse("whatsapp://send?phone=$formattedPhone&text=$encodedMessage");
        print('Trying whatsapp:// scheme');
        // Don't check canLaunchUrl for this - just try it
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        print('✅ WhatsApp launched via whatsapp:// scheme');
        return true;
      } catch (e) {
        print('whatsapp:// scheme failed: $e');
      }

      // Method 3: Android Intent (for better compatibility)
      if (Platform.isAndroid) {
        try {
          final intentUri = Uri.parse(
              "intent://send?phone=$formattedPhone&text=$encodedMessage#Intent;scheme=whatsapp;package=com.whatsapp;end");
          print('Trying Android Intent');
          await launchUrl(intentUri, mode: LaunchMode.externalApplication);
          print('✅ WhatsApp launched via Android Intent');
          return true;
        } catch (e) {
          print('Android Intent failed: $e');
        }
      }

      // Method 4: Fallback - open WhatsApp with phone number only
      try {
        final fallbackUri = Uri.parse("whatsapp://send?phone=$formattedPhone");
        print('⚠️ Fallback: Opening WhatsApp without message');
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        print('⚠️ WhatsApp opened but message not pre-filled - user must type manually');
        return true; // Still return true since WhatsApp opened
      } catch (e) {
        print('Fallback method failed: $e');
      }

      print('❌ All WhatsApp methods failed');
      return false;
    } catch (e) {
      print('Error in sendWhatsApp: $e');
      return false;
    }
  }

  /// Try to launch WhatsApp directly using package manager
  Future<bool> _launchWhatsAppDirectly(
      String phoneNumber, String message) async {
    try {
      if (Platform.isAndroid) {
        // Try to launch WhatsApp directly using package name
        final intentUri = Uri.parse(
            "intent://send?package=com.whatsapp&phone=$phoneNumber&text=${Uri.encodeComponent(message)}#Intent;scheme=whatsapp;package=com.whatsapp;end");

        // Force launch without checking canLaunchUrl
        try {
          await launchUrl(intentUri, mode: LaunchMode.externalApplication);
          return true;
        } catch (e) {
          print('Direct launch failed: $e');
        }

        // Try alternative direct method
        final altUri = Uri.parse("whatsapp://send?phone=$phoneNumber");
        try {
          await launchUrl(altUri, mode: LaunchMode.externalApplication);
          return true;
        } catch (e) {
          print('Alternative direct launch failed: $e');
        }

        // Try to open WhatsApp first, then navigate to contact
        try {
          final openWhatsAppUri = Uri.parse("whatsapp://");
          await launchUrl(openWhatsAppUri,
              mode: LaunchMode.externalApplication);
          print('WhatsApp opened, now user can manually send message');
          return true;
        } catch (e) {
          print('Open WhatsApp failed: $e');
        }
      }
      return false;
    } catch (e) {
      print('Error in direct WhatsApp launch: $e');
      return false;
    }
  }

  /// Get emergency contacts from Firebase
  Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      final contacts = (data?['emergencyContacts'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      return contacts;
    } catch (e) {
      print('Error fetching emergency contacts: $e');
      return [];
    }
  }

  /// Send SOS alerts to all emergency contacts with confirmation tracking and auto-call
  Future<Map<String, dynamic>> sendSOSAlerts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      final contacts = await getEmergencyContacts();

      if (contacts.isEmpty) {
        return {
          'success': false,
          'message': 'No emergency contacts found',
          'contactsReached': 0,
          'totalContacts': 0,
        };
      }

      // Create SOS alert document in Firestore
      // Generate a clean ID that's safe for URLs (no special characters that break URLs)
      var rawSosId = FirebaseFirestore.instance.collection('sosAlerts').doc().id;
      // Clean the ID to make it URL-safe - replace problematic characters
      final sosId = rawSosId
          .replaceAll('&', '-')
          .replaceAll('+', '-')
          .replaceAll('=', '-')
          .replaceAll('%', '-')
          .replaceAll('#', '-')
          .replaceAll('?', '-');
      
      print('🔑 Generated SOS ID: $sosId (cleaned from: $rawSosId)');
      final locationData = await getLocationWithContext();
      final timestamp = DateTime.now();
      
      // Prepare contacts data structure
      final contactsData = <String, dynamic>{};
      for (int i = 0; i < contacts.length; i++) {
        contactsData[i.toString()] = {
          'name': contacts[i]['name'] ?? 'Unknown',
          'phone': contacts[i]['phone'] ?? '',
          'status': 'sent', // sent, confirmed, called
          'sentAt': timestamp.toIso8601String(),
        };
      }

      // Create SOS alert document
      print('📝 Creating SOS alert document with ID: $sosId');
      try {
        // Calculate call time (1 minute from now)
        final callTime = timestamp.add(const Duration(minutes: 1));
        
        await FirebaseFirestore.instance.collection('sosAlerts').doc(sosId).set({
          'userId': user.uid,
          'sosId': sosId, // Store the ID as a field too for case-insensitive lookup
          'timestamp': FieldValue.serverTimestamp(),
          'callScheduledAt': callTime.toIso8601String(), // Server will check and call at this time
          'location': locationData != null
              ? {
                  'latitude': locationData['latitude'],
                  'longitude': locationData['longitude'],
                  'googleMapsUrl': locationData['googleMapsUrl'],
                }
              : null,
          'contacts': contactsData,
          'status': 'active',
        });
        print('✅ SOS alert document created successfully in Firestore');
        print('⏰ Call scheduled for: ${callTime.toLocal()}');
      } catch (e) {
        print('❌ Error creating SOS alert document: $e');
        rethrow; // Re-throw to stop execution
      }

      int whatsappSuccess = 0;
      List<String> errors = [];
      List<Future<void>> callFutures = [];

      // Send WhatsApp messages to all contacts
      for (int i = 0; i < contacts.length; i++) {
        final contact = contacts[i];
        final phone = contact['phone']?.toString() ?? '';
        final name = contact['name']?.toString() ?? 'Unknown';
        
        print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📞 Processing contact ${i + 1}: $name');
        print('📱 Phone number from Firebase: "$phone"');
        
        if (phone.isEmpty) {
          print('❌ Skipping - phone number is empty');
          continue;
        }

        try {
          // Create message with confirmation link
          final message = await createWhatsAppSOSMessage(
            sosId: sosId,
            contactIndex: i,
          );
          
          // Debug: Print the message to verify confirmation link is included
          print('📱 Full message:');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print(message);
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          
          // Send WhatsApp message
          print('Sending WhatsApp to: $name ($phone)');
          final waResult = await sendWhatsApp(phone, message);
          
          if (waResult) {
            whatsappSuccess++;
            print('WhatsApp sent successfully to ${contact['name'] ?? phone}');
            
            // Start background service countdown (works even when app is in background/WhatsApp)
            await _startBackgroundSOSCountdown(
              sosId: sosId,
              contactIndex: i,
              contactName: contact['name'] ?? 'Unknown',
              phone: phone,
            );
            
            // Also keep the original countdown as backup (in case background service fails)
            callFutures.add(_waitAndCheckConfirmation(
              sosId: sosId,
              contactIndex: i,
              contactName: contact['name'] ?? 'Unknown',
              phone: phone,
            ));
          } else {
            errors.add('Failed to send WhatsApp to ${contact['name'] ?? phone}');
            // Still try to call after timeout even if WhatsApp failed
            callFutures.add(_waitAndCallAfterTimeout(
              contactName: contact['name'] ?? 'Unknown',
              phone: phone,
              contactIndex: i,
              sosId: sosId,
            ));
          }
        } catch (e) {
          errors.add('Error sending to ${contact['name'] ?? phone}: $e');
        }
      }

      // Wait for all call futures to complete (they run in parallel)
      await Future.wait(callFutures);

      // Log SOS attempt to Firestore for history
      await _logSOSAttempt(contacts.length, 0, whatsappSuccess, errors);

      // Track SOS activity in app history
      try {
        final contactNames = contacts.map((c) => c['name']?.toString() ?? 'Unknown').join(', ');
        await AppHistoryService().trackSosMessage(
          message: 'SOS alert sent to ${contacts.length} contact(s)',
          recipient: contactNames,
        );
      } catch (e) {
        print('Error tracking SOS in app history: $e');
        // Don't fail the SOS operation if tracking fails
      }

      return {
        'success': true,
        'message': 'SOS alerts sent successfully via WhatsApp',
        'contactsReached': whatsappSuccess,
        'totalContacts': contacts.length,
        'whatsappSuccess': whatsappSuccess,
        'errors': errors,
        'sosId': sosId,
      };
    } catch (e) {
      print('Error sending SOS alerts: $e');
      return {
        'success': false,
        'message': 'Failed to send SOS alerts: $e',
        'contactsReached': 0,
        'totalContacts': 0,
      };
    }
  }
  
  /// Start background service countdown (works even when user is in WhatsApp)
  Future<void> _startBackgroundSOSCountdown({
    required String sosId,
    required int contactIndex,
    required String contactName,
    required String phone,
  }) async {
    try {
      // Request all necessary permissions for background service
      if (Platform.isAndroid) {
        final phonePermission = await Permission.phone.request();
        if (!phonePermission.isGranted) {
          print('⚠️ Phone permission not granted for background calls');
        }
        
        // Request FOREGROUND_SERVICE_PHONE_CALL permission (Android 14+)
        try {
          if (Platform.isAndroid) {
            // Request via platform channel
            final platform = MethodChannel('com.example.medcon30/permissions');
            await platform.invokeMethod('requestForegroundServicePhoneCallPermission');
            print('📱 Foreground service phone call permission requested');
          }
        } catch (e) {
          print('⚠️ Could not request foreground service permission: $e');
          // Continue anyway - background service can still run, just might show warnings
        }
        
        // Request battery optimization exemption
        final batteryOptimization = await Permission.ignoreBatteryOptimizations.request();
        if (!batteryOptimization.isGranted) {
          print('⚠️ Battery optimization not exempted - service may be killed');
        }
      }

      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();
      
      if (!isRunning) {
        print('🚀 Starting background service...');
        await service.startService();
        
        // Give it a moment to initialize
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Send SOS countdown task to background service
      service.invoke('startSOSCountdown', {
        'sosId': sosId,
        'contactIndex': contactIndex,
        'phone': phone,
        'contactName': contactName,
      });
      
      print('✅ Background service countdown started for $contactName');
      
      // Set up Firestore listener for real-time status updates
      // This will automatically detect when background service marks as 'callPending'
      // and make the call immediately when app is in foreground
      final sosDocRef = FirebaseFirestore.instance
          .collection('sosAlerts')
          .doc(sosId);
      
      StreamSubscription? firestoreSubscription;
      firestoreSubscription = sosDocRef.snapshots().listen((snapshot) async {
        if (!snapshot.exists) {
          firestoreSubscription?.cancel();
          return;
        }
        
        try {
          final data = snapshot.data();
          final contacts = data?['contacts'] as Map<String, dynamic>?;
          final contactData = contacts?[contactIndex.toString()] as Map<String, dynamic>?;
          final status = contactData?['status'] as String?;

          // If confirmed, stop everything - no call needed
          if (status == 'confirmed') {
            print('✅ Firestore listener: $contactName confirmed - cancelling call');
            firestoreSubscription?.cancel();
            return;
          }

          // If marked as callPending (by background service), make the call immediately
          if (status == 'callPending') {
            print('📞 Firestore listener: Detected callPending for $contactName - making call NOW');
            firestoreSubscription?.cancel();
            
            // Show high-priority notification that opens dialer (works even if app was in background)
            await _showCallNotification(phone, contactName);
            
            // Also make the call directly from main app
            await _makeEmergencyCall(phone, contactName, contactIndex, sosId);
            return;
          }

          // If already called, stop listening
          if (status == 'called') {
            firestoreSubscription?.cancel();
            return;
          }
        } catch (e) {
          print('❌ Error in Firestore listener: $e');
        }
      }, onError: (e) {
        print('❌ Firestore listener error: $e');
        firestoreSubscription?.cancel();
      });
      
      // Also set up frequent periodic check (works even when app is backgrounded)
      // This ensures notification shows even when in WhatsApp
      Timer.periodic(const Duration(seconds: 2), (timer) async {
        try {
          final sosDoc = await FirebaseFirestore.instance
              .collection('sosAlerts')
              .doc(sosId)
              .get();

          if (!sosDoc.exists) {
            timer.cancel();
            firestoreSubscription?.cancel();
            return;
          }

          final data = sosDoc.data();
          final contacts = data?['contacts'] as Map<String, dynamic>?;
          final contactData = contacts?[contactIndex.toString()] as Map<String, dynamic>?;
          final status = contactData?['status'] as String?;

          // If confirmed or called, stop checking
          if (status == 'confirmed' || status == 'called') {
            timer.cancel();
            firestoreSubscription?.cancel();
            return;
          }

          // If marked as callPending, show notification and make call
          if (status == 'callPending') {
            timer.cancel();
            firestoreSubscription?.cancel();
            print('📞 Periodic check: Detected callPending for $contactName - showing notification and making call');
            
            // Show high-priority notification that opens dialer
            await _showCallNotification(phone, contactName);
            
            // Also make the call directly
            await _makeEmergencyCall(phone, contactName, contactIndex, sosId);
          }
        } catch (e) {
          print('❌ Error in periodic callPending check: $e');
        }
      });
      
    } catch (e) {
      print('❌ Error starting background SOS countdown: $e');
      // Fallback to regular countdown
    }
  }
  
  /// Wait 1 minute and check if contact confirmed, then call if not confirmed (BACKUP METHOD)
  Future<void> _waitAndCheckConfirmation({
    required String sosId,
    required int contactIndex,
    required String contactName,
    required String phone,
  }) async {
    try {
      print('Starting 1-minute countdown for $contactName...');
      
      // Wait 1 minute
      await Future.delayed(const Duration(minutes: 1));
      
      // Check Firestore for confirmation
      final sosDoc = await FirebaseFirestore.instance
          .collection('sosAlerts')
          .doc(sosId)
          .get();
      
      if (!sosDoc.exists) {
        print('SOS alert $sosId not found, calling anyway');
        await _makeEmergencyCall(phone, contactName, contactIndex, sosId);
        return;
      }
      
      final data = sosDoc.data();
      final contacts = data?['contacts'] as Map<String, dynamic>?;
      final contactData = contacts?[contactIndex.toString()] as Map<String, dynamic>?;
      final status = contactData?['status'] as String?;
      
      if (status == 'confirmed') {
        print('✅ $contactName confirmed the message - no call needed');
        return;
      }
      
      // Not confirmed - make the call
      print('❌ $contactName did not confirm within 1 minute - calling now');
      await _makeEmergencyCall(phone, contactName, contactIndex, sosId);
    } catch (e) {
      print('Error in wait and check confirmation: $e');
      // Still try to call on error
      await _makeEmergencyCall(phone, contactName, contactIndex, sosId);
    }
  }
  
  /// Wait and call after timeout (if WhatsApp failed)
  Future<void> _waitAndCallAfterTimeout({
    required String contactName,
    required String phone,
    required int contactIndex,
    required String sosId,
  }) async {
    await Future.delayed(const Duration(minutes: 1));
    await _makeEmergencyCall(phone, contactName, contactIndex, sosId);
  }
  
  /// Show notification that opens dialer when tapped (works from background)
  Future<void> _showCallNotification(String phone, String contactName) async {
    try {
      if (Platform.isAndroid) {
        final platform = MethodChannel('com.example.medcon30/permissions');
        await platform.invokeMethod('showCallNotification', {
          'phone': phone,
          'contactName': contactName,
        });
        print('📱 Requested call notification for $contactName');
      }
    } catch (e) {
      print('⚠️ Could not show call notification: $e');
      // Continue anyway - will try to make call directly
    }
  }

  /// Make emergency call to contact
  Future<void> _makeEmergencyCall(
    String phone,
    String contactName,
    int contactIndex,
    String sosId,
  ) async {
    try {
      print('📞 Calling $contactName at $phone...');
      
      // Update Firestore status
      try {
        await FirebaseFirestore.instance
            .collection('sosAlerts')
            .doc(sosId)
            .update({
          'contacts.$contactIndex.status': 'called',
          'contacts.$contactIndex.calledAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating Firestore call status: $e');
      }
      
      // Make the call using tel: URI
      final telUri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
        print('✅ Call initiated to $contactName');
      } else {
        print('❌ Cannot launch phone call to $phone');
      }
    } catch (e) {
      print('Error making emergency call: $e');
    }
  }

  /// Log SOS attempt to Firestore for history tracking
  Future<void> _logSOSAttempt(int totalContacts, int smsSuccess,
      int whatsappSuccess, List<String> errors) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Log to user's document
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'lastSOSAttempt': {
              'timestamp': FieldValue.serverTimestamp(),
              'totalContacts': totalContacts,
              'smsSuccess': smsSuccess,
              'whatsappSuccess': whatsappSuccess,
              'errors': errors,
              'status': 'completed',
            }
          });
        } catch (userDocError) {
          print('Could not log SOS attempt to user document: $userDocError');
      }
    } catch (e) {
      print('Error in SOS logging: $e');
    }
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  /// Check if SMS app is available (Disabled - WhatsApp only)
  Future<bool> isSMSAvailable() async {
    // SMS functionality disabled - WhatsApp only
    return false;
  }

  /// Check if WhatsApp is available
  Future<bool> isWhatsAppAvailable() async {
    try {
      // Try multiple WhatsApp URI formats with better detection
      final uris = [
        Uri.parse("whatsapp://send?phone=1234567890"),
        Uri.parse("https://wa.me/1234567890"),
        Uri.parse("intent://send?package=com.whatsapp"),
        Uri.parse(
            "intent://send?package=com.whatsapp&phone=1234567890#Intent;scheme=whatsapp;package=com.whatsapp;end"),
      ];

      for (int i = 0; i < uris.length; i++) {
        try {
          final canLaunch = await canLaunchUrl(uris[i]);
          if (canLaunch) {
            print('WhatsApp available via URI $i: ${uris[i]}');
            return true;
          }
        } catch (e) {
          print('Error checking WhatsApp URI $i: $e');
          continue;
        }
      }

      print('WhatsApp not available via any URI');
      return false;
    } catch (e) {
      print('Error in isWhatsAppAvailable: $e');
      return false;
    }
  }

  /// Alternative method: Try to open phone dialer with message
  Future<bool> openPhoneDialer(String phoneNumber, String message) async {
    try {
      // Try to open phone dialer
      final telUri = Uri.parse("tel:$phoneNumber");
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('Error opening phone dialer: $e');
      return false;
    }
  }

  /// Alternative method: Try to open any messaging app (Disabled - WhatsApp only)
  Future<bool> openMessagingApp(String phoneNumber, String message) async {
    // SMS messaging app functionality disabled - WhatsApp only
    return false;
  }

  /// Platform-specific emergency contact method (WhatsApp focused)
  Future<bool> openEmergencyContact(String phoneNumber, String message) async {
    try {
      if (Platform.isAndroid) {
        // Android: Try WhatsApp intent schemes first, then phone dialer
        final uris = [
          Uri.parse(
              "intent://send?package=com.whatsapp&phone=$phoneNumber&text=${Uri.encodeComponent(message)}#Intent;scheme=whatsapp;package=com.whatsapp;end"),
          Uri.parse(
              "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}"),
          Uri.parse("tel:$phoneNumber"),
        ];

        for (final uri in uris) {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return true;
          }
        }
      } else if (Platform.isIOS) {
        // iOS: Try WhatsApp first, then phone dialer
        final uris = [
          Uri.parse(
              "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}"),
          Uri.parse("tel:$phoneNumber"),
        ];

        for (final uri in uris) {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('Error opening emergency contact: $e');
      return false;
    }
  }

  /// Get emergency contact instructions for manual contact (WhatsApp focused)
  String getEmergencyInstructions(String phoneNumber, String message) {
    return '''
🚨 EMERGENCY CONTACT INSTRUCTIONS

Contact: $phoneNumber
Message: $message

If WhatsApp couldn't open automatically:

1. 📲 **WhatsApp**: Open WhatsApp and send the message to $phoneNumber
2. 📱 **Call directly**: Dial $phoneNumber as backup
3. 📧 **Email**: If you have their email, send the message there

⚠️ **URGENT**: This is an emergency situation requiring immediate response!
''';
  }

  /// Check if WhatsApp is actually installed on the device
  Future<bool> isWhatsAppInstalled() async {
    try {
      if (Platform.isAndroid) {
        // Try to check if WhatsApp package is available
        final intentUri = Uri.parse(
            "intent://send?package=com.whatsapp#Intent;scheme=whatsapp;end");
        return await canLaunchUrl(intentUri);
      } else if (Platform.isIOS) {
        // iOS: try standard WhatsApp scheme
        final waUri = Uri.parse("whatsapp://send?phone=1234567890");
        return await canLaunchUrl(waUri);
      }
      return false;
    } catch (e) {
      print('Error checking WhatsApp installation: $e');
      return false;
    }
  }

  /// Force launch WhatsApp with multiple fallback methods
  Future<bool> forceLaunchWhatsApp(String phoneNumber, String message) async {
    try {
      print('Force launching WhatsApp for: $phoneNumber');

      // Method 1: Try Android intent with explicit package FIRST (forces regular WhatsApp)
      try {
        final uri = Uri.parse(
            "intent://send?package=com.whatsapp&phone=$phoneNumber&text=${Uri.encodeComponent(message)}#Intent;scheme=whatsapp;package=com.whatsapp;end");
        print(
            'Trying Android intent with explicit package (regular WhatsApp only)');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('WhatsApp launched via Android intent (regular app)');
        return true;
      } catch (e) {
        print('Android intent failed: $e');
      }

      // Method 2: Try web WhatsApp with specific app selection
      try {
        final uri = Uri.parse(
            "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
        print('Trying web WhatsApp (should default to regular app)');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('WhatsApp launched via web scheme');
        return true;
      } catch (e) {
        print('Web scheme failed: $e');
      }

      // Method 3: Try standard WhatsApp scheme
      try {
        final uri = Uri.parse(
            "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");
        print('Trying standard WhatsApp scheme');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('WhatsApp launched via standard scheme');
        return true;
      } catch (e) {
        print('Standard scheme failed: $e');
      }

      // Method 4: Try to open WhatsApp main app first, then navigate
      try {
        final uri = Uri.parse("whatsapp://");
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('WhatsApp main app opened, now navigating to contact');

        // Wait for WhatsApp to open
        await Future.delayed(const Duration(seconds: 2));

        // Now try to open the specific contact
        try {
          final contactUri = Uri.parse("whatsapp://send?phone=$phoneNumber");
          await launchUrl(contactUri, mode: LaunchMode.externalApplication);
          print('Contact opened in WhatsApp');
          return true;
        } catch (e) {
          print('Contact opening failed, but WhatsApp is open');
          return true; // WhatsApp is open, user can manually navigate
        }
      } catch (e) {
        print('WhatsApp main app failed: $e');
      }

      print('All force launch methods failed');
      return false;
    } catch (e) {
      print('Error in force launch: $e');
      return false;
    }
  }

  /// Create a minimal SOS message for better WhatsApp compatibility
  Future<String> createMinimalSOSMessage() async {
    try {
      final locationData = await getLocationWithContext();
      if (locationData != null) {
        final googleMapsUrl = locationData['googleMapsUrl'] as String;

        return '''🚨 SOS! Need help! Location: $googleMapsUrl

Sent via MedCon app. Please respond immediately!''';
      } else {
        return '''🚨 SOS! Need help! Location unavailable.

Sent via MedCon app. Please respond immediately!''';
      }
    } catch (e) {
      return '''🚨 SOS! Need help! Location error.

Sent via MedCon app. Please respond immediately!''';
    }
  }

  /// Try to launch WhatsApp using alternative methods
  Future<bool> launchWhatsAppAlternative(
      String phoneNumber, String message) async {
    try {
      print('Trying alternative WhatsApp launch for: $phoneNumber');

      // Method 1: Try to open WhatsApp main screen
      try {
        final uri = Uri.parse("whatsapp://");
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('WhatsApp main screen opened');

        // Give user time to see WhatsApp opened
        await Future.delayed(const Duration(seconds: 2));

        // Now try to open specific contact
        try {
          final contactUri = Uri.parse("whatsapp://send?phone=$phoneNumber");
          await launchUrl(contactUri, mode: LaunchMode.externalApplication);
          print('Contact opened in WhatsApp');
          return true;
        } catch (e) {
          print('Contact opening failed: $e');
          // WhatsApp is open, user can manually navigate
          return true;
        }
      } catch (e) {
        print('WhatsApp main screen failed: $e');
      }

      // Method 2: Try to open phone contacts and let user select WhatsApp
      try {
        final contactsUri = Uri.parse("content://contacts/people");
        await launchUrl(contactsUri, mode: LaunchMode.externalApplication);
        print('Contacts opened, user can select contact and choose WhatsApp');
        return true;
      } catch (e) {
        print('Contacts opening failed: $e');
      }

      // Method 3: Try to open phone dialer with the number
      try {
        final dialerUri = Uri.parse("tel:$phoneNumber");
        await launchUrl(dialerUri, mode: LaunchMode.externalApplication);
        print('Phone dialer opened with number');
        return true;
      } catch (e) {
        print('Phone dialer failed: $e');
      }

      print('All alternative methods failed');
      return false;
    } catch (e) {
      print('Error in alternative WhatsApp launch: $e');
      return false;
    }
  }

  /// Try to launch WhatsApp using package name directly
  Future<bool> launchWhatsAppByPackage(
      String phoneNumber, String message) async {
    try {
      print('Trying to launch WhatsApp by package name for: $phoneNumber');

      if (Platform.isAndroid) {
        // Method 1: Try to open WhatsApp directly using package name (regular app only)
        try {
          final packageUri = Uri.parse("package:com.whatsapp");
          await launchUrl(packageUri, mode: LaunchMode.externalApplication);
          print('WhatsApp package opened (regular app only)');

          // Wait for WhatsApp to open
          await Future.delayed(const Duration(seconds: 3));

          // Now try to open the specific contact
          try {
            final contactUri = Uri.parse("whatsapp://send?phone=$phoneNumber");
            await launchUrl(contactUri, mode: LaunchMode.externalApplication);
            print('Contact opened in WhatsApp');
            return true;
          } catch (e) {
            print('Contact opening failed, but WhatsApp is open');
            return true; // WhatsApp is open, user can manually navigate
          }
        } catch (e) {
          print('Package launch failed: $e');
        }

        // Method 2: Try to open WhatsApp using activity name
        try {
          final activityUri = Uri.parse(
              "intent://launch?package=com.whatsapp#Intent;scheme=android-app;package=com.whatsapp;end");
          await launchUrl(activityUri, mode: LaunchMode.externalApplication);
          print('WhatsApp activity launched');

          await Future.delayed(const Duration(seconds: 2));

          // Try to open contact
          try {
            final contactUri = Uri.parse("whatsapp://send?phone=$phoneNumber");
            await launchUrl(contactUri, mode: LaunchMode.externalApplication);
            print('Contact opened in WhatsApp');
            return true;
          } catch (e) {
            print('Contact opening failed, but WhatsApp is open');
            return true;
          }
        } catch (e) {
          print('Activity launch failed: $e');
        }
      }

      print('All package methods failed');
      return false;
    } catch (e) {
      print('Error in package launch: $e');
      return false;
    }
  }

  /// Force launch ONLY regular WhatsApp (no business app choice)
  Future<bool> forceRegularWhatsAppOnly(
      String phoneNumber, String message) async {
    try {
      print('Force launching REGULAR WhatsApp only for: $phoneNumber');

      if (Platform.isAndroid) {
        // Method 1: Use explicit activity name for regular WhatsApp
        try {
          final activityUri = Uri.parse(
              "intent://send?package=com.whatsapp&phone=$phoneNumber&text=${Uri.encodeComponent(message)}#Intent;scheme=whatsapp;package=com.whatsapp;action=android.intent.action.SEND;end");
          print('Trying explicit activity intent (regular WhatsApp only)');
          await launchUrl(activityUri, mode: LaunchMode.externalApplication);
          print('Regular WhatsApp launched via explicit activity');
          return true;
        } catch (e) {
          print('Explicit activity failed: $e');
        }

        // Method 2: Use component name to force regular WhatsApp
        try {
          final componentUri = Uri.parse(
              "intent://send?package=com.whatsapp&phone=$phoneNumber&text=${Uri.encodeComponent(message)}&component=com.whatsapp/.Main#Intent;scheme=whatsapp;package=com.whatsapp;end");
          print('Trying component-specific intent (regular WhatsApp only)');
          await launchUrl(componentUri, mode: LaunchMode.externalApplication);
          print('Regular WhatsApp launched via component intent');
          return true;
        } catch (e) {
          print('Component intent failed: $e');
        }

        // Method 3: Use specific WhatsApp activity
        try {
          final specificUri = Uri.parse(
              "intent://send?package=com.whatsapp&phone=$phoneNumber&text=${Uri.encodeComponent(message)}&component=com.whatsapp/.Conversation#Intent;scheme=whatsapp;package=com.whatsapp;end");
          print('Trying conversation activity intent (regular WhatsApp only)');
          await launchUrl(specificUri, mode: LaunchMode.externalApplication);
          print('Regular WhatsApp launched via conversation activity');
          return true;
        } catch (e) {
          print('Conversation activity failed: $e');
        }

        // Method 4: Try to open WhatsApp main screen first, then force contact
        try {
          final mainUri = Uri.parse(
              "intent://launch?package=com.whatsapp#Intent;scheme=android-app;package=com.whatsapp;end");
          await launchUrl(mainUri, mode: LaunchMode.externalApplication);
          print('WhatsApp main screen opened, now forcing contact');

          await Future.delayed(const Duration(seconds: 3));

          // Force contact with explicit package
          try {
            final contactUri = Uri.parse(
                "intent://send?package=com.whatsapp&phone=$phoneNumber&text=${Uri.encodeComponent(message)}#Intent;scheme=whatsapp;package=com.whatsapp;end");
            await launchUrl(contactUri, mode: LaunchMode.externalApplication);
            print('Contact forced in regular WhatsApp');
            return true;
          } catch (e) {
            print('Contact forcing failed, but WhatsApp is open');
            return true; // WhatsApp is open, user can manually navigate
          }
        } catch (e) {
          print('Main screen launch failed: $e');
        }
      }

      print('All regular WhatsApp methods failed');
      return false;
    } catch (e) {
      print('Error in regular WhatsApp launch: $e');
      return false;
    }
  }

  /// Block WhatsApp Business and force regular WhatsApp only
  Future<bool> blockBusinessForceRegular(
      String phoneNumber, String message) async {
    try {
      print(
          'Blocking WhatsApp Business and forcing regular WhatsApp for: $phoneNumber');

      if (Platform.isAndroid) {
        // Method 1: Use the working methods that we know work (Test Launch and Test Minimal)
        try {
          // Use the same approach as Test Launch (which works)
          final uri = Uri.parse(
              "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");
          print('Trying working WhatsApp scheme (like Test Launch)');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('WhatsApp launched via working scheme');
          return true;
        } catch (e) {
          print('Working scheme failed: $e');
        }

        // Method 2: Use minimal message approach (like Test Minimal)
        try {
          final minimalMessage = await createMinimalSOSMessage();
          final uri = Uri.parse(
              "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(minimalMessage)}");
          print('Trying minimal message approach (like Test Minimal)');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('WhatsApp launched via minimal message');
          return true;
        } catch (e) {
          print('Minimal message approach failed: $e');
        }

        // Method 3: Use web WhatsApp (which should default to regular app)
        try {
          final uri = Uri.parse(
              "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
          print('Trying web WhatsApp (should default to regular app)');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('WhatsApp launched via web scheme');
          return true;
        } catch (e) {
          print('Web scheme failed: $e');
        }

        // Method 4: Try to open WhatsApp main screen first, then navigate
        try {
          final mainUri = Uri.parse("whatsapp://");
          await launchUrl(mainUri, mode: LaunchMode.externalApplication);
          print('WhatsApp main screen opened, now navigating to contact');

          await Future.delayed(const Duration(seconds: 2));

          // Navigate to contact using working method
          try {
            final contactUri = Uri.parse("whatsapp://send?phone=$phoneNumber");
            await launchUrl(contactUri, mode: LaunchMode.externalApplication);
            print('Contact opened in WhatsApp');
            return true;
          } catch (e) {
            print('Contact opening failed, but WhatsApp is open');
            return true; // WhatsApp is open, user can manually navigate
          }
        } catch (e) {
          print('Main screen launch failed: $e');
        }
      }

      print('All business-blocking methods failed');
      return false;
    } catch (e) {
      print('Error in business-blocking launch: $e');
      return false;
    }
  }

  /// Wait for user to return to MedCon app before proceeding
  Future<void> waitForUserReturn() async {
    try {
      print('Waiting for user to return to MedCon app...');

      // Wait for a reasonable time for user to send message and return
      await Future.delayed(const Duration(seconds: 10));

      // Additional wait if needed (user can manually continue)
      print(
          'User should have sent message by now. Continuing to next contact...');
    } catch (e) {
      print('Error waiting for user return: $e');
    }
  }
}
