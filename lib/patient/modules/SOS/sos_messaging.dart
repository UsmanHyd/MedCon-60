import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:medcon30/theme/theme_provider.dart';

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

  String _emergencyMessage =
      'EMERGENCY! I need help. This is an automated alert sent through the Emergency SOS app.';

  @override
  void initState() {
    super.initState();
    _fetchEmergencyContacts();
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
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Press for Emergency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Activates emergency protocol and alerts your contacts',
                    style: TextStyle(color: subTextColor, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
            // Emergency Message Expansion
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.cyan.withOpacity(isDarkMode ? 0.3 : 0.15),
                  child: Icon(Icons.message,
                      color: isDarkMode ? Colors.white : Colors.cyan),
                ),
                title: Text('Emergency Message',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor)),
                subtitle: Text('Customize your emergency alert message',
                    style: TextStyle(color: subTextColor)),
                children: [
                  Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Message:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: textColor)),
                        const SizedBox(height: 6),
                        Text(_emergencyMessage,
                            style: TextStyle(fontSize: 15, color: textColor)),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03B6E8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final newMsg = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              final controller = TextEditingController(
                                  text: _emergencyMessage);
                              return AlertDialog(
                                backgroundColor: cardColor,
                                title: Text('Edit Emergency Message',
                                    style: TextStyle(color: textColor)),
                                content: TextField(
                                  controller: controller,
                                  maxLines: 4,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    labelText: 'Emergency Message',
                                    labelStyle: TextStyle(color: subTextColor),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFF03B6E8)),
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel',
                                        style: TextStyle(color: textColor)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, controller.text),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF03B6E8)),
                                    child: const Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (newMsg != null && newMsg.trim().isNotEmpty) {
                            setState(() {
                              _emergencyMessage = newMsg.trim();
                            });
                          }
                        },
                        label: const Text('Edit Emergency Message',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white)),
                      ),
                    ),
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
            const SizedBox(height: 18),
            const SizedBox(height: 24),
            // Test SOS Feature Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_outline),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _testSOSFeature(),
                label: const Text(
                  'Test SOS Feature',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
  }) {
    return Container(
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
    );
  }
}
