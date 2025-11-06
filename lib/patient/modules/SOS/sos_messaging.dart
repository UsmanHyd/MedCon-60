import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/services/sos_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medcon30/widgets/sos_countdown_dialog.dart';
import 'dart:io';

class SosMessagingScreen extends StatefulWidget {
  const SosMessagingScreen({Key? key}) : super(key: key);

  @override
  State<SosMessagingScreen> createState() => _SosMessagingScreenState();
}

class _SosMessagingScreenState extends State<SosMessagingScreen> {
  List<Map<String, dynamic>> _emergencyContacts = [];
  bool _loadingContacts = true;
  String? _contactsError;

  // Location sharing switches
  bool _shareLocation = true;
  bool _locationHistory = false;
  bool _continuousUpdates = true;

  // SOS Service
  final SOSService _sosService = SOSService();
  bool _isSendingSOS = false;



  @override
  void initState() {
    super.initState();
    _fetchEmergencyContacts();
    _checkLocationPermission();
  }

  /// Check and request location permission if needed
  Future<void> _checkLocationPermission() async {
    if (!await _sosService.hasLocationPermission()) {
      await _sosService.requestLocationPermission();
    }
  }

  /// Refresh location data
  Future<void> _refreshLocation() async {
    setState(() {
      // This will trigger a rebuild of the FutureBuilder
    });
  }

