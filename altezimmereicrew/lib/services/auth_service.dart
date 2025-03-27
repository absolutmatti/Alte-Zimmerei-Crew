import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user stream
  Stream<User?> get userStream => _auth.authStateChanges();

  // Get user model stream
  Stream<UserModel?> getUserModelStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? UserModel.fromFirestore(snapshot) : null);
  }

  // Register with email and password
  Future<UserModel> registerWithEmailAndPassword(
      String email, String password, String name, String? phoneNumber) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user == null) {
        throw Exception('Failed to create user');
      }

      // Create user document in Firestore
      UserModel userModel = UserModel(
        id: user.uid,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        role: AppConstants.roleEmployee, // Default role is employee
        notificationPreferences: [
          AppConstants.newsChannel,
          AppConstants.generalChannel,
          AppConstants.shiftsChannel,
          AppConstants.meetingsChannel,
          AppConstants.eventsChannel,
        ],
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toMap());

      return userModel;
    } catch (e) {
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user == null) {
        throw Exception('Failed to sign in');
      }

      // Update last login
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Get user data
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile(
      String userId, String name, String? phoneNumber, String? profileImageUrl) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
        'name': name,
        'phoneNumber': phoneNumber,
        'profileImageUrl': profileImageUrl,
      });

      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences(
      String userId, List<String> preferences) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
        'notificationPreferences': preferences,
      });
    } catch (e) {
      throw Exception('Failed to update notification preferences: ${e.toString()}');
    }
  }

  // Check if user is owner
  Future<bool> isUserOwner(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        return false;
      }
      
      UserModel user = UserModel.fromFirestore(userDoc);
      return user.role == AppConstants.roleOwner;
    } catch (e) {
      return false;
    }
  }

  // Set user as owner (admin function)
  Future<void> setUserAsOwner(String userId) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
        'role': AppConstants.roleOwner,
      });
    } catch (e) {
      throw Exception('Failed to set user as owner: ${e.toString()}');
    }
  }

  // Remove user (admin function)
  Future<void> removeUser(String userId) async {
    try {
      // Delete user document
      await _firestore.collection(AppConstants.usersCollection).doc(userId).delete();
      
      // Note: This doesn't delete the Auth user. In a production app,
      // you would use Firebase Admin SDK or Cloud Functions to delete the Auth user as well.
    } catch (e) {
      throw Exception('Failed to remove user: ${e.toString()}');
    }
  }

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .orderBy('name')
          .get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: ${e.toString()}');
    }
  }
}

