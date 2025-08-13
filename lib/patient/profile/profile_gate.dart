import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_creation.dart';
import 'profile_display.dart';
import 'package:medcon30/providers/patient_provider.dart';

class ProfileGateScreen extends ConsumerStatefulWidget {
  const ProfileGateScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileGateScreen> createState() => _ProfileGateScreenState();
}

class _ProfileGateScreenState extends ConsumerState<ProfileGateScreen> {
  bool _isLoading = true;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _hasProfile = false;
      });
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    bool hasProfile = false;
    if (doc.exists && data != null) {
      // Check for required fields
      final address = data['address'] ?? '';
      final dob = data['dateOfBirth'] ?? '';
      final gender = data['gender'] ?? '';
      if (address.toString().trim().isNotEmpty &&
          dob.toString().trim().isNotEmpty &&
          gender.toString().trim().isNotEmpty) {
        hasProfile = true;
      }
    }
    setState(() {
      _isLoading = false;
      _hasProfile = hasProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasProfile) {
      return const ProfileDisplayScreen();
    } else {
      return const ProfileCreationScreen();
    }
  }
}