  Future<void> _fetchEmergencyContacts() async {
    setState(() {
      _loadingContacts = true;
      _contactsError = null;
    });
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
      setState(() {
        _emergencyContacts = contacts;
        _loadingContacts = false;
      });
    } catch (e) {
      print('Error fetching contacts: $e');
      setState(() {
        _contactsError = 'Failed to load contacts';
        _loadingContacts = false;
      });
    }
  }

  Future<void> _addEmergencyContact() async {
    if (_emergencyContacts.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum of 3 emergency contacts allowed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final phoneController = TextEditingController();
        final relationController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Emergency Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationController,
                decoration: const InputDecoration(
                  labelText: 'Relation',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty ||
                    phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name and phone number are required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'relation': relationController.text,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not logged in');

        final newContacts = [..._emergencyContacts, result];
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'emergencyContacts': newContacts});

        setState(() {
          _emergencyContacts = newContacts;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency contact added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error adding contact: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add emergency contact'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEmergencyContact(int index) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final newContacts = List<Map<String, dynamic>>.from(_emergencyContacts);
      newContacts.removeAt(index);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'emergencyContacts': newContacts});

      setState(() {
        _emergencyContacts = newContacts;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency contact removed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting contact: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to remove emergency contact'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show SOS countdown confirmation dialog
  Future<bool?> _showSOSCountdownDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SOSCountdownDialog();
      },
    );
  }

  /// Trigger SOS emergency alert
  Future<void> _triggerSOS() async {
    // Check if user has emergency contacts
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No emergency contacts found. Please add contacts first.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
        final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black;

        return AlertDialog(
          backgroundColor: bgColor,
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                'Confirm SOS Alert',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to send an SOS alert?\n\n'
            'This will:\n'
            '• Send WhatsApp messages to all emergency contacts\n'
            '• Share your current location\n\n'
            '⚠️ Only use in genuine emergencies!',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: textColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'SEND SOS',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Set loading state
    setState(() {
      _isSendingSOS = true;
    });

    try {
      // Check location permission first
      if (!await _sosService.hasLocationPermission()) {
        final granted = await _sosService.requestLocationPermission();
        if (!granted) {
          throw Exception('Location permission is required for SOS alerts');
        }
      }

              // Show progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Provider.of<ThemeProvider>(context, listen: false).isDarkMode 
                  ? const Color(0xFF121212) 
                  : Colors.white,
              title: Row(
                children: [
                  const CircularProgressIndicator(color: Colors.red),
                  const SizedBox(width: 16),
                  Text(
                    'Sending SOS Alerts...',
                    style: TextStyle(
                      color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode 
                          ? Colors.white 
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Sending emergency messages to ${_emergencyContacts.length} contacts...\n\n'
                'Please send each message and return to MedCon to continue.',
                style: TextStyle(
                  color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode 
                      ? Colors.white 
                      : Colors.black,
                ),
              ),
            );
          },
        );

        // Send SOS alerts
        final result = await _sosService.sendSOSAlerts();

        // Close progress dialog
        Navigator.of(context).pop();

      if (result['success']) {
        // Show success dialog
        _showSOSResultDialog(result, true);
      } else {
        // Show error dialog
        _showSOSResultDialog(result, false);
      }
    } catch (e) {
      // Show error dialog
      _showSOSResultDialog({
        'success': false,
        'message': 'Error: $e',
        'contactsReached': 0,
        'totalContacts': 0,
      }, false);
    } finally {
      // Reset loading state
      setState(() {
        _isSendingSOS = false;
      });
    }
  }

  /// Show SOS result dialog
  void _showSOSResultDialog(Map<String, dynamic> result, bool isSuccess) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgColor,
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isSuccess ? 'SOS Sent Successfully' : 'SOS Failed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['message'],
                style: TextStyle(color: textColor),
              ),
              if (isSuccess) ...[
                const SizedBox(height: 16),
                _resultItem(
                    'Total Contacts', '${result['totalContacts']}', textColor),
                _resultItem(
                    'WhatsApp Sent', '${result['whatsappSuccess']}', textColor),
                if (result['errors']?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Some errors occurred:',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...result['errors'].map((error) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          '• $error',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      )),
                ],
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSuccess ? const Color(0xFF0288D1) : Colors.red,
              ),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _resultItem(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textColor)),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Format timestamp for display
  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _testSOSFeature() {
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
        final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black;

        return AlertDialog(
          backgroundColor: bgColor,
          title: Text(
            'Test SOS Feature',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: Text(
            'This is a test of the SOS feature. In a real emergency, this would:\n\n'
            '• Send alerts to your emergency contacts\n'
            '• Share your location\n'
            '• Provide quick access to emergency services\n\n'
            'This test will NOT send any actual alerts.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: textColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _simulateSOSTest();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              child: const Text(
                'Test SOS',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _simulateSOSTest() {
    // Simulate SOS test without sending actual alerts
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'SOS Test Completed Successfully! No actual alerts were sent.',
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    // Show test results dialog
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
        final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black;

        return AlertDialog(
          backgroundColor: bgColor,
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                'Test Results',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOS Feature Test Results:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              _testResultItem(
                  'Emergency Contacts',
                  _emergencyContacts.isNotEmpty
                      ? '✓ Available'
                      : '✗ No contacts'),
              _testResultItem('Location Sharing',
                  _shareLocation ? '✓ Enabled' : '✗ Disabled'),
              _testResultItem('Emergency Message', '✓ Configured'),
              _testResultItem('Quick Services', '✓ Available'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
              ),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _testResultItem(String label, String status) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: textColor),
          ),
          Text(
            status,
            style: TextStyle(
              color: status.contains('✓') ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _debugWhatsApp() async {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgColor,
          title: Text(
            'WhatsApp Debug Info',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: FutureBuilder<Map<String, dynamic>>(
            future: _getWhatsAppDebugInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data ?? {};
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WhatsApp Installation:',
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.bold)),
                  Text('Installed: ${data['installed'] ?? 'Unknown'}',
                      style: TextStyle(color: textColor)),
                  const SizedBox(height: 8),
                  Text('Availability Check:',
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.bold)),
                  Text('Available: ${data['available'] ?? 'Unknown'}',
                      style: TextStyle(color: textColor)),
                  const SizedBox(height: 8),
                  Text('Test Contact:',
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.bold)),
                  Text('Phone: ${data['testPhone'] ?? 'Unknown'}',
                      style: TextStyle(color: textColor)),
                  const SizedBox(height: 8),
                  Text('Debug Info:',
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.bold)),
                  Text('${data['debugInfo'] ?? 'No debug info'}',
                      style: TextStyle(color: textColor, fontSize: 12)),
                ],
              );
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _testWhatsAppLaunch();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Test Launch',
                  style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _testForceWhatsAppLaunch();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Force Launch',
                  style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _testMinimalMessage();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Test Minimal',
                  style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _testPackageLaunch();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Test Package',
                  style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _testForceLaunchDirect();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Test Force Direct',
                  style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _testRegularWhatsAppOnly();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text('Test Regular Only',
                  style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _testBusinessBlocking();
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text('Test Business Block',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getWhatsAppDebugInfo() async {
    try {
      final installed = await _sosService.isWhatsAppInstalled();
      final available = await _sosService.isWhatsAppAvailable();

      // Get a test phone number from contacts if available
      String testPhone = 'No contacts available';
      if (_emergencyContacts.isNotEmpty) {
        testPhone =
            _emergencyContacts.first['phone']?.toString() ?? 'Invalid contact';
      }

      return {
        'installed': installed ? 'Yes' : 'No',
        'available': available ? 'Yes' : 'No',
        'testPhone': testPhone,
        'debugInfo':
            'Platform: ${Platform.operatingSystem}\nVersion: ${Platform.operatingSystemVersion}',
      };
    } catch (e) {
      return {
        'installed': 'Error: $e',
        'available': 'Error: $e',
        'testPhone': 'Error',
        'debugInfo': 'Failed to get debug info: $e',
      };
    }
  }

  Future<void> _testWhatsAppLaunch() async {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts available for testing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final testPhone = _emergencyContacts.first['phone']?.toString() ?? '';
    final testMessage =
        '🧪 TEST MESSAGE - This is a test from MedCon SOS app. Please ignore.';

    try {
      final result = await _sosService.sendWhatsApp(testPhone, testMessage);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp test launched successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp test failed to launch'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WhatsApp test error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testForceWhatsAppLaunch() async {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts available for testing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final testPhone = _emergencyContacts.first['phone']?.toString() ?? '';
    final testMessage =
        '🧪 FORCE TEST MESSAGE - This is a force test from MedCon SOS app. Please ignore.';

    try {
      final result =
          await _sosService.forceLaunchWhatsApp(testPhone, testMessage);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp force launch successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp force launch failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WhatsApp force launch error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testMinimalMessage() async {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts available for testing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final testPhone = _emergencyContacts.first['phone']?.toString() ?? '';

    try {
      final minimalMessage = await _sosService.createMinimalSOSMessage();
      final result = await _sosService.sendWhatsApp(testPhone, minimalMessage);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Minimal message test successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Minimal message test failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimal message test error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testPackageLaunch() async {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts available for testing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final testPhone = _emergencyContacts.first['phone']?.toString() ?? '';

    try {
      final minimalMessage = await _sosService.createMinimalSOSMessage();
      final result =
          await _sosService.launchWhatsAppByPackage(testPhone, minimalMessage);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Package launch test successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Package launch test failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Package launch test error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testForceLaunchDirect() async {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts available for testing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final testPhone = _emergencyContacts.first['phone']?.toString() ?? '';

    try {
      final minimalMessage = await _sosService.createMinimalSOSMessage();
      final result =
          await _sosService.forceLaunchWhatsApp(testPhone, minimalMessage);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Force launch test successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Force launch test failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Force launch test error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testRegularWhatsAppOnly() async {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts available for testing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final testPhone = _emergencyContacts.first['phone']?.toString() ?? '';

    try {
      final minimalMessage = await _sosService.createMinimalSOSMessage();
      final result =
          await _sosService.forceRegularWhatsAppOnly(testPhone, minimalMessage);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Regular WhatsApp only test successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Regular WhatsApp only test failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Regular WhatsApp only test error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testBusinessBlocking() async {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts available for testing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final testPhone = _emergencyContacts.first['phone']?.toString() ?? '';

    try {
      final minimalMessage = await _sosService.createMinimalSOSMessage();
      final result = await _sosService.blockBusinessForceRegular(
          testPhone, minimalMessage);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business blocking test successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business blocking test failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Business blocking test error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Call emergency service number
  Future<void> _callEmergencyService(String number) async {
    try {
      final uri = Uri.parse('tel:$number');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open dialer for $number'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calling $number: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F8FF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    final borderColor = isDarkMode ? const Color(0xFF2C2C2C) : Colors.black12;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDarkMode ? Colors.white : const Color(0xFF0288D1)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Emergency SOS Help',
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF0288D1),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline,
                color: isDarkMode ? Colors.white : const Color(0xFF0288D1)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // SOS Button
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isSendingSOS ? null : _triggerSOS,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _isSendingSOS
                            ? Colors.grey
                            : const Color(0xFFE53935),
                        shape: BoxShape.circle,
                        boxShadow: _isSendingSOS
                            ? []
                            : [
                                BoxShadow(
                                  color:
                                      const Color(0xFFE53935).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                      ),
                      child: Center(
                        child: _isSendingSOS
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              )
                            : const Text(
                                'SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSendingSOS ? 'Sending SOS...' : 'Press for Emergency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isSendingSOS
                        ? 'Alerting your emergency contacts...'
                        : 'Activates emergency protocol and alerts your contacts',
                    style: TextStyle(color: subTextColor, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Quick Services
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Services',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Quick Services Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _quickServiceCard(
                  icon: Icons.medical_services,
                  color: Colors.red,
                  label: 'Ambulance',
                  number: '115',
                  isDarkMode: isDarkMode,
                  onTap: () => _callEmergencyService('115'),
                ),
                _quickServiceCard(
                  icon: Icons.emergency_outlined,
                  color: Colors.orange,
                  label: 'Rescue',
                  number: '1122',
                  isDarkMode: isDarkMode,
                  onTap: () => _callEmergencyService('1122'),
                ),
                _quickServiceCard(
                  icon: Icons.fire_truck,
                  color: Colors.deepOrange,
                  label: 'Fire',
                  number: '16',
                  isDarkMode: isDarkMode,
                  onTap: () => _callEmergencyService('16'),
                ),
                _quickServiceCard(
                  icon: Icons.local_police,
                  color: Colors.blue,
                  label: 'Police',
                  number: '15',
                  isDarkMode: isDarkMode,
                  onTap: () => _callEmergencyService('15'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Emergency Features
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Emergency Features',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // How SOS Works Expansion
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.blue.withOpacity(isDarkMode ? 0.3 : 0.15),
                  child: Icon(Icons.info,
                      color: isDarkMode ? Colors.white : Colors.blue),
                ),
                title: Text('How SOS Works',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor)),
                subtitle: Text('Learn about the emergency response system',
                    style: TextStyle(color: subTextColor)),
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.blue.withOpacity(isDarkMode ? 0.3 : 0.1),
                      child: Text('1',
                          style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.blue,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text('Press the SOS Button',
                        style: TextStyle(color: textColor)),
                    subtitle: Text(
                        'In an emergency, press and hold the red SOS button for 3 seconds',
                        style: TextStyle(color: subTextColor)),
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.blue.withOpacity(isDarkMode ? 0.3 : 0.1),
                      child: Text('2',
                          style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.blue,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text('Confirmation',
                        style: TextStyle(color: textColor)),
                    subtitle: Text(
                        'Confirm the emergency alert or cancel if pressed by mistake',
                        style: TextStyle(color: subTextColor)),
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.blue.withOpacity(isDarkMode ? 0.3 : 0.1),
                      child: Text('3',
                          style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.blue,
                              fontWeight: FontWeight.bold)),
                    ),
                    title:
                        Text('Alert Sent', style: TextStyle(color: textColor)),
                    subtitle: Text(
                        'Your emergency contacts will receive your location and alert message',
                        style: TextStyle(color: subTextColor)),
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.blue.withOpacity(isDarkMode ? 0.3 : 0.1),
                      child: Text('4',
                          style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.blue,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text('Emergency Services',
                        style: TextStyle(color: textColor)),
                    subtitle: Text(
                        'Option to directly call emergency services will appear',
                        style: TextStyle(color: subTextColor)),
                  ),
                ],
              ),
            ),
            // Emergency Contacts Expansion
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.green.withOpacity(isDarkMode ? 0.3 : 0.15),
                  child: Icon(Icons.contacts,
                      color: isDarkMode ? Colors.white : Colors.green),
                ),
                title: Text('Emergency Contacts',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor)),
                subtitle: Text('Manage your emergency contact list',
                    style: TextStyle(color: subTextColor)),
                children: [
                  if (_loadingContacts)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_contactsError != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_contactsError!,
                          style: const TextStyle(color: Colors.red)),
                    )
                  else if (_emergencyContacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'No emergency contacts found.',
                            style: TextStyle(fontSize: 16, color: textColor),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0288D1),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _addEmergencyContact,
                            label: const Text('Add Emergency Contact',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    for (final contact in _emergencyContacts)
                      Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        color: cardColor,
                        child: ListTile(
                          title: Text(contact['name'] ?? '-',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((contact['relation'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Text(contact['relation'] ?? '',
                                    style: TextStyle(
                                        fontSize: 13, color: subTextColor)),
                              if ((contact['phone'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Text(contact['phone'] ?? '',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: isDarkMode
                                            ? Colors.blue[300]
                                            : Colors.blue)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteEmergencyContact(
                                _emergencyContacts.indexOf(contact)),
                          ),
                        ),
                      ),
                    if (_emergencyContacts.length < 3)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0288D1),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _addEmergencyContact,
                            label: const Text('Add Emergency Contact',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            // Quick Services Expansion
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.orange.withOpacity(isDarkMode ? 0.3 : 0.15),
                  child: Icon(Icons.phone_in_talk,
                      color: isDarkMode ? Colors.white : Colors.orange),
                ),
                title: Text('Quick Services',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor)),
                subtitle: Text('Direct access to emergency numbers',
                    style: TextStyle(color: subTextColor)),
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _quickServiceCard(
                                icon: Icons.call,
                                color: Colors.red,
                                label: 'Emergency',
                                number: '911',
                                isDarkMode: isDarkMode,
                                onTap: () => _callEmergencyService('911'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _quickServiceCard(
                                icon: Icons.local_police,
                                color: Colors.blue,
                                label: 'Police',
                                number: '999',
                                isDarkMode: isDarkMode,
                                onTap: () => _callEmergencyService('999'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _quickServiceCard(
                                icon: Icons.local_hospital,
                                color: Colors.green,
                                label: 'Ambulance',
                                number: '998',
                                isDarkMode: isDarkMode,
                                onTap: () => _callEmergencyService('998'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _quickServiceCard(
                                icon: Icons.local_fire_department,
                                color: Colors.orange,
                                label: 'Fire Dept',
                                number: '997',
                                isDarkMode: isDarkMode,
                                onTap: () => _callEmergencyService('997'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Current Location Expansion
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.blue.withOpacity(isDarkMode ? 0.3 : 0.15),
                  child: Icon(Icons.my_location,
                      color: isDarkMode ? Colors.white : Colors.blue),
                ),
                title: Text('Current Location',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor)),
                subtitle: Text('View your current GPS coordinates',
                    style: TextStyle(color: subTextColor)),
                trailing: IconButton(
                  icon: Icon(Icons.refresh,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF0288D1)),
                  onPressed: _refreshLocation,
                ),
                children: [
                  FutureBuilder<Position?>(
                    future: _sosService.getCurrentLocation(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final position = snapshot.data;
                      if (position == null) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(Icons.location_off,
                                  color: Colors.red, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                'Location unavailable',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Check location permissions and GPS settings',
                                style: TextStyle(
                                    color: subTextColor, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      final mapsUrl =
                          "https://maps.google.com/?q=${position.latitude},${position.longitude}";

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Latitude:',
                                    style: TextStyle(color: textColor)),
                                Text(
                                  '${position.latitude.toStringAsFixed(6)}°',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Longitude:',
                                    style: TextStyle(color: textColor)),
                                Text(
                                  '${position.longitude.toStringAsFixed(6)}°',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Accuracy:',
                                    style: TextStyle(color: textColor)),
                                Text(
                                  '±${position.accuracy.toStringAsFixed(1)}m',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon:
                                    const Icon(Icons.map, color: Colors.white),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0288D1),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () async {
                                  final uri = Uri.parse(mapsUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
                                label: const Text(
                                  'Open in Google Maps',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Location Settings Expansion
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.purple.withOpacity(isDarkMode ? 0.3 : 0.15),
                  child: Icon(Icons.location_on,
                      color: isDarkMode ? Colors.white : Colors.purple),
                ),
                title: Text('Location Settings',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor)),
                subtitle: Text('Configure location sharing preferences',
                    style: TextStyle(color: subTextColor)),
                children: [
                  FutureBuilder<bool>(
                    future: _sosService.hasLocationPermission(),
                    builder: (context, snapshot) {
                      final hasPermission = snapshot.data ?? false;
                      return ListTile(
                        leading: Icon(
                          hasPermission
                              ? Icons.location_on
                              : Icons.location_off,
                          color: hasPermission ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          'Location Permission',
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Text(
                          hasPermission
                              ? 'Location access granted ✓'
                              : 'Location access required for SOS alerts',
                          style: TextStyle(
                            color: hasPermission ? Colors.green : Colors.red,
                          ),
                        ),
                        trailing: hasPermission
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : ElevatedButton(
                                onPressed: () async {
                                  final granted = await _sosService
                                      .requestLocationPermission();
                                  if (granted && mounted) {
                                    setState(() {}); // Refresh UI
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                                child: const Text(
                                  'Grant',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                      );
                    },
                  ),
                  // WhatsApp Availability Check
                  FutureBuilder<bool>(
                    future: _sosService.isWhatsAppAvailable(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(
                          leading: CircularProgressIndicator(),
                          title: Text('Checking WhatsApp availability...'),
                        );
                      }

                      final whatsappAvailable = snapshot.data ?? false;

                      return ListTile(
                        leading: Icon(
                          whatsappAvailable
                              ? Icons.chat
                              : Icons.chat_bubble_outline,
                          color: whatsappAvailable ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          'WhatsApp',
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Text(
                          whatsappAvailable
                              ? 'WhatsApp available ✓'
                              : 'WhatsApp not installed',
                          style: TextStyle(
                            color:
                                whatsappAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                        trailing: whatsappAvailable
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.cancel, color: Colors.red),
                      );
                    },
                  ),
                  SwitchListTile(
                    title: Text('Share Location During Emergency',
                        style: TextStyle(color: textColor)),
                    subtitle: Text(
                        'Send your precise location to emergency contacts',
                        style: TextStyle(color: subTextColor)),
                    value: _shareLocation,
                    activeColor: const Color(0xFF0288D1),
                    onChanged: (val) {
                      setState(() {
                        _shareLocation = val;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text('Location History',
                        style: TextStyle(color: textColor)),
                    subtitle: Text(
                        'Share recent location history (last 30 minutes)',
                        style: TextStyle(color: subTextColor)),
                    value: _locationHistory,
                    activeColor: const Color(0xFF0288D1),
                    onChanged: (val) {
                      setState(() {
                        _locationHistory = val;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text('Continuous Updates',
                        style: TextStyle(color: textColor)),
                    subtitle: Text('Send location updates every 2 minutes',
                        style: TextStyle(color: subTextColor)),
                    value: _continuousUpdates,
                    activeColor: const Color(0xFF0288D1),
                    onChanged: (val) {
                      setState(() {
                        _continuousUpdates = val;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            // Safety Tips
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Safety Tips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _tipCard(
              icon: Icons.info_outline,
              iconColor: Colors.blue,
              title: 'When to Use SOS',
              description:
                  'Only use the SOS feature in genuine emergencies when you need immediate assistance',
              isDarkMode: isDarkMode,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            _tipCard(
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
              title: 'Stay Calm',
              description:
                  'Try to remain calm and provide clear information about your situation when possible',
              isDarkMode: isDarkMode,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            _tipCard(
              icon: Icons.cancel,
              iconColor: Colors.red,
              title: 'Avoid False Alarms',
              description:
                  'False alarms can divert resources from real emergencies and cause unnecessary concern',
              isDarkMode: isDarkMode,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

          ],
        ),
      ),
    );
  }

  Widget _tipCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDarkMode,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 32),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        subtitle: Text(description, style: TextStyle(color: subTextColor)),
      ),
    );
  }

  Widget _quickServiceCard({
    required IconData icon,
    required Color color,
    required String label,
    required String number,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.black12,
              width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(isDarkMode ? 0.1 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(isDarkMode ? 0.3 : 0.13),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDarkMode ? Colors.white : Colors.black),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(number,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 16),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
