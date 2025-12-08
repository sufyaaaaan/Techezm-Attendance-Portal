import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:techezm_attendance_portal/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> updateProfileName(String newName) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('employees').doc(user.uid).update({
        'name': newName,
      });

      await user.updateDisplayName(newName);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }


  /// Universal sign-in method for BOTH Admin and Employee.
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return credential.user;
  }

  /// Sign out user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Create an employee account
  Future<UserModel> createEmployee({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;
    final now = DateTime.now();

    await _firestore.collection('employees').doc(user.uid).set({
      'name': name,
      'username': username,
      'email': email,
      'role': 'employee',
      'createdAt': now,
    });

    return UserModel(
      id: user.uid,
      name: name,
      username: username,
      email: email,
      role: 'employee',
      createdAt: now,
    );
  }
}
