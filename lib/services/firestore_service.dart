import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create or update user profile
  Future<void> saveUserProfile({
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Add user ID to profile data
      profileData['uid'] = userId;
      profileData['lastUpdated'] = FieldValue.serverTimestamp();

      // Save all profile data to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .set(profileData, SetOptions(merge: true));

      print('Profile data saved successfully');
    } catch (e) {
      print('Error saving profile: $e');
      throw Exception('Failed to save profile: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting profile: $e');
      throw Exception('Failed to get profile: $e');
    }
  }

  // Update specific fields in user profile
  Future<void> updateUserProfile({
    required Map<String, dynamic> updates,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      updates['lastUpdated'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(updates);
      print('Profile updated successfully');
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Add a vaccination reminder
  Future<DocumentReference> addVaccinationReminder(
      Map<String, dynamic> data) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Add user ID and timestamp to the reminder data
      final reminderData = {
        ...data,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': data['status'] ?? 'Pending',
      };

      // Save to Firestore
      final docRef = await _firestore
          .collection('vaccination_reminders')
          .add(reminderData);
      print('Vaccination reminder added successfully with ID: ${docRef.id}');
      return docRef;
    } catch (e) {
      print('Error adding vaccination reminder: $e');
      throw Exception('Failed to add vaccination reminder: $e');
    }
  }

  // Update a vaccination reminder
  Future<void> updateVaccinationReminder(
      String docId, Map<String, dynamic> data) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      print('Debug - Current user ID: $userId');
      print('Debug - Document ID being updated: $docId');

      // Add user ID and timestamp to the update data
      data['userId'] = userId;
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Get the document first to verify ownership
      final doc =
          await _firestore.collection('vaccination_reminders').doc(docId).get();
      if (!doc.exists) {
        throw Exception('Vaccination reminder not found');
      }

      final docData = doc.data();
      print('Debug - Document data: $docData');
      print('Debug - Document userId: ${docData?['userId']}');
      print('Debug - Current userId: $userId');

      // If the document doesn't have a userId, we'll allow the update and set it
      if (docData == null) {
        throw Exception('Invalid document data');
      }

      // Allow update if:
      // 1. The document has no userId (old document)
      // 2. The userId matches the current user
      if (docData['userId'] == null || docData['userId'] == userId) {
        // Update the document
        await _firestore
            .collection('vaccination_reminders')
            .doc(docId)
            .update(data);
        print('Vaccination reminder updated successfully');
      } else {
        throw Exception('You do not have permission to update this reminder');
      }
    } catch (e) {
      print('Error updating vaccination reminder: $e');
      throw Exception('Failed to update vaccination reminder: $e');
    }
  }

  // Delete a vaccination reminder
  Future<void> deleteVaccinationReminder(String docId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Get the document first to verify ownership
      final doc =
          await _firestore.collection('vaccination_reminders').doc(docId).get();
      if (!doc.exists) {
        throw Exception('Vaccination reminder not found');
      }

      final docData = doc.data();
      if (docData == null) {
        throw Exception('Invalid document data');
      }

      print('Debug - Current user ID: $userId');
      print('Debug - Document data: $docData');
      print('Debug - Document userId: ${docData['userId']}');
      print('Debug - Has userId field: ${docData.containsKey('userId')}');

      // Allow deletion if:
      // 1. The document has no userId (old document)
      // 2. The userId matches the current user
      if (!docData.containsKey('userId') || docData['userId'] == userId) {
        await _firestore
            .collection('vaccination_reminders')
            .doc(docId)
            .delete();
        print('Vaccination reminder deleted successfully');
      } else {
        print(
            'Debug - Permission denied. Document userId: ${docData['userId']}, Current userId: $userId');
        throw Exception('You do not have permission to delete this reminder');
      }
    } catch (e) {
      print('Error deleting vaccination reminder: $e');
      throw Exception('Failed to delete vaccination reminder: $e');
    }
  }

  // Update all existing vaccination reminders with user ID
  Future<void> updateExistingVaccinationReminders() async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Get all vaccination reminders
      final querySnapshot =
          await _firestore.collection('vaccination_reminders').get();

      // Update each document that doesn't have a userId
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['userId'] == null) {
          await _firestore
              .collection('vaccination_reminders')
              .doc(doc.id)
              .update({
            'userId': userId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('Updated document ${doc.id} with userId: $userId');
        }
      }
    } catch (e) {
      print('Error updating existing vaccination reminders: $e');
      throw Exception('Failed to update existing vaccination reminders: $e');
    }
  }

  // Save weekly plan to Firestore
  Future<void> saveWeeklyPlan(Map<String, dynamic> planData) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final planDoc = {
        ...planData,
        'userId': userId,
        'savedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore - use user ID as document ID and REPLACE existing plan (not merge)
      // This ensures new plans override old ones
      await _firestore
          .collection('weekly_plans')
          .doc(userId)
          .set(planDoc, SetOptions(merge: false));

      print('Weekly plan saved successfully');
    } catch (e) {
      print('Error saving weekly plan: $e');
      throw Exception('Failed to save weekly plan: $e');
    }
  }

  // Get saved weekly plan from Firestore
  Future<Map<String, dynamic>?> getSavedWeeklyPlan() async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final doc = await _firestore.collection('weekly_plans').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        print('Saved weekly plan retrieved successfully');
        return doc.data();
      } else {
        print('No saved weekly plan found');
        return null;
      }
    } catch (e) {
      print('Error getting saved weekly plan: $e');
      throw Exception('Failed to get saved weekly plan: $e');
    }
  }
}

// Riverpod provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

// Provider for user profile
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return await firestoreService.getUserProfile();
});
