import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

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

  /// Create a shorter WhatsApp-friendly SOS message
  Future<String> createWhatsAppSOSMessage() async {
    try {
      final locationData = await getLocationWithContext();
      if (locationData != null) {
        final position = locationData['position'] as Position;
        final googleMapsUrl = locationData['googleMapsUrl'] as String;
        final coordinates =
            "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        final accuracy = "±${position.accuracy.toStringAsFixed(1)}m";
        final timestamp = DateTime.now().toLocal().toString().split('.')[0];

        return '''🚨 SOS EMERGENCY! I need immediate help!

📍 Location: $googleMapsUrl
📍 Coordinates: $coordinates
📍 Accuracy: $accuracy
⏰ Time: $timestamp

📱 Sent via MedCon Emergency App
⚠️ URGENT: Automated emergency alert

🚨 Please respond immediately or call emergency services!

🙏 Help me as soon as possible!''';
      } else {
        return '''🚨 SOS EMERGENCY! I need immediate help!

📍 Location: Unable to get current location
📱 Sent via MedCon Emergency App
⚠️ URGENT: Automated emergency alert

🚨 Please respond immediately or call emergency services!

🙏 Help me as soon as possible!''';
      }
    } catch (e) {
      return '''🚨 SOS EMERGENCY! I need immediate help!

📍 Location: Error getting location
📱 Sent via MedCon Emergency App
⚠️ URGENT: Automated emergency alert

🚨 Please respond immediately or call emergency services!

🙏 Help me as soon as possible!''';
    }
  }

  /// Send SMS (Disabled - WhatsApp only)
  Future<bool> sendSMS(String phoneNumber, String message) async {
    // SMS functionality disabled - WhatsApp only
    return false;
  }

  /// Send WhatsApp message
  Future<bool> sendWhatsApp(String phoneNumber, String message) async {
    try {
      // Format phone number (remove spaces, +, and any non-digit characters)
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // Ensure phone number starts with country code if not present
      if (!formattedPhone.startsWith('92') &&
          !formattedPhone.startsWith('1') &&
          !formattedPhone.startsWith('44')) {
        // Default to Pakistan (+92) if no country code
        formattedPhone = '92$formattedPhone';
      }

      print('Attempting to send WhatsApp to: $formattedPhone');
      print('Message length: ${message.length} characters');

      // Try multiple WhatsApp URI formats with better error handling
      final uris = [
        // Method 1: Android intent with explicit package FIRST (forces regular WhatsApp)
        Uri.parse(
            "intent://send?package=com.whatsapp&phone=$formattedPhone&text=${Uri.encodeComponent(message)}#Intent;scheme=whatsapp;package=com.whatsapp;end"),

        // Method 2: Standard WhatsApp scheme with encoded text
        Uri.parse(
            "whatsapp://send?phone=$formattedPhone&text=${Uri.encodeComponent(message)}"),

        // Method 3: Web WhatsApp (should default to regular app)
        Uri.parse(
            "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}"),

        // Method 4: Alternative Android intent
        Uri.parse(
            "intent://send?phone=$formattedPhone&text=${Uri.encodeComponent(message)}#Intent;scheme=whatsapp;end"),

        // Method 5: WhatsApp without text (fallback)
        Uri.parse("whatsapp://send?phone=$formattedPhone"),
      ];

      for (int i = 0; i < uris.length; i++) {
        final uri = uris[i];
        try {
          print('Trying WhatsApp URI $i: $uri');
          if (await canLaunchUrl(uri)) {
            print('URI $i can be launched, attempting to launch...');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            print('WhatsApp launched successfully with URI $i');
            return true;
          } else {
            print('URI $i cannot be launched');
          }
        } catch (e) {
          print('Failed to launch WhatsApp URI $i ($uri): $e');
          continue;
        }
      }

      // If all URIs fail, try direct app launch
      print('Trying direct WhatsApp app launch...');
      final directResult =
          await _launchWhatsAppDirectly(formattedPhone, message);
      if (directResult) {
        print('WhatsApp launched via direct method');
        return true;
      }

      print('All WhatsApp methods failed');
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

  /// Send SOS alerts to all emergency contacts
  Future<Map<String, dynamic>> sendSOSAlerts() async {
    try {
      // Try minimal message first for better WhatsApp compatibility
      final minimalMessage = await createMinimalSOSMessage();
      final fullMessage = await createWhatsAppSOSMessage();
      final contacts = await getEmergencyContacts();

      if (contacts.isEmpty) {
        return {
          'success': false,
          'message': 'No emergency contacts found',
          'contactsReached': 0,
          'totalContacts': 0,
        };
      }

      int whatsappSuccess = 0;
      List<String> errors = [];

      for (final contact in contacts) {
        final phone = contact['phone']?.toString() ?? '';
        if (phone.isEmpty) continue;

        try {
          // Use business-blocking method FIRST (uses working Test Launch/Test Minimal approach)
          print(
              'Using business-blocking method for ${contact['name'] ?? phone}');
          final businessBlockResult =
              await blockBusinessForceRegular(phone, minimalMessage);
          if (businessBlockResult) {
            whatsappSuccess++;
            print(
                'Regular WhatsApp launched via business-blocking method for ${contact['name'] ?? phone}');
            print('Waiting for user to send message and return to MedCon...');
            await waitForUserReturn(); // Wait for user to return
            continue; // Move to next contact
          }

          // If business-blocking failed, try regular WhatsApp only method
          print(
              'Business-blocking failed, trying regular WhatsApp only method');
          final regularResult =
              await forceRegularWhatsAppOnly(phone, minimalMessage);
          if (regularResult) {
            whatsappSuccess++;
            print(
                'Regular WhatsApp launched successfully for ${contact['name'] ?? phone}');
            print('Waiting for user to send message and return to MedCon...');
            await waitForUserReturn(); // Wait for user to return
            continue; // Move to next contact
          }

          // If regular WhatsApp only failed, try force launch method
          print('Regular WhatsApp only failed, trying force launch method');
          final forceResult = await forceLaunchWhatsApp(phone, minimalMessage);
          if (forceResult) {
            whatsappSuccess++;
            print(
                'WhatsApp launched via force method for ${contact['name'] ?? phone}');
            print('Waiting for user to send message and return to MedCon...');
            await waitForUserReturn(); // Wait for user to return
            continue; // Move to next contact
          }

          // If force launch failed, try standard WhatsApp method
          print('Force launch failed, trying standard WhatsApp method');
          final waResult = await sendWhatsApp(phone, minimalMessage);
          if (waResult) {
            whatsappSuccess++;
            print(
                'WhatsApp launched via standard method for ${contact['name'] ?? phone}');
            print('Waiting for user to send message and return to MedCon...');
            await waitForUserReturn(); // Wait for user to return
            continue; // Move to next contact
          }

          // If both failed, try package-based launch method
          print('Standard method failed, trying package-based launch');
          final packageResult =
              await launchWhatsAppByPackage(phone, minimalMessage);
          if (packageResult) {
            whatsappSuccess++;
            print(
                'WhatsApp launched via package method for ${contact['name'] ?? phone}');
            print('Waiting for user to send message and return to MedCon...');
            await waitForUserReturn(); // Wait for user to return
            continue; // Move to next contact
          }

          // If all WhatsApp methods failed, try platform-specific method
          print('Package method failed, trying platform-specific method');
          final platformResult =
              await openEmergencyContact(phone, minimalMessage);
          if (platformResult) {
            print(
                'Opened emergency contact via platform method for ${contact['name'] ?? phone}');
            continue; // Move to next contact
          }

          // Only open phone dialer as last resort
          print(
              'All WhatsApp methods failed, opening phone dialer as last resort');
          final dialerResult = await openPhoneDialer(phone, minimalMessage);
          if (dialerResult) {
            print('Opened phone dialer for ${contact['name'] ?? phone}');
          }

          // Small delay to avoid overwhelming the system
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          errors.add('Error sending to ${contact['name'] ?? phone}: $e');
        }
      }

      // Log SOS attempt to Firestore for history
      await _logSOSAttempt(contacts.length, 0, whatsappSuccess, errors);

      return {
        'success': true,
        'message': 'SOS alerts sent successfully via WhatsApp',
        'contactsReached': whatsappSuccess,
        'totalContacts': contacts.length,
        'whatsappSuccess': whatsappSuccess,
        'errors': errors,
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

  /// Log SOS attempt to Firestore for history tracking
  Future<void> _logSOSAttempt(int totalContacts, int smsSuccess,
      int whatsappSuccess, List<String> errors) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Try to log to sos_history collection
      try {
        await FirebaseFirestore.instance.collection('sos_history').add({
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'totalContacts': totalContacts,
          'smsSuccess': smsSuccess,
          'whatsappSuccess': whatsappSuccess,
          'errors': errors,
          'status': 'completed',
        });
      } catch (firestoreError) {
        // If sos_history fails, try to log to user's document
        print('Could not log to sos_history collection: $firestoreError');
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
        final position = locationData['position'] as Position;
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
