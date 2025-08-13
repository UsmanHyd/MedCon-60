import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// User data model
class UserData {
  final String uid;
  final String email;
  final String name;
  final String role; // 'patient' or 'doctor'
  final String? phoneNumber;
  final String? profileImage;
  final Map<String, dynamic>? additionalData;

  UserData({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.profileImage,
    this.additionalData,
  });

  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'patient',
      phoneNumber: data['phoneNumber'],
      profileImage: data['profileImage'],
      additionalData: data,
    );
  }
}

// Auth state notifier
class AuthNotifier extends StateNotifier<AsyncValue<UserData?>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      state = const AsyncValue.loading();
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final userData = UserData.fromFirestore(doc);
        state = AsyncValue.data(userData);
      } else {
        state = AsyncValue.error('User data not found', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // User data will be loaded automatically via _init()
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signUp(String email, String password, String name, String role) async {
    try {
      state = const AsyncValue.loading();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // User data will be loaded automatically via _init()
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // State will be updated automatically via _init()
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (profileImage != null) updates['profileImage'] = profileImage;

      await _firestore.collection('users').doc(user.uid).update(updates);
      
      // Reload user data
      await _loadUserData(user.uid);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserData?>>(
  (ref) => AuthNotifier(),
);

// Convenience providers
final userProvider = Provider<UserData?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user != null;
});

final userRoleProvider = Provider<String?>((ref) {
  final user = ref.watch(userProvider);
  return user?.role;
});

final isPatientProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'patient';
});

final isDoctorProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'doctor';
});
