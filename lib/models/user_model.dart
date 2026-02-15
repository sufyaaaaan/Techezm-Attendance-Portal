/// Represents a user in the system (admin or employee).
///
/// The [UserModel] class encapsulates both administrator and employee
/// properties. Admins are authenticated with their email while employees
/// authenticate with a synthetic email generated from their username. The
/// [role] field indicates the user type and is used by security rules.
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String role; // 'admin' or 'employee'
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'createdAt': createdAt,
    };
  }
}