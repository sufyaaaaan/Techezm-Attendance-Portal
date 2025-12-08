import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:techezm_attendance_portal/services/auth_service.dart';
import 'package:techezm_attendance_portal/services/firestore_service.dart';
import 'package:techezm_attendance_portal/models/user_model.dart';

/// Core services
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

/// Firebase auth state stream
final firebaseAuthUserProvider =
StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

/// Loads employee/admin profile AFTER Firebase user is ready
final currentUserModelProvider = StreamProvider<UserModel?>((ref) async* {
  await for (final authUser in FirebaseAuth.instance.authStateChanges()) {
    print("AUTH USER: ${authUser?.uid}");

    if (authUser == null) {
      print("AUTH USER NULL");
      yield null;
      continue;
    }

    final fs = FirebaseFirestore.instance;

    // EMPLOYEE
    final emp = await fs.collection('employees').doc(authUser.uid).get();
    print("EMP DOC EXISTS? ${emp.exists}");
    if (emp.exists) {
      print("LOADED EMPLOYEE");
      yield UserModel.fromMap(emp.id, emp.data()!);
      continue;
    }

    // ADMIN (admins collection)
    final adm = await fs.collection('admins').doc(authUser.uid).get();
    print("ADM DOC EXISTS? ${adm.exists}");
    if (adm.exists) {
      print("LOADED ADMIN FROM /admins");
      yield UserModel.fromMap(adm.id, adm.data()!);
      continue;
    }

    // ADMIN (users collection)
    final usr = await fs.collection('users').doc(authUser.uid).get();
    print("USR DOC EXISTS? ${usr.exists}");
    if (usr.exists) {
      print("LOADED ADMIN FROM /users");
      yield UserModel.fromMap(usr.id, usr.data()!);
      continue;
    }

    print("NO MATCHING FIRESTORE DOCUMENT");
    yield null;
  }
});


